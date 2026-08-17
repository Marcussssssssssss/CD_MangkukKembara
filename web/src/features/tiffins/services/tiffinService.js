import { supabase, queryRows, insertRows, updateRows } from '../../../services/supabase/api';
import { uploadTiffinImage, uploadHeritageVideo } from '../../../services/cloudinary/upload';

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

/**
 * Helper to generate the next HT0000 ID format.
 */
async function getNextTiffinId() {
  const { data, error } = await supabase
    .from('heritage_tiffins')
    .select('heritage_tiffin_id')
    .order('heritage_tiffin_id', { ascending: false })
    .limit(1);

  if (error) throw error;

  let nextNum = 1;
  if (data && data.length > 0 && data[0].heritage_tiffin_id) {
    const numPart = data[0].heritage_tiffin_id.replace('HT', '');
    nextNum = parseInt(numPart, 10) + 1;
  }
  
  return `HT${String(nextNum).padStart(4, '0')}`;
}

async function getNextStoryId() {
  const { data, error } = await supabase
    .from('heritage_stories')
    .select('heritage_story_id')
    .order('heritage_story_id', { ascending: false })
    .limit(1);

  if (error) throw error;

  let nextNum = 1;
  if (data && data.length > 0 && data[0].heritage_story_id) {
    const numPart = data[0].heritage_story_id.replace('HS', '');
    nextNum = parseInt(numPart, 10) + 1;
  }
  
  return `HS${String(nextNum).padStart(4, '0')}`;
}

async function getNextMediaId() {
  const { data, error } = await supabase
    .from('heritage_media')
    .select('heritage_media_id')
    .order('heritage_media_id', { ascending: false })
    .limit(1);

  if (error) throw error;

  let nextNum = 1;
  if (data && data.length > 0 && data[0].heritage_media_id) {
    const numPart = data[0].heritage_media_id.replace('HM', '');
    nextNum = parseInt(numPart, 10) + 1;
  }
  
  return `HM${String(nextNum).padStart(4, '0')}`;
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
    '*, heritage_stories(*), heritage_media(*), tiffin_qr_codes(code_value, is_active)',
    q => q.order('created_at', { ascending: false })
  );
  
  return data;
}

/**
 * Fetch all reference data needed for the Tiffin Forms.
 */
export async function fetchReferenceData() {
  const [states, foods, artworkRows] = await Promise.all([
    queryRows('states', '*', q => q.eq('is_active', true).order('state_name')),
    queryRows('heritage_foods', '*', q => q.eq('is_active', true).order('food_name')),
    queryRows('artworks', '*', q => q.neq('status', 'inactive').order('title'))
  ]);

  const artworks = await enrichArtworksWithPublicProfiles(artworkRows);

  return { states, foods, artworks };
}

/**
 * Create a new Tiffin with optional media.
 */
export async function createTiffin(formData, files) {
  // 1. Upload cover image
  let coverImageUrl = null;
  if (files.coverImage) {
    const result = await uploadTiffinImage(files.coverImage);
    coverImageUrl = result.secure_url;
  }

  // 2. Generate IDs
  const tiffinId = await getNextTiffinId();
  const storyId = await getNextStoryId();

  // 3. Insert Tiffin
  const tiffinPayload = {
    heritage_tiffin_id: tiffinId,
    edition_name: formData.edition_name,
    state_id: formData.state_id,
    heritage_food_id: formData.heritage_food_id,
    artwork_id: formData.artwork_id,
    description: formData.description,
    cultural_significance: formData.cultural_significance,
    release_year: formData.release_year,
    status: formData.status,
    cover_image_url: coverImageUrl,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  };

  const [insertedTiffin] = await insertRows('heritage_tiffins', [tiffinPayload]);

  // 4. Insert Story
  const storyPayload = {
    heritage_story_id: storyId,
    heritage_tiffin_id: tiffinId,
    title: formData.heritage_story.title,
    story_body: formData.heritage_story.story_body,
    is_published: true,
    sort_order: 1
  };

  const [insertedStory] = await insertRows('heritage_stories', [storyPayload]);

  // 5. Upload heritage story video and insert heritage_media record
  let insertedMedia = null;
  if (files.heritageVideo) {
    const videoResult = await uploadHeritageVideo(files.heritageVideo);
    const mediaId = await getNextMediaId();

    const mediaPayload = {
      heritage_media_id: mediaId,
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
}

/**
 * Update an existing Tiffin with optional media replacement.
 */
export async function updateTiffin(tiffinId, formData, files) {
  // 1. Upload Media if new file exists
  let coverImageUrl = formData.cover_image_url;
  if (files.coverImage) {
    const result = await uploadTiffinImage(files.coverImage);
    coverImageUrl = result.secure_url;
  }

  // 2. Update Tiffin
  const tiffinPayload = {
    edition_name: formData.edition_name,
    state_id: formData.state_id,
    heritage_food_id: formData.heritage_food_id,
    artwork_id: formData.artwork_id,
    description: formData.description,
    cultural_significance: formData.cultural_significance,
    release_year: formData.release_year,
    status: formData.status,
    cover_image_url: coverImageUrl,
    updated_at: new Date().toISOString(),
  };

  const [updatedTiffin] = await updateRows(
    'heritage_tiffins', 
    tiffinPayload, 
    q => q.eq('heritage_tiffin_id', tiffinId)
  );

  // 3. Update Story
  let updatedStory = null;
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
    const storyId = await getNextStoryId();
    const storyPayload = {
      heritage_story_id: storyId,
      heritage_tiffin_id: tiffinId,
      title: formData.heritage_story.title,
      story_body: formData.heritage_story.story_body,
      is_published: true,
      sort_order: 1
    };
    const [res] = await insertRows('heritage_stories', [storyPayload]);
    updatedStory = res;
  }

  // 4. Upload heritage story video if a new file is provided
  let mediaResult = null;
  if (files.heritageVideo) {
    const videoResult = await uploadHeritageVideo(files.heritageVideo);
    const mediaId = await getNextMediaId();

    const mediaPayload = {
      heritage_media_id: mediaId,
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
    mediaResult = res;
  }

  return {
    ...updatedTiffin,
    heritage_stories: updatedStory ? [updatedStory] : [],
    heritage_media: mediaResult ? [mediaResult] : (formData.heritage_media || []),
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

async function getNextQrCodeId() {
  const { data, error } = await supabase
    .from('tiffin_qr_codes')
    .select('tiffin_qr_code_id')
    .order('tiffin_qr_code_id', { ascending: false })
    .limit(1);

  if (error) throw error;

  let nextNum = 1;
  if (data && data.length > 0 && data[0].tiffin_qr_code_id) {
    const numPart = data[0].tiffin_qr_code_id.replace('TQC', '');
    nextNum = parseInt(numPart, 10) + 1;
  }

  return `TQC${String(nextNum).padStart(4, '0')}`;
}

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

  const qrCodeId = await getNextQrCodeId();
  const year = new Date().getFullYear();
  const codeValue = `MKK-${tiffinId}-${year}`;

  const payload = {
    tiffin_qr_code_id: qrCodeId,
    heritage_tiffin_id: tiffinId,
    code_value: codeValue,
    is_active: true,
    generated_at: new Date().toISOString(),
  };

  const [inserted] = await insertRows('tiffin_qr_codes', [payload]);
  return inserted;
}
