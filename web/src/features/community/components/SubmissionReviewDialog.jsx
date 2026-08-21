import Modal from '../../../components/Modal';

export default function SubmissionReviewDialog({ submission, action, isOpen, isProcessing, onClose, onConfirm }) {
  if (!submission || !action) return null;

  const isApprove = action === 'approve';
  const actionLabel = isApprove ? 'Approve' : 'Reject';
  const accentClasses = isApprove
    ? 'bg-green-100 text-green-600'
    : 'bg-red-100 text-red-600';
  const buttonClasses = isApprove
    ? 'bg-green-600 hover:bg-green-700 focus-visible:outline-green-600'
    : 'bg-red-600 hover:bg-red-700 focus-visible:outline-red-600';

  return (
    <Modal open={isOpen} onClose={isProcessing ? () => {} : onClose} title={`${actionLabel} Submission`} size="confirm">
      <div className="p-6">
        <div className={`mx-auto flex h-12 w-12 items-center justify-center rounded-full ${accentClasses}`}>
          {isApprove ? (
            <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor" aria-hidden="true">
              <path strokeLinecap="round" strokeLinejoin="round" d="m4.5 12.75 6 6 9-13.5" />
            </svg>
          ) : (
            <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor" aria-hidden="true">
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3.75m9.303 3.376c.866 1.5-.217 3.374-1.948 3.374H4.645c-1.73 0-2.813-1.874-1.948-3.374L10.052 3.38c.866-1.5 3.03-1.5 3.896 0l7.355 12.746ZM12 16.5h.008v.008H12V16.5Z" />
            </svg>
          )}
        </div>

        <div className="mt-4 text-center">
          <h3 className="text-base font-semibold text-surface-900">
            {isApprove ? 'Approve this artwork?' : 'Reject this artwork?'}
          </h3>
          <p className="mt-2 text-sm text-surface-500">
            You are about to {action} <span className="font-medium text-surface-900">{submission.artwork_title}</span>.
            {isApprove
              ? ' It will be marked as approved.'
              : ' It will be marked as rejected and can be approved later if needed.'}
          </p>
        </div>

        <div className="mt-6 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
          <button
            type="button"
            onClick={onClose}
            disabled={isProcessing}
            className="inline-flex w-full justify-center rounded-lg bg-white px-3 py-2 text-sm font-semibold text-surface-900 shadow-sm ring-1 ring-inset ring-surface-300 hover:bg-surface-50 disabled:cursor-not-allowed disabled:opacity-60 sm:w-auto"
          >
            Cancel
          </button>
          <button
            type="button"
            onClick={onConfirm}
            disabled={isProcessing}
            className={`inline-flex w-full items-center justify-center gap-2 rounded-lg px-3 py-2 text-sm font-semibold text-white shadow-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 disabled:cursor-not-allowed disabled:opacity-60 sm:w-auto ${buttonClasses}`}
          >
            {isProcessing && (
              <span className="h-4 w-4 animate-spin rounded-full border-2 border-white/40 border-t-white" aria-hidden="true" />
            )}
            {isProcessing ? (isApprove ? 'Approving...' : 'Rejecting...') : `${actionLabel} Submission`}
          </button>
        </div>
      </div>
    </Modal>
  );
}
