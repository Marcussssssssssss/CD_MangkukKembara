import Modal from '../../../components/Modal';

export default function CampaignDeactivateDialog({ campaign, isOpen, onClose, onConfirm }) {
  if (!campaign) return null;

  return (
    <Modal open={isOpen} onClose={onClose} title="Deactivate Campaign">
      <div className="p-6">
        <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-red-100">
          <svg className="h-6 w-6 text-red-600" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
        </div>
        
        <div className="mt-3 text-center sm:mt-5">
          <h3 className="text-base font-semibold leading-6 text-surface-900">
            Deactivate Campaign
          </h3>
          <div className="mt-2">
            <p className="text-sm text-surface-500">
              Are you sure you want to deactivate <span className="font-medium text-surface-900">{campaign.campaign_title}</span>? 
              This will prevent the campaign from continuing as an active campaign.
            </p>
          </div>
        </div>

        <div className="mt-6 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
          <button
            type="button"
            className="inline-flex w-full justify-center rounded-lg bg-white px-3 py-2 text-sm font-semibold text-surface-900 shadow-sm ring-1 ring-inset ring-surface-300 hover:bg-surface-50 sm:w-auto"
            onClick={onClose}
          >
            Cancel
          </button>
          <button
            type="button"
            className="inline-flex w-full justify-center rounded-lg bg-red-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-red-500 sm:w-auto"
            onClick={() => onConfirm(campaign)}
          >
            Deactivate
          </button>
        </div>
      </div>
    </Modal>
  );
}
