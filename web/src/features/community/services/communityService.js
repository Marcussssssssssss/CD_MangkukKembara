import {
  queryRows,
  insertRows,
  updateRows,
} from '../../../services/supabase/api';

const CAMPAIGN_STATUSES = new Set(['active', 'completed']);

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
  ),
  artwork_submission_photos!artwork_submission_photos_artwork_submission_id_fkey(
    artwork_submission_photo_id,
    view_type,
    photo_url,
    sort_order,
    created_at
  )
`;

function toIsoTimestamp(value, fieldName) {
  const parsed = new Date(value);

  if (Number.isNaN(parsed.getTime())) {
    throw new Error(`${fieldName} must be a valid date and time.`);
  }

  return parsed.toISOString();
}

function campaignDateToIsoTimestamp(value, fieldName, time = '23:59:00') {
  const timestamp = /^\d{4}-\d{2}-\d{2}$/.test(value || '')
    ? `${value}T${time}`
    : value;
  return toIsoTimestamp(timestamp, fieldName);
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

  const submissionStartAt = campaignDateToIsoTimestamp(
    campaignData.submission_start_at,
    'Submission start',
    '00:00:00',
  );
  const submissionEndAt = campaignDateToIsoTimestamp(
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
    submissions.flatMap(submission => [
      submission.profile_id,
      submission.reviewed_by_profile_id,
    ]),
  );

  return submissions.map(submission => ({
    ...mergePublicProfileIntoSubmission(submission, publicProfilesById),
    reviewer_profile: publicProfilesById.get(submission.reviewed_by_profile_id) || null,
  }));
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
    query => {
      const scopedQuery = query.eq('artwork_submission_id', submissionId);
      return reviewStatus === 'approved'
        ? scopedQuery.in('review_status', ['pending', 'rejected'])
        : scopedQuery.eq('review_status', 'pending');
    },
  );

  if (!updatedSubmission) {
    throw new Error(
      `Could not mark the submission as ${reviewStatus}. Its status may have changed or it may no longer exist.`,
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
  const [states, foods] = await Promise.all([
    queryRows(
      'states',
      '*',
      query => query.eq('is_active', true).order('state_name'),
    ),
    queryRows(
      'heritage_foods',
      'state_id',
      query => query.eq('is_active', true),
    ),
  ]);
  const foodStateIds = new Set(foods.map(food => food.state_id));

  return {
    states: states.map(state => ({
      ...state,
      has_heritage_food: foodStateIds.has(state.state_id),
    })),
  };
}

async function assertStateHasHeritageFood(stateId) {
  const foods = await queryRows(
    'heritage_foods',
    'heritage_food_id',
    query => query.eq('state_id', stateId).eq('is_active', true).limit(1),
  );
  if (foods.length === 0) {
    throw new Error('This state has no active Heritage Food. Add one before creating a campaign.');
  }
}

/**
 * Create one state-specific campaign. The database supplies its campaign ID.
 */
export async function createCampaign(campaignData, profileId) {
  if (!profileId) {
    throw new Error('An administrator profile is required to create a campaign.');
  }
  await assertStateHasHeritageFood(campaignData.state_id);

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
  await assertStateHasHeritageFood(campaignData.state_id);
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
 * End an active campaign immediately.
 */
export async function endCampaign(campaignId) {
  const endDate = new Date();
  endDate.setHours(23, 59, 0, 0);
  const [updatedCampaign] = await updateRows(
    'artwork_campaigns',
    { submission_end_at: endDate.toISOString(), status: 'completed' },
    query => query.eq('artwork_campaign_id', campaignId),
  );

  if (!updatedCampaign) {
    throw new Error('The campaign could not be ended.');
  }

  return (await fetchCampaignById(campaignId)) || updatedCampaign;
}

export async function fetchCampaignTopVotedArtworks(campaignId) {
  const entries = await queryRows(
    'artwork_voting_entries',
    `
      artwork_voting_entry_id,
      vote_count,
      artwork_voting_sessions!inner(artwork_campaign_id),
      artwork_submissions!artwork_voting_entries_artwork_submission_id_fkey(
        artwork_submission_id,
        artwork_title,
        artwork_file_url
      )
    `,
    query => query
      .eq('artwork_voting_sessions.artwork_campaign_id', campaignId)
      .order('vote_count', { ascending: false }),
  );

  if (entries.length === 0) return [];
  const highestVoteCount = entries[0].vote_count;
  return entries.filter(entry => entry.vote_count === highestVoteCount);
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
          layer_1_meaning,
          layer_2_meaning,
          layer_3_meaning,
          artwork_file_url,
          profile_id,
          artwork_submission_photos!artwork_submission_photos_artwork_submission_id_fkey(
            artwork_submission_photo_id,
            view_type,
            photo_url,
            sort_order
          )
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
