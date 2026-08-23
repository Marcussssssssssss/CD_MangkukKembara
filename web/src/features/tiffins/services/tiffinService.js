import { supabase, queryRows, insertRows, updateRows } from '../../../services/supabase/api';
import { uploadHeritageVideo } from '../../../services/cloudinary/upload';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Attach the public artist profile to each artwork without querying the
 * RLS-protected profiles table directly. The existing `profiles` property is
 * preserved so TiffinCard, TiffinDetails and TiffinForm keep the same shape.
 */
async function enrichArtworksWithPublicProfiles(artworks) {
  const profileIds = [...new Set(
    artworks.map(artwork => artwork.profile_id).filter(Boolean)
  )];

  if (profileIds.length === 0) return artworks;

  const publicProfiles = await queryRows(
    'public_profiles',
    'profile_id, display_name, avatar_url',
    q => q.in('profile_id', profileIds)
  );

  const publicProfilesById = new Map(
    publicProfiles.map(profile => [profile.profile_id, profile])
  );

  return artworks.map(artwork => ({
    ...artwork,
    profiles: publicProfilesById.get(artwork.profile_id) || null,
  }));
}

function relationRow(relation) {
  if (Array.isArray(relation)) return relation[0] || null;
  return relation || null;
}

function relationRows(relation) {
  if (Array.isArray(relation)) return relation;
  return relation ? [relation] : [];
}

async function assertArtworkAvailable(artworkId, currentTiffinId = null) {
  const assignments = await queryRows(
    'heritage_tiffins',
    'heritage_tiffin_id',
    query => {
      const artworkQuery = query.eq('artwork_id', artworkId);
      return currentTiffinId
        ? artworkQuery.neq('heritage_tiffin_id', currentTiffinId)
        : artworkQuery;
    }
  );

  if (assignments.length > 0) {
    throw new Error('This Artwork is already assigned to another Heritage Tiffin.');
  }
}

async function assertTiffinRelationships(formData, currentTiffinId = null) {
  if (!formData.artwork_id) throw new Error('Select a published winning Artwork.');

  const artworks = await queryRows(
    'artworks',
    `
      artwork_id,
      status,
      artwork_campaign_winners!inner(
        artwork_campaigns!artwork_campaign_winners_artwork_campaign_id_fkey(state_id)
      )
    `,
    query => query.eq('artwork_id', formData.artwork_id).eq('status', 'published')
  );
  const artwork = artworks[0];
  const campaignStateId = relationRow(
    relationRow(artwork?.artwork_campaign_winners)?.artwork_campaigns
  )?.state_id;

  if (!artwork || !campaignStateId) {
    throw new Error('The selected Artwork is not a published campaign winner.');
  }
  if (formData.state_id !== campaignStateId) {
    throw new Error('The Tiffin state must match the selected Artwork campaign.');
  }

  const foods = await queryRows(
    'heritage_foods',
    'heritage_food_id, state_id, is_active',
    query => query
      .eq('heritage_food_id', formData.heritage_food_id)
      .eq('is_active', true)
  );
  if (!foods[0] || foods[0].state_id !== campaignStateId) {
    throw new Error('Select an active Heritage Food from the Artwork campaign state.');
  }

  await assertArtworkAvailable(formData.artwork_id, currentTiffinId);
}

// ---------------------------------------------------------------------------
// Service Exports
// ---------------------------------------------------------------------------

/**
 * Fetch all active/inactive tiffins with their nested relations.
 */
export async function fetchTiffins() {
  const data = await queryRows(
    'heritage_tiffins',
    '*, heritage_stories(*), heritage_media(*), tiffin_qr_codes(tiffin_qr_code_id, code_value, is_active)',
    q => q.order('created_at', { ascending: false })
  );

  return data.map(tiffin => ({
    ...tiffin,
    heritage_stories: [...(tiffin.heritage_stories || [])]
      .sort((a, b) => a.sort_order - b.sort_order),
    heritage_media: [...(tiffin.heritage_media || [])]
      .filter(media => media.media_type === 'video')
      .sort((a, b) => a.sort_order - b.sort_order),
  }));
}

/**
 * Fetch all reference data needed for the Tiffin Forms.
 */
export async function fetchReferenceData() {
  const [states, foods, artworkRows] = await Promise.all([
    queryRows('states', '*', q => q.eq('is_active', true).order('state_name')),
    queryRows('heritage_foods', '*', q => q.eq('is_active', true).order('food_name')),
    queryRows(
      'artworks',
      `
        *,
        artwork_submissions!fk_artwork_source_submission(
          artwork_submission_id,
          design_description,
          cultural_inspiration,
          layer_1_meaning,
          layer_2_meaning,
          layer_3_meaning
        ),
        artwork_campaign_winners!inner(
          artwork_campaign_winner_id,
          artwork_campaigns!artwork_campaign_winners_artwork_campaign_id_fkey(state_id)
        ),
        heritage_tiffins(heritage_tiffin_id)
      `,
      q => q.eq('status', 'published').order('title')
    )
  ]);

  const normalizedArtworks = artworkRows.map(artwork => ({
    ...artwork,
    source_submission: relationRow(artwork.artwork_submissions),
    campaign_state_id: relationRow(
      relationRow(artwork.artwork_campaign_winners)?.artwork_campaigns
    )?.state_id || null,
    assigned_tiffin_id: relationRows(artwork.heritage_tiffins)[0]?.heritage_tiffin_id || null,
  }));
  const artworks = await enrichArtworksWithPublicProfiles(normalizedArtworks);

  return { states, foods, artworks };
}

/**
 * Create a new Tiffin with optional media.
 */
export async function createTiffin(formData, files) {
  await assertTiffinRelationships(formData);

  // 2. Insert Tiffin. Its display image comes from the linked Artwork.
  const tiffinPayload = {
    edition_name: formData.edition_name,
    state_id: formData.state_id,
    heritage_food_id: formData.heritage_food_id,
    artwork_id: formData.artwork_id,
    release_year: formData.release_year,
    status: formData.status,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  };

  let insertedTiffin = null;
  try {
    [insertedTiffin] = await insertRows('heritage_tiffins', [tiffinPayload]);
    const tiffinId = insertedTiffin.heritage_tiffin_id;

    // 3. Insert Story
    const storyPayload = {
      heritage_tiffin_id: tiffinId,
      title: formData.heritage_story.title,
      story_body: formData.heritage_story.story_body,
      is_published: true,
      sort_order: 1
    };

    const [insertedStory] = await insertRows('heritage_stories', [storyPayload]);

    // 4. Upload heritage story video and insert heritage_media record
    let insertedMedia = null;
    if (files?.heritageVideo) {
      const videoResult = await uploadHeritageVideo(files.heritageVideo);
      const mediaPayload = {
        heritage_tiffin_id: tiffinId,
        media_type: 'video',
        title: formData.heritage_story.title || 'Heritage Story Video',
        media_url: videoResult.secure_url,
        thumbnail_url: null,
        caption: null,
        duration_seconds: null,
        sort_order: 1,
        is_published: true,
      };

      const [res] = await insertRows('heritage_media', [mediaPayload]);
      insertedMedia = res;
    }

    return {
      ...insertedTiffin,
      heritage_stories: [insertedStory],
      heritage_media: insertedMedia ? [insertedMedia] : [],
    };
  } catch (error) {
    // This operation spans database rows and an external media service. If a
    // later step fails, remove the newly inserted parent; child rows cascade.
    if (insertedTiffin) {
      const tiffinId = insertedTiffin.heritage_tiffin_id;
      const { error: rollbackError } = await supabase
        .from('heritage_tiffins')
        .delete()
        .eq('heritage_tiffin_id', tiffinId);
      if (rollbackError) {
        throw new Error(
          `${error.message || 'Tiffin creation failed.'} A partial Tiffin (${tiffinId}) may remain and should be reviewed.`,
          { cause: error }
        );
      }
    }
    throw error;
  }
}

/**
 * Update an existing Tiffin with optional media replacement.
 */
export async function updateTiffin(tiffinId, formData, files) {
  await assertTiffinRelationships(formData, tiffinId);

  // Upload first. A Cloudinary failure must not leave partially updated DB rows.
  const uploadedVideo = files?.heritageVideo
    ? await uploadHeritageVideo(files.heritageVideo)
    : null;

  // 1. Update Tiffin. Its display image comes from the linked Artwork.
  const tiffinPayload = {
    edition_name: formData.edition_name,
    state_id: formData.state_id,
    heritage_food_id: formData.heritage_food_id,
    artwork_id: formData.artwork_id,
    release_year: formData.release_year,
    status: formData.status,
    updated_at: new Date().toISOString(),
  };

  const [updatedTiffin] = await updateRows(
    'heritage_tiffins', 
    tiffinPayload, 
    q => q.eq('heritage_tiffin_id', tiffinId)
  );

  // 2. Update Story
  let updatedStory;
  const existingStory = formData.heritage_stories && formData.heritage_stories.length > 0 
    ? formData.heritage_stories[0] 
    : null;

  if (existingStory) {
    const storyPayload = {
      title: formData.heritage_story.title,
      story_body: formData.heritage_story.story_body,
    };
    const [res] = await updateRows(
      'heritage_stories',
      storyPayload,
      q => q.eq('heritage_story_id', existingStory.heritage_story_id)
    );
    updatedStory = res;
  } else {
    const storyPayload = {
      heritage_tiffin_id: tiffinId,
      title: formData.heritage_story.title,
      story_body: formData.heritage_story.story_body,
      is_published: true,
      sort_order: 1
    };
    const [res] = await insertRows('heritage_stories', [storyPayload]);
    updatedStory = res;
  }

  // 3. Replace the single heritage story video if a new file is provided.
  let mediaResult = null;
  if (uploadedVideo) {
    const existingVideo = (formData.heritage_media || [])
      .find(media => media.media_type === 'video');
    const mediaPayload = {
      media_type: 'video',
      title: formData.heritage_story.title || 'Heritage Story Video',
      media_url: uploadedVideo.secure_url,
      thumbnail_url: null,
      caption: null,
      duration_seconds: null,
      sort_order: 1,
      is_published: true,
    };

    if (existingVideo) {
      const [updatedMedia] = await updateRows(
        'heritage_media',
        mediaPayload,
        q => q.eq('heritage_media_id', existingVideo.heritage_media_id)
      );
      mediaResult = updatedMedia;
    } else {
      const [insertedMedia] = await insertRows('heritage_media', [{
        ...mediaPayload,
        heritage_tiffin_id: tiffinId,
      }]);
      mediaResult = insertedMedia;
    }
  }

  return {
    ...updatedTiffin,
    heritage_stories: updatedStory ? [updatedStory] : [],
    heritage_media: mediaResult ? [mediaResult] : (formData.heritage_media || []),
    tiffin_qr_codes: formData.tiffin_qr_codes || [],
  };
}

/**
 * Deactivate a Tiffin (Soft Delete)
 */
export async function deactivateTiffin(tiffinId) {
  const [updatedTiffin] = await updateRows(
    'heritage_tiffins',
    { status: 'inactive', updated_at: new Date().toISOString() },
    q => q.eq('heritage_tiffin_id', tiffinId)
  );
  return updatedTiffin;
}

// ---------------------------------------------------------------------------
// QR Code Generation
// ---------------------------------------------------------------------------

/**
 * Generate and store a QR code record for a Heritage Tiffin.
 *
 * The code_value follows the existing convention: MKK-{tiffinId}-{year}
 * If a QR record already exists for the given tiffin, it is returned
 * instead of creating a duplicate.
 *
 * @param {string} tiffinId
 * @returns {Promise<Object>} The tiffin_qr_codes row.
 */
export async function generateTiffinQrCode(tiffinId) {
  // Check for existing QR to prevent duplicates
  const existing = await queryRows(
    'tiffin_qr_codes',
    '*',
    q => q.eq('heritage_tiffin_id', tiffinId)
  );

  if (existing.length > 0) {
    return existing[0];
  }

  const year = new Date().getFullYear();
  const codeValue = `MKK-${tiffinId}-${year}`;

  const payload = {
    heritage_tiffin_id: tiffinId,
    code_value: codeValue,
    is_active: true,
    generated_at: new Date().toISOString(),
  };

  const [inserted] = await insertRows('tiffin_qr_codes', [payload]);
  return inserted;
}
