import { useState } from 'react';
import Modal from '../../../components/Modal';

const emptyFormData = () => ({
  voting_start_at: '',
  voting_end_at: ''
});

export default function TieBreakForm({
  isOpen,
  onClose,
  onSave,
  parentSessionId,
  campaignTitle
}) {
  const [formData, setFormData] = useState(emptyFormData);
  
  const [errors, setErrors] = useState({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const resetForm = () => {
    setFormData(emptyFormData());
    setErrors({});
  };

  const handleClose = () => {
    resetForm();
    onClose();
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: null }));
    }
  };

  const validate = () => {
    const newErrors = {};
    if (!formData.voting_start_at) newErrors.voting_start_at = 'Voting Start is required.';
    if (!formData.voting_end_at) newErrors.voting_end_at = 'Voting End is required.';
    
    if (formData.voting_start_at && formData.voting_end_at) {
      if (new Date(formData.voting_end_at) <= new Date(formData.voting_start_at)) {
        newErrors.voting_end_at = 'Voting End must be later than Voting Start.';
      }
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!validate()) return;
    
    if (!window.confirm(`Are you sure you want to create a tie-break session for "${campaignTitle}"?`)) {
      return;
    }

    setIsSubmitting(true);
    try {
      await onSave(parentSessionId, formData.voting_start_at, formData.voting_end_at);
      handleClose();
    } catch (err) {
      setErrors({ form: err.message || 'Failed to create tie-break session.' });
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Modal open={isOpen} onClose={handleClose} title="Create Tie-Break Session" size="md">
      <form onSubmit={handleSubmit} className="flex flex-col h-full max-h-[85vh]">
        <div className="flex-1 p-6">
          <p className="text-sm text-surface-600 mb-6">
            Creating a tie-break session for <span className="font-semibold text-surface-900">{campaignTitle}</span> from session <span className="font-mono text-surface-900">{parentSessionId}</span>. This will automatically include the tied artworks.
          </p>

          {errors.form && (
            <div className="mb-6 rounded-lg bg-red-50 p-4 text-sm text-red-700 border border-red-200">
              {errors.form}
            </div>
          )}

          <div className="space-y-4">
            <div>
              <label htmlFor="voting_start_at" className="block text-sm font-medium text-surface-700">
                New Voting Start Date & Time <span className="text-red-500">*</span>
              </label>
              <input
                type="datetime-local"
                id="voting_start_at"
                name="voting_start_at"
                value={formData.voting_start_at}
                onChange={handleChange}
                className={`mt-1 block w-full rounded-lg border p-2.5 text-sm ${
                  errors.voting_start_at ? 'border-red-300 focus:border-red-500 focus:ring-red-500' : 'border-surface-300 focus:border-primary-500 focus:ring-primary-500'
                }`}
              />
              {errors.voting_start_at && <p className="mt-1 text-sm text-red-600">{errors.voting_start_at}</p>}
            </div>

            <div>
              <label htmlFor="voting_end_at" className="block text-sm font-medium text-surface-700">
                New Voting End Date & Time <span className="text-red-500">*</span>
              </label>
              <input
                type="datetime-local"
                id="voting_end_at"
                name="voting_end_at"
                value={formData.voting_end_at}
                onChange={handleChange}
                className={`mt-1 block w-full rounded-lg border p-2.5 text-sm ${
                  errors.voting_end_at ? 'border-red-300 focus:border-red-500 focus:ring-red-500' : 'border-surface-300 focus:border-primary-500 focus:ring-primary-500'
                }`}
              />
              {errors.voting_end_at && <p className="mt-1 text-sm text-red-600">{errors.voting_end_at}</p>}
            </div>
          </div>
        </div>

        <div className="shrink-0 flex items-center justify-end gap-3 border-t border-surface-200 p-6 bg-surface-50">
          <button
            type="button"
            onClick={handleClose}
            disabled={isSubmitting}
            className="rounded-lg px-4 py-2 text-sm font-medium text-surface-700 hover:bg-surface-200 disabled:opacity-50"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={isSubmitting}
            className="inline-flex items-center justify-center rounded-lg bg-primary-600 px-6 py-2 text-sm font-medium text-white hover:bg-primary-700 disabled:opacity-50 min-w-[120px]"
          >
            {isSubmitting ? (
              <div className="h-5 w-5 animate-spin rounded-full border-2 border-white border-t-transparent" />
            ) : (
              'Create Tie-Break'
            )}
          </button>
        </div>
      </form>
    </Modal>
  );
}
