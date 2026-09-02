import Modal from './Modal';

export default function EditSaveConfirmation({
  open,
  entityName,
  recordName,
  isSaving,
  onCancel,
  onConfirm,
}) {
  return (
    <Modal
      open={open}
      onClose={isSaving ? undefined : onCancel}
      title={`Confirm ${entityName} Changes`}
      size="confirm"
      closeOnBackdrop={false}
    >
      <div className="p-6">
        <p className="text-sm leading-6 text-surface-600">
          Save the changes to{' '}
          <span className="font-semibold text-surface-900">{recordName}</span>?
          The existing record will only be updated after you confirm.
        </p>

        <div className="mt-6 flex justify-end gap-3 border-t border-surface-200 pt-4">
          <button
            type="button"
            onClick={onCancel}
            disabled={isSaving}
            className="rounded-lg px-4 py-2 text-sm font-medium text-surface-700 hover:bg-surface-100 disabled:opacity-50"
          >
            Continue Editing
          </button>
          <button
            type="button"
            onClick={onConfirm}
            disabled={isSaving}
            className="rounded-lg bg-primary-600 px-5 py-2 text-sm font-medium text-white hover:bg-primary-700 disabled:opacity-50"
          >
            {isSaving ? 'Saving…' : 'Confirm Changes'}
          </button>
        </div>
      </div>
    </Modal>
  );
}
