import Modal from '../../../components/Modal';

export default function SubmissionDetails({ submission, isOpen, onClose, onApprove, onReject }) {
  if (!submission) return null;

  const statusColors = {
    pending: 'bg-yellow-100 text-yellow-800',
    approved: 'bg-green-100 text-green-700',
    rejected: 'bg-red-100 text-red-700',
  };

  const getStatusDisplay = (status) => status.charAt(0).toUpperCase() + status.slice(1);

  const submitter = submission.profiles?.display_name || submission.profile_id;
  const campaign = submission.artwork_campaigns;
  const campaignTitle = campaign?.campaign_title || 'Unknown Campaign';
  const dateSubmitted = new Date(submission.submitted_at).toLocaleString();
  const reviewedBy = submission.reviewer_profile?.display_name
    || submission.reviewed_by_profile_id
    || 'Not reviewed';
  const photos = [...(submission.artwork_submission_photos || [])]
    .sort((a, b) => a.sort_order - b.sort_order);
  const photoLabels = {
    front_hero: 'Front Hero',
    layer_1_flat_360: 'Layer 1 · Flat 360°',
    layer_2_flat_360: 'Layer 2 · Flat 360°',
    layer_3_flat_360: 'Layer 3 · Flat 360°',
  };

  return (
    <Modal open={isOpen} onClose={onClose} title="Review Submission" size="2xl">
      <div className="flex flex-col p-6 max-h-[85vh] overflow-y-auto">
        
        {/* Header Section */}
        <div className="flex items-start justify-between gap-4 border-b border-surface-200 pb-4">
          <div>
            <h3 className="text-2xl font-bold text-surface-900">{submission.artwork_title}</h3>
            <p className="text-sm font-medium text-surface-500 mt-1">Submitted by <span className="text-surface-900">{submitter}</span> on {dateSubmitted}</p>
          </div>
          <span className={`shrink-0 inline-flex items-center rounded-full px-3 py-1 text-xs font-semibold ${statusColors[submission.review_status] || 'bg-surface-100 text-surface-700'}`}>
            {getStatusDisplay(submission.review_status)}
          </span>
        </div>

        {/* Campaign Info */}
        <div className="mt-6 bg-surface-50 p-4 rounded-lg border border-surface-200">
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <div>
            <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">Campaign</h4>
            <p className="mt-1 text-sm font-medium text-surface-900">{campaignTitle}</p>
            {(campaign?.states?.state_name || campaign?.state_id) && (
              <p className="mt-1 text-xs text-surface-500">
                State: {campaign.states?.state_name || campaign.state_id}
              </p>
            )}
            </div>
            <div>
              <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">Submission ID</h4>
              <p className="mt-1 text-sm text-surface-900">{submission.artwork_submission_id}</p>
            </div>
            <div>
              <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">Profile ID</h4>
              <p className="mt-1 text-sm text-surface-900">{submission.profile_id}</p>
            </div>
            <div>
              <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">Review Details</h4>
              <p className="mt-1 text-sm text-surface-900">{reviewedBy}</p>
              <p className="mt-1 text-xs text-surface-500">
                {submission.reviewed_at ? new Date(submission.reviewed_at).toLocaleString() : 'Pending review'}
              </p>
            </div>
          </div>
        </div>

        <div className="mt-6">
          <h4 className="mb-3 text-xs font-medium uppercase tracking-wider text-surface-400">Required Artwork Photos</h4>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {photos.length > 0 ? photos.map(photo => (
              <a key={photo.artwork_submission_photo_id} href={photo.photo_url} target="_blank" rel="noreferrer" className="group">
                <div className="aspect-square overflow-hidden rounded-xl border border-surface-200 bg-surface-100">
                  <img src={photo.photo_url} alt={`${submission.artwork_title} – ${photoLabels[photo.view_type] || photo.view_type}`} className="h-full w-full object-cover transition-transform group-hover:scale-105" />
                </div>
                <p className="mt-2 text-sm font-medium text-surface-700 group-hover:text-primary-600">{photoLabels[photo.view_type] || photo.view_type}</p>
              </a>
            )) : (
              <div className="col-span-full rounded-lg border border-surface-200 bg-surface-50 p-6 text-center text-sm text-surface-500">
                No submission photos were returned.
              </div>
            )}
          </div>
        </div>

        <div className="mt-6 grid grid-cols-1 gap-6 md:grid-cols-2">
          <div className="space-y-6">
            <div>
              <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">Design Description</h4>
              <p className="mt-2 text-sm text-surface-700 whitespace-pre-wrap bg-white p-3 rounded-lg border border-surface-100">
                {submission.design_description || 'None provided.'}
              </p>
            </div>

            <div>
              <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">Cultural Inspiration</h4>
              <p className="mt-2 text-sm text-surface-700 whitespace-pre-wrap bg-white p-3 rounded-lg border border-surface-100">
                {submission.cultural_inspiration || 'None provided.'}
              </p>
            </div>

          </div>
          <div className="space-y-6">
            {[
              ['Layer 1 Meaning', submission.layer_1_meaning],
              ['Layer 2 Meaning', submission.layer_2_meaning],
              ['Layer 3 Meaning', submission.layer_3_meaning],
            ].map(([label, value]) => (
              <div key={label}>
              <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">{label}</h4>
              <p className="mt-2 text-sm text-surface-700 whitespace-pre-wrap bg-white p-3 rounded-lg border border-surface-100">
                {value || 'None provided.'}
              </p>
              </div>
            ))}
          </div>
        </div>

        {/* Action Buttons */}
        <div className="mt-8 flex justify-end gap-3 border-t border-surface-100 pt-4">
          <button
            onClick={onClose}
            className="rounded-lg px-4 py-2 text-sm font-medium text-surface-700 hover:bg-surface-100"
          >
            Close
          </button>
          
          {/* Action Placeholders */}
          {submission.review_status === 'pending' && (
            <>
              <button
                onClick={() => onReject(submission)}
                className="rounded-lg bg-red-100 px-4 py-2 text-sm font-medium text-red-700 hover:bg-red-200"
              >
                Reject
              </button>
              <button
                onClick={() => onApprove(submission)}
                className="rounded-lg bg-green-600 px-4 py-2 text-sm font-medium text-white hover:bg-green-700"
              >
                Approve
              </button>
            </>
          )}
          {submission.review_status === 'rejected' && (
            <button
              onClick={() => onApprove(submission)}
              className="rounded-lg bg-green-600 px-4 py-2 text-sm font-medium text-white hover:bg-green-700"
            >
              Approve
            </button>
          )}
        </div>
        
      </div>
    </Modal>
  );
}
