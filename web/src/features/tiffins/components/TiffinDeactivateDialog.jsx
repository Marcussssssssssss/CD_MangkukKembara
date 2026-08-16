import Modal from '../../../components/Modal';

export default function TiffinDeactivateDialog({ tiffin, isOpen, onClose, onConfirm }) {
  if (!tiffin) return null;

  return (
    <Modal open={isOpen} onClose={onClose} title="Deactivate Tiffin Edition" size="sm">
      <div className="p-6">
        <p className="text-surface-600">
          Are you sure you want to deactivate <span className="font-semibold text-surface-900">{tiffin.edition_name}</span>?
        </p>
        <p className="mt-2 text-sm text-surface-500">
          This will hide the edition from the public facing application. You can re-activate it later by editing its status.
        </p>

        <div className="mt-8 flex justify-end gap-3">
          <button
            onClick={onClose}
            className="rounded-lg px-4 py-2 text-sm font-medium text-surface-700 hover:bg-surface-100"
          >
            Cancel
          </button>
          <button
            onClick={() => onConfirm(tiffin.heritage_tiffin_id)}
            className="rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700"
          >
            Deactivate
          </button>
        </div>
      </div>
    </Modal>
  );
}
