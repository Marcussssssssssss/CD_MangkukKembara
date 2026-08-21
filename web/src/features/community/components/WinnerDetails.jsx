import Modal from '../../../components/Modal';

export default function WinnerDetails({ winner, isOpen, onClose }) {
  if (!winner) return null;

  const campaign = winner.artwork_campaigns;
  const entry = winner.artwork_voting_entries;
  const submission = entry?.artwork_submissions;
  const artist = submission?.profiles?.display_name || 'Unknown Artist';
  const photos = [...(submission?.artwork_submission_photos || [])]
    .sort((a, b) => a.sort_order - b.sort_order);
  const photoLabels = {
    front_hero: 'Front Hero',
    layer_1_flat_360: 'Layer 1 · Flat 360°',
    layer_2_flat_360: 'Layer 2 · Flat 360°',
    layer_3_flat_360: 'Layer 3 · Flat 360°',
  };

  return (
    <Modal open={isOpen} onClose={onClose} title="Campaign Winner Details" size="2xl">
      <div className="flex max-h-[85vh] flex-col overflow-y-auto p-6">
        <div className="flex items-start justify-between gap-4 border-b border-surface-200 pb-4">
          <div>
            <h3 className="text-2xl font-bold text-surface-900">
              {submission?.artwork_title || 'Untitled Artwork'}
            </h3>
            <p className="mt-1 text-sm font-medium text-surface-500">
              Designed by <span className="text-surface-900">{artist}</span>
            </p>
          </div>
          <span className="shrink-0 rounded-full bg-yellow-100 px-3 py-1 text-xs font-semibold text-yellow-800">
            Confirmed Winner
          </span>
        </div>

        <div className="mt-6 rounded-lg border border-surface-200 bg-surface-50 p-4">
          <div className="grid gap-4 sm:grid-cols-3">
            <div>
              <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">Campaign</h4>
              <p className="mt-1 text-sm font-medium text-surface-900">
                {campaign?.campaign_title || 'Unknown Campaign'}
              </p>
            </div>
            <div>
              <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">State</h4>
              <p className="mt-1 text-sm font-medium text-surface-900">
                {campaign?.states?.state_name || campaign?.state_id || 'Unknown State'}
              </p>
            </div>
            <div>
              <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">Final Vote Count</h4>
              <p className="mt-1 text-xl font-bold text-primary-600">{winner.final_vote_count}</p>
            </div>
          </div>
        </div>

        <div className="mt-6">
          <h4 className="mb-3 text-xs font-medium uppercase tracking-wider text-surface-400">Artwork Photos</h4>
          {photos.length > 0 ? (
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
              {photos.map((photo) => (
                <a key={photo.artwork_submission_photo_id} href={photo.photo_url} target="_blank" rel="noreferrer" className="group">
                  <div className="aspect-square overflow-hidden rounded-xl border border-surface-200 bg-surface-100">
                    <img
                      src={photo.photo_url}
                      alt={`${submission?.artwork_title || 'Winning artwork'} – ${photoLabels[photo.view_type] || photo.view_type}`}
                      className="h-full w-full object-cover transition-transform group-hover:scale-105"
                    />
                  </div>
                  <p className="mt-2 text-sm font-medium text-surface-700 group-hover:text-primary-600">
                    {photoLabels[photo.view_type] || photo.view_type}
                  </p>
                </a>
              ))}
            </div>
          ) : (
            <div className="overflow-hidden rounded-xl border border-surface-200 bg-surface-100">
              {submission?.artwork_file_url ? (
                <img
                  src={submission.artwork_file_url}
                  alt={submission.artwork_title || 'Winning artwork'}
                  className="max-h-96 w-full object-contain"
                />
              ) : (
                <p className="p-6 text-center text-sm text-surface-500">No artwork image available.</p>
              )}
            </div>
          )}
        </div>

        <div className="mt-6 grid grid-cols-1 gap-6 md:grid-cols-2">
          <div className="space-y-6">
            <Detail label="Design Description" value={submission?.design_description} />
            <Detail label="Cultural Inspiration" value={submission?.cultural_inspiration} />
          </div>
          <div className="space-y-6">
            <Detail label="Layer 1 Meaning" value={submission?.layer_1_meaning} />
            <Detail label="Layer 2 Meaning" value={submission?.layer_2_meaning} />
            <Detail label="Layer 3 Meaning" value={submission?.layer_3_meaning} />
          </div>
        </div>

        <div className="mt-8 flex justify-end border-t border-surface-100 pt-4">
          <button
            type="button"
            onClick={onClose}
            className="rounded-lg px-4 py-2 text-sm font-medium text-surface-700 hover:bg-surface-100"
          >
            Back to Campaign Details
          </button>
        </div>
      </div>
    </Modal>
  );
}

function Detail({ label, value }) {
  return (
    <div>
      <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">{label}</h4>
      <p className="mt-2 whitespace-pre-wrap rounded-lg border border-surface-100 bg-white p-3 text-sm text-surface-700">
        {value || 'None provided.'}
      </p>
    </div>
  );
}
