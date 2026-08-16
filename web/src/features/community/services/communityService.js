import {
  supabase,
  queryRows,
  insertRows,
  updateRows,
  deleteRows,
} from '../../../services/supabase/api';

const CAMPAIGN_STATUSES = new Set(['active', 'completed', 'inactive']);

const CAMPAIGN_SELECT = `
  *,
  states!artwork_campaigns_state_id_fkey(
    state_id,
    state_code,
    state_name
  )
`;

const SUBMISSION_SELECT = `
  *,
  artwork_campaigns!artwork_submissions_artwork_campaign_id_fkey(
    artwork_campaign_id,
    campaign_title,
    state_id,
    states!artwork_campaigns_state_id_fkey(
      state_id,
      state_code,
      state_name
    )
  )
`;

const VOTING_SESSION_SELECT = `
  *,
  artwork_campaigns!artwork_voting_sessions_artwork_campaign_id_fkey(
    artwork_campaign_id,
    campaign_title,
    status,
    state_id,
    states!artwork_campaigns_state_id_fkey(
      state_id,
      state_code,
      state_name
    )
  )
`;

function toIsoTimestamp(value, fieldName) {
  const parsed = new Date(value);

  if (Number.isNaN(parsed.getTime())) {
    throw new Error(`${fieldName} must be a valid date and time.`);
  }

  return parsed.toISOString();
}

function campaignPayloadFrom(campaignData) {
  if (!campaignData?.state_id) {
    throw new Error('A state is required for the campaign.');
  }

  if (!campaignData.campaign_title?.trim()) {
    throw new Error('A campaign title is required.');
  }

  const status = campaignData.status || 'active';
  if (!CAMPAIGN_STATUSES.has(status)) {
    throw new Error(`Unsupported campaign status: ${status}.`);
  }

  const submissionStartAt = toIsoTimestamp(
    campaignData.submission_start_at,
    'Submission start',
  );
  const submissionEndAt = toIsoTimestamp(
    campaignData.submission_end_at,
    'Submission end',
  );

  if (new Date(submissionEndAt) <= new Date(submissionStartAt)) {
    throw new Error('Submission end must be later than submission start.');
  }

  return {
    state_id: campaignData.state_id,
    campaign_title: campaignData.campaign_title.trim(),
    description: campaignData.description?.trim() || null,
    submission_start_at: submissionStartAt,
    submission_end_at: submissionEndAt,
    status,
  };
}

function relationRows(relation) {
  if (Array.isArray(relation)) return relation;
  return relation ? [relation] : [];
}

function mapRelation(relation, mapper) {
  if (Array.isArray(relation)) return relation.map(mapper);
  return relation ? mapper(relation) : relation;
}

async function fetchPublicProfilesById(profileIds) {
  const uniqueProfileIds = [...new Set(profileIds.filter(Boolean))];
  if (uniqueProfileIds.length === 0) return new Map();

  const publicProfiles = await queryRows(
    'public_profiles',
    'profile_id, display_name, avatar_url',
    query => query.in('profile_id', uniqueProfileIds),
  );

  return new Map(
    publicProfiles.map(profile => [profile.profile_id, profile]),
  );
}

function mergePublicProfileIntoSubmission(submission, publicProfilesById) {
  if (!submission) return submission;

  return {
    ...submission,
    profiles: publicProfilesById.get(submission.profile_id) || null,
  };
}

async function enrichSubmissionsWithPublicProfiles(submissions) {
  const publicProfilesById = await fetchPublicProfilesById(
    submissions.map(submission => submission.profile_id),
  );

  return submissions.map(submission => (
    mergePublicProfileIntoSubmission(submission, publicProfilesById)
  ));
}

function submissionProfileIdsFromEntries(entries) {
  return relationRows(entries).flatMap(entry => (
    relationRows(entry.artwork_submissions)
      .map(submission => submission.profile_id)
  ));
}

function mergePublicProfilesIntoEntries(entries, publicProfilesById) {
  return mapRelation(entries, entry => ({
    ...entry,
    artwork_submissions: mapRelation(
      entry.artwork_submissions,
      submission => mergePublicProfileIntoSubmission(
        submission,
        publicProfilesById,
      ),
    ),
  }));
}

async function fetchCampaignById(campaignId) {
  const [campaign] = await queryRows(
    'artwork_campaigns',
    CAMPAIGN_SELECT,
    query => query.eq('artwork_campaign_id', campaignId),
  );

  return campaign || null;
}

async function fetchSubmissionById(submissionId) {
  const [submission] = await queryRows(
    'artwork_submissions',
    SUBMISSION_SELECT,
    query => query.eq('artwork_submission_id', submissionId),
  );

  if (!submission) return null;

  const [enrichedSubmission] = await enrichSubmissionsWithPublicProfiles([
    submission,
  ]);

  return enrichedSubmission;
}

async function fetchVotingSessionById(sessionId) {
  const [session] = await queryRows(
    'artwork_voting_sessions',
    VOTING_SESSION_SELECT,
    query => query.eq('artwork_voting_session_id', sessionId),
  );

  return session || null;
}

async function reviewSubmission(submissionId, profileId, reviewStatus) {
  if (!profileId) {
    throw new Error('An administrator profile is required to review a submission.');
  }

  const [updatedSubmission] = await updateRows(
    'artwork_submissions',
    {
      review_status: reviewStatus,
      reviewed_by_profile_id: profileId,
      reviewed_at: new Date().toISOString(),
    },
    query => query
      .eq('artwork_submission_id', submissionId)
      .eq('review_status', 'pending'),
  );

  if (!updatedSubmission) {
    throw new Error(
      `Could not mark the submission as ${reviewStatus}. It may no longer be pending or does not exist.`,
    );
  }

  return (await fetchSubmissionById(submissionId)) || updatedSubmission;
}

/**
 * Fetch all campaigns with their directly related state.
 */
export async function fetchCampaigns() {
  return queryRows(
    'artwork_campaigns',
    CAMPAIGN_SELECT,
    query => query.order('created_at', { ascending: false }),
  );
}

/**
 * Fetch reference data needed for campaign forms.
 */
export async function fetchReferenceData() {
  const states = await queryRows(
    'states',
    '*',
    query => query.eq('is_active', true).order('state_name'),
  );

  return { states };
}

/**
 * Create one state-specific campaign. The database supplies its campaign ID.
 */
export async function createCampaign(campaignData, profileId) {
  if (!profileId) {
    throw new Error('An administrator profile is required to create a campaign.');
  }

  const [createdCampaign] = await insertRows('artwork_campaigns', [{
    ...campaignPayloadFrom(campaignData),
    created_by_profile_id: profileId,
  }]);

  if (!createdCampaign) {
    throw new Error('The campaign was not created.');
  }

  return (
    (await fetchCampaignById(createdCampaign.artwork_campaign_id))
    || createdCampaign
  );
}

/**
 * Update a state-specific campaign without creating or synchronising categories.
 */
export async function updateCampaign(campaignId, campaignData) {
  const [updatedCampaign] = await updateRows(
    'artwork_campaigns',
    campaignPayloadFrom(campaignData),
    query => query.eq('artwork_campaign_id', campaignId),
  );

  if (!updatedCampaign) {
    throw new Error('The campaign could not be updated or does not exist.');
  }

  return (await fetchCampaignById(campaignId)) || updatedCampaign;
}

/**
 * Deactivate a campaign using the category-free schema's inactive status.
 */
export async function deactivateCampaign(campaignId) {
  const [updatedCampaign] = await updateRows(
    'artwork_campaigns',
    { status: 'inactive' },
    query => query.eq('artwork_campaign_id', campaignId),
  );

  if (!updatedCampaign) {
    throw new Error('The campaign could not be deactivated or does not exist.');
  }

  return (await fetchCampaignById(campaignId)) || updatedCampaign;
}

/**
 * Fetch submissions with their artist, campaign and campaign state.
 */
export async function fetchSubmissions() {
  const submissions = await queryRows(
    'artwork_submissions',
    SUBMISSION_SELECT,
    query => query.order('submitted_at', { ascending: false }),
  );

  return enrichSubmissionsWithPublicProfiles(submissions);
}

/**
 * Approve a pending artwork submission.
 */
export async function approveSubmission(submissionId, profileId) {
  return reviewSubmission(submissionId, profileId, 'approved');
}

/**
 * Reject a pending artwork submission.
 */
export async function rejectSubmission(submissionId, profileId) {
  return reviewSubmission(submissionId, profileId, 'rejected');
}

/**
 * Fetch voting sessions with campaign and state information.
 */
export async function fetchVotingSessions() {
  return queryRows(
    'artwork_voting_sessions',
    VOTING_SESSION_SELECT,
    query => query.order('voting_start_at', { ascending: false }),
  );
}

/**
 * Create a standard session as scheduled, publish its entries, then activate it
 * only if its voting window has already started and has not ended.
 */
export async function createVotingSession(
  campaignId,
  startAt,
  endAt,
  selectedSubmissions,
) {
  if (!campaignId) {
    throw new Error('A campaign is required for the voting session.');
  }

  const votingStartAt = toIsoTimestamp(startAt, 'Voting start');
  const votingEndAt = toIsoTimestamp(endAt, 'Voting end');

  if (new Date(votingEndAt) <= new Date(votingStartAt)) {
    throw new Error('Voting end must be later than voting start.');
  }

  const submissionIds = [...new Set(
    (selectedSubmissions || [])
      .map(submission => (
        typeof submission === 'string'
          ? submission
          : submission?.artwork_submission_id
      ))
      .filter(Boolean),
  )];

  if (submissionIds.length === 0) {
    throw new Error('Select at least one approved submission.');
  }

  const [createdSession] = await insertRows('artwork_voting_sessions', [{
    artwork_campaign_id: campaignId,
    voting_start_at: votingStartAt,
    voting_end_at: votingEndAt,
    status: 'scheduled',
    session_type: 'standard',
  }]);

  if (!createdSession) {
    throw new Error('The voting session was not created.');
  }

  const sessionId = createdSession.artwork_voting_session_id;
  const entryPayloads = submissionIds.map(submissionId => ({
    artwork_voting_session_id: sessionId,
    artwork_submission_id: submissionId,
  }));

  try {
    await insertRows('artwork_voting_entries', entryPayloads);
  } catch (error) {
    // The batch insert is atomic. Remove the still-empty scheduled session so a
    // corrected retry is not blocked by the one-standard-session constraint.
    try {
      await deleteRows(
        'artwork_voting_sessions',
        query => query.eq('artwork_voting_session_id', sessionId),
      );
    } catch {
      // Preserve the original entry-validation error for the caller.
    }

    throw error;
  }

  const now = new Date();
  if (new Date(votingStartAt) <= now && now < new Date(votingEndAt)) {
    await updateRows(
      'artwork_voting_sessions',
      { status: 'active' },
      query => query
        .eq('artwork_voting_session_id', sessionId)
        .eq('status', 'scheduled'),
    );
  }

  return (await fetchVotingSessionById(sessionId)) || createdSession;
}

/**
 * Activate a scheduled standard or tie-break session.
 */
export async function activateVotingSession(sessionId) {
  const [updatedSession] = await updateRows(
    'artwork_voting_sessions',
    { status: 'active' },
    query => query
      .eq('artwork_voting_session_id', sessionId)
      .eq('status', 'scheduled'),
  );

  if (!updatedSession) {
    throw new Error('Only an existing scheduled voting session can be activated.');
  }

  return (await fetchVotingSessionById(sessionId)) || updatedSession;
}

/**
 * Close a voting session before finalisation or tie-break creation.
 */
export async function closeVotingSession(sessionId) {
  const [updatedSession] = await updateRows(
    'artwork_voting_sessions',
    { status: 'closed' },
    query => query.eq('artwork_voting_session_id', sessionId),
  );

  if (!updatedSession) {
    throw new Error('The voting session could not be closed or does not exist.');
  }

  return (await fetchVotingSessionById(sessionId)) || updatedSession;
}

/**
 * Fetch one voting session with category-free entry and submission details.
 */
export async function fetchVotingSessionDetails(sessionId) {
  const [session] = await queryRows(
    'artwork_voting_sessions',
    `
      *,
      artwork_campaigns!artwork_voting_sessions_artwork_campaign_id_fkey(
        artwork_campaign_id,
        campaign_title,
        status,
        state_id,
        states!artwork_campaigns_state_id_fkey(
          state_id,
          state_code,
          state_name
        )
      ),
      artwork_voting_entries!artwork_voting_entries_artwork_voting_session_id_fkey(
        artwork_voting_entry_id,
        artwork_submission_id,
        vote_count,
        published_at,
        artwork_submissions!artwork_voting_entries_artwork_submission_id_fkey(
          artwork_submission_id,
          artwork_title,
          design_description,
          cultural_inspiration,
          artist_statement,
          artwork_file_url,
          profile_id
        )
      )
    `,
    query => query.eq('artwork_voting_session_id', sessionId),
  );

  if (!session) return null;

  const publicProfilesById = await fetchPublicProfilesById(
    submissionProfileIdsFromEntries(session.artwork_voting_entries),
  );

  return {
    ...session,
    artwork_voting_entries: mergePublicProfilesIntoEntries(
      session.artwork_voting_entries,
      publicProfilesById,
    ),
  };
}

/**
 * Finalize a closed, uniquely won session. The RPC creates the artwork and
 * winner record and completes the campaign atomically.
 */
export async function finalizeVotingSession(sessionId) {
  const { data, error } = await supabase.rpc(
    'finalize_artwork_voting_session',
    { p_artwork_voting_session_id: sessionId },
  );

  if (error) {
    throw new Error(error.message || 'Failed to finalize voting session.');
  }

  return data;
}

/**
 * Create a category-free tie-break. The RPC copies only the parent's top-tied
 * submissions and returns the database-generated session ID.
 */
export async function createTieBreakSession(parentSessionId, startAt, endAt) {
  const votingStartAt = toIsoTimestamp(startAt, 'Tie-break voting start');
  const votingEndAt = toIsoTimestamp(endAt, 'Tie-break voting end');

  if (new Date(votingEndAt) <= new Date(votingStartAt)) {
    throw new Error('Tie-break voting end must be later than voting start.');
  }

  const { data: sessionId, error } = await supabase.rpc(
    'create_tie_break_session',
    {
      p_parent_voting_session_id: parentSessionId,
      p_voting_start_at: votingStartAt,
      p_voting_end_at: votingEndAt,
    },
  );

  if (error) {
    throw new Error(error.message || 'Failed to create tie-break session.');
  }

  if (!sessionId) {
    throw new Error('The tie-break session was not created.');
  }

  const now = new Date();
  if (new Date(votingStartAt) <= now && now < new Date(votingEndAt)) {
    return activateVotingSession(sessionId);
  }

  return fetchVotingSessionById(sessionId);
}

/**
 * Fetch the finalized winner and its automatically created official artwork.
 */
export async function fetchCampaignWinners(campaignId) {
  const winners = await queryRows(
    'artwork_campaign_winners',
    `
      *,
      artwork_campaigns!artwork_campaign_winners_artwork_campaign_id_fkey(
        artwork_campaign_id,
        campaign_title,
        description,
        state_id,
        states!artwork_campaigns_state_id_fkey(
          state_id,
          state_code,
          state_name
        )
      ),
      artworks!artwork_campaign_winners_artwork_id_fkey(
        artwork_id,
        title,
        description,
        artwork_meaning,
        cultural_inspiration,
        image_url,
        status
      ),
      artwork_voting_entries!fk_winner_entry_session(
        artwork_voting_entry_id,
        vote_count,
        artwork_voting_sessions!artwork_voting_entries_artwork_voting_session_id_fkey(
          artwork_voting_session_id,
          session_type
        ),
        artwork_submissions!artwork_voting_entries_artwork_submission_id_fkey(
          artwork_submission_id,
          artwork_title,
          design_description,
          cultural_inspiration,
          artist_statement,
          artwork_file_url,
          profile_id
        )
      )
    `,
    query => query
      .eq('artwork_campaign_id', campaignId)
      .order('final_rank', { ascending: true }),
  );

  const publicProfilesById = await fetchPublicProfilesById(
    winners.flatMap(winner => (
      submissionProfileIdsFromEntries(winner.artwork_voting_entries)
    )),
  );

  return winners.map(winner => ({
    ...winner,
    artwork_voting_entries: mergePublicProfilesIntoEntries(
      winner.artwork_voting_entries,
      publicProfilesById,
    ),
  }));
}
