import { supabase, queryRows, insertRows, updateRows, deleteRows } from '../../../services/supabase/api';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

async function getNextId(table, column, prefix) {
  const { data, error } = await supabase
    .from(table)
    .select(column)
    .order(column, { ascending: false })
    .limit(1);

  if (error) throw error;

  let nextNum = 1;
  if (data && data.length > 0 && data[0][column]) {
    const numPart = data[0][column].replace(prefix, '');
    nextNum = parseInt(numPart, 10) + 1;
  }
  
  return `${prefix}${String(nextNum).padStart(4, '0')}`;
}

// ---------------------------------------------------------------------------
// Service Exports
// ---------------------------------------------------------------------------

/**
 * Fetch all campaigns with nested relations (categories).
 */
export async function fetchCampaigns() {
  const data = await queryRows(
    'artwork_campaigns',
    `*,
     artwork_campaign_categories(artwork_campaign_category_id, category_name, state_id)`,
    q => q.order('created_at', { ascending: false })
  );
  
  return data;
}

/**
 * Fetch reference data needed for creating campaigns (e.g., states).
 */
export async function fetchReferenceData() {
  const states = await queryRows('states', '*', q => q.eq('is_active', true).order('state_name'));
  return { states };
}

/**
 * Create a new campaign and its categories.
 */
export async function createCampaign(campaignData, selectedCategories, profileId) {
  // 1. Generate Campaign ID
  const campaignId = await getNextId('artwork_campaigns', 'artwork_campaign_id', 'AC');

  // 2. Insert Campaign
  const campaignPayload = {
    artwork_campaign_id: campaignId,
    campaign_title: campaignData.campaign_title,
    description: campaignData.description || null,
    submission_start_at: campaignData.submission_start_at,
    submission_end_at: campaignData.submission_end_at,
    status: campaignData.status || 'draft',
    created_by_profile_id: profileId,
  };

  await insertRows('artwork_campaigns', [campaignPayload]);

  // 3. Generate Category IDs and Insert Categories
  if (selectedCategories && selectedCategories.length > 0) {
    // Generate IDs sequentially to avoid race condition or use a batch approach if possible.
    // However, since we need sequential IDs like ACC0001, ACC0002...
    // We can get the next ID, then increment in JS for this batch.
    let nextCatIdStr = await getNextId('artwork_campaign_categories', 'artwork_campaign_category_id', 'ACC');
    let nextCatNum = parseInt(nextCatIdStr.replace('ACC', ''), 10);

    const categoryPayloads = selectedCategories.map((cat) => {
      const catId = `ACC${String(nextCatNum).padStart(4, '0')}`;
      nextCatNum++;
      return {
        artwork_campaign_category_id: catId,
        artwork_campaign_id: campaignId,
        state_id: cat.state_id,
        category_name: cat.category_name
      };
    });

    await insertRows('artwork_campaign_categories', categoryPayloads);
  }

  // Fetch the created campaign with categories joined
  const newCampaignData = await queryRows(
    'artwork_campaigns',
    `*,
     artwork_campaign_categories(artwork_campaign_category_id, category_name, state_id)`,
    q => q.eq('artwork_campaign_id', campaignId)
  );

  return newCampaignData[0];
}

/**
 * Update an existing campaign and its categories.
 */
export async function updateCampaign(campaignId, campaignData, selectedCategories) {
  // 1. Update Campaign
  const campaignPayload = {
    campaign_title: campaignData.campaign_title,
    description: campaignData.description || null,
    submission_start_at: campaignData.submission_start_at,
    submission_end_at: campaignData.submission_end_at,
    status: campaignData.status || 'draft',
  };

  await updateRows('artwork_campaigns', campaignPayload, q => q.eq('artwork_campaign_id', campaignId));

  // 2. Sync Categories (Delete existing, insert new)
  if (selectedCategories && selectedCategories.length >= 0) {
    await deleteRows('artwork_campaign_categories', q => q.eq('artwork_campaign_id', campaignId));
    
    if (selectedCategories.length > 0) {
      let nextCatIdStr = await getNextId('artwork_campaign_categories', 'artwork_campaign_category_id', 'ACC');
      let nextCatNum = parseInt(nextCatIdStr.replace('ACC', ''), 10);

      const categoryPayloads = selectedCategories.map((cat) => {
        const catId = `ACC${String(nextCatNum).padStart(4, '0')}`;
        nextCatNum++;
        return {
          artwork_campaign_category_id: catId,
          artwork_campaign_id: campaignId,
          state_id: cat.state_id,
          category_name: cat.category_name
        };
      });

      await insertRows('artwork_campaign_categories', categoryPayloads);
    }
  }

  // Fetch the updated campaign with categories joined
  const updatedCampaignData = await queryRows(
    'artwork_campaigns',
    `*,
     artwork_campaign_categories(artwork_campaign_category_id, category_name, state_id)`,
    q => q.eq('artwork_campaign_id', campaignId)
  );

  return updatedCampaignData[0];
}

/**
 * Mark a campaign as completed.
 */
export async function completeCampaign(campaignId) {
  const [updatedCampaign] = await updateRows(
    'artwork_campaigns',
    { status: 'completed' },
    q => q.eq('artwork_campaign_id', campaignId)
  );

  // Fetch the full joined record
  const fullUpdatedData = await queryRows(
    'artwork_campaigns',
    `*,
     artwork_campaign_categories(artwork_campaign_category_id, category_name, state_id)`,
    q => q.eq('artwork_campaign_id', campaignId)
  );

  return fullUpdatedData[0] || updatedCampaign;
}

/**
 * Deactivate an active campaign (mark as cancelled).
 */
export async function deactivateCampaign(campaignId) {
  const [updatedCampaign] = await updateRows(
    'artwork_campaigns',
    { status: 'cancelled' },
    q => q.eq('artwork_campaign_id', campaignId)
  );

  // Fetch the full joined record
  const fullUpdatedData = await queryRows(
    'artwork_campaigns',
    `*,
     artwork_campaign_categories(artwork_campaign_category_id, category_name, state_id)`,
    q => q.eq('artwork_campaign_id', campaignId)
  );

  return fullUpdatedData[0] || updatedCampaign;
}

/**
 * Fetch all artwork submissions with nested relations for review.
 */
export async function fetchSubmissions() {
  const data = await queryRows(
    'artwork_submissions',
    `*,
     profiles!artwork_submissions_profile_id_fkey(display_name),
     artwork_campaign_categories(
       category_name,
       state_id,
       artwork_campaigns(campaign_title)
     )`,
    q => q.order('submitted_at', { ascending: false })
  );
  
  return data;
}

/**
 * Reject a pending artwork submission.
 */
export async function rejectSubmission(submissionId, profileId) {
  const [updatedSubmission] = await updateRows(
    'artwork_submissions',
    {
      review_status: 'rejected',
      reviewed_by_profile_id: profileId,
      reviewed_at: new Date().toISOString(),
    },
    q => q.eq('artwork_submission_id', submissionId).eq('review_status', 'pending')
  );

  if (!updatedSubmission) {
    throw new Error('Could not reject the submission. It may no longer be pending or does not exist.');
  }

  // Fetch the full joined record to refresh UI accurately
  const fullUpdatedData = await queryRows(
    'artwork_submissions',
    `*,
     profiles!artwork_submissions_profile_id_fkey(display_name),
     artwork_campaign_categories(
       category_name,
       state_id,
       artwork_campaigns(campaign_title)
     )`,
    q => q.eq('artwork_submission_id', submissionId)
  );

  return fullUpdatedData[0] || updatedSubmission;
}

/**
 * Fetch voting sessions.
 */
export async function fetchVotingSessions() {
  const data = await queryRows(
    'artwork_voting_sessions',
    `*,
     artwork_campaigns(campaign_title)`,
    q => q.order('voting_start_at', { ascending: false })
  );
  return data;
}

/**
 * Create a standard voting session and its entries.
 */
export async function createVotingSession(campaignId, startAt, endAt, selectedSubmissions) {
  // 1. Create the session
  const sessionId = await getNextId('artwork_voting_sessions', 'artwork_voting_session_id', 'AVS');
  
  const status = new Date(startAt) > new Date() ? 'scheduled' : 'active';

  const sessionPayload = {
    artwork_voting_session_id: sessionId,
    artwork_campaign_id: campaignId,
    voting_start_at: startAt,
    voting_end_at: endAt,
    status: status
  };

  await insertRows('artwork_voting_sessions', [sessionPayload]);

  // 2. Create the entries
  if (selectedSubmissions && selectedSubmissions.length > 0) {
    let nextEntryIdStr = await getNextId('artwork_voting_entries', 'artwork_voting_entry_id', 'AVE');
    let nextEntryNum = parseInt(nextEntryIdStr.replace('AVE', ''), 10);

    const entryPayloads = selectedSubmissions.map((sub) => {
      const entryId = `AVE${String(nextEntryNum).padStart(4, '0')}`;
      nextEntryNum++;
      
      return {
        artwork_voting_entry_id: entryId,
        artwork_voting_session_id: sessionId,
        artwork_campaign_category_id: sub.artwork_campaign_category_id,
        artwork_submission_id: sub.artwork_submission_id,
        vote_count: 0
      };
    });

    await insertRows('artwork_voting_entries', entryPayloads);
  }

  // 3. Return the created session
  const [newSession] = await queryRows(
    'artwork_voting_sessions',
    `*, artwork_campaigns(campaign_title)`,
    q => q.eq('artwork_voting_session_id', sessionId)
  );
  
  return newSession;
}

/**
 * Fetch a specific voting session with its entries and submission details.
 */
export async function fetchVotingSessionDetails(sessionId) {
  // Fetch session with entries and relations
  const data = await queryRows(
    'artwork_voting_sessions',
    `*,
     artwork_campaigns(campaign_title),
     artwork_voting_entries(
       artwork_voting_entry_id,
       vote_count,
       artwork_campaign_categories(category_name, state_id),
       artwork_submissions(
         artwork_title,
         artwork_file_url,
         profiles!artwork_submissions_profile_id_fkey(display_name)
       )
     )`,
    q => q.eq('artwork_voting_session_id', sessionId)
  );

  return data[0];
}

/**
 * Finalize an ended voting session using the backend RPC.
 */
export async function finalizeVotingSession(sessionId) {
  const { data, error } = await supabase.rpc('finalize_artwork_voting_session', {
    session_id: sessionId
  });

  if (error) {
    throw new Error(error.message || 'Failed to finalize voting session.');
  }

  return data;
}

/**
 * Create a tie-break voting session via backend RPC.
 */
export async function createTieBreakSession(parentSessionId, categoryId, startAt, endAt) {
  const { data, error } = await supabase.rpc('create_tie_break_session', {
    parent_session_id: parentSessionId,
    category_id: categoryId,
    voting_start_at: startAt,
    voting_end_at: endAt
  });

  if (error) {
    throw new Error(error.message || 'Failed to create tie-break session.');
  }

  return data;
}

/**
 * Fetch campaign winners for a specific campaign.
 */
export async function fetchCampaignWinners(campaignId) {
  const data = await queryRows(
    'artwork_campaign_winners',
    `*,
     artwork_campaigns(campaign_title, description),
     artworks(artwork_id, title, status),
     artwork_voting_entries(
       vote_count,
       artwork_voting_sessions(artwork_voting_session_id, session_type),
       artwork_submissions(
         artwork_submission_id,
         artwork_title,
         artwork_description,
         cultural_inspiration,
         artwork_file_url,
         profile_id,
         profiles!artwork_submissions_profile_id_fkey(display_name)
       )
     ),
     artwork_campaign_categories(category_name, state_id)
    `,
    q => q.eq('artwork_campaign_id', campaignId).order('final_rank', { ascending: true })
  );
  return data;
}

/**
 * Promote a winning submission to an official artwork.
 */
export async function promoteWinnerToArtwork(winnerId, submissionData) {
  const newArtworkId = await getNextId('artworks', 'artwork_id', 'A');
  
  const payload = {
    artwork_id: newArtworkId,
    profile_id: submissionData.profile_id,
    source_artwork_submission_id: submissionData.artwork_submission_id,
    title: submissionData.artwork_title,
    description: submissionData.artwork_description || null,
    cultural_inspiration: submissionData.cultural_inspiration || null,
    image_url: submissionData.artwork_file_url,
    status: 'published'
  };

  await insertRows('artworks', [payload]);
  
  await updateRows(
    'artwork_campaign_winners',
    { artwork_id: newArtworkId },
    q => q.eq('artwork_campaign_winner_id', winnerId)
  );

  return newArtworkId;
}
