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
          <div>
            <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">Campaign</h4>
            <p className="mt-1 text-sm font-medium text-surface-900">{campaignTitle}</p>
            {(campaign?.states?.state_name || campaign?.state_id) && (
              <p className="mt-1 text-xs text-surface-500">
                State: {campaign.states?.state_name || campaign.state_id}
              </p>
            )}
          </div>
        </div>

        <div className="mt-6 grid grid-cols-1 md:grid-cols-2 gap-8">
          
          {/* Left Column: Image */}
          <div>
            <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400 mb-3">Artwork Preview</h4>
            <div className="rounded-xl overflow-hidden border border-surface-200 bg-surface-100 aspect-square flex items-center justify-center">
              {submission.artwork_file_url ? (
                <img 
                  src={submission.artwork_file_url} 
                  alt={submission.artwork_title}
                  className="w-full h-full object-cover"
                />
              ) : (
                <span className="text-surface-400 text-sm">No artwork provided</span>
              )}
            </div>
            {submission.artwork_file_url && (
              <a 
                href={submission.artwork_file_url} 
                target="_blank" 
                rel="noreferrer"
                className="mt-2 inline-flex items-center gap-1 text-sm font-medium text-primary-600 hover:text-primary-700"
              >
                <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 6H5.25A2.25 2.25 0 003 8.25v10.5A2.25 2.25 0 005.25 21h10.5A2.25 2.25 0 0018 18.75V10.5m-10.5 6L21 3m0 0h-5.25M21 3v5.25" />
                </svg>
                Open Original Image
              </a>
            )}
          </div>

          {/* Right Column: Descriptions */}
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

            <div>
              <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">Artist Statement</h4>
              <p className="mt-2 text-sm text-surface-700 whitespace-pre-wrap bg-white p-3 rounded-lg border border-surface-100">
                {submission.artist_statement || 'None provided.'}
              </p>
            </div>
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
        </div>
        
      </div>
    </Modal>
  );
}
