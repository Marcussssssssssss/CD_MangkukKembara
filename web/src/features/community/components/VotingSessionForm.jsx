import { useState } from 'react';
import Modal from '../../../components/Modal';

const emptyFormData = () => ({
  campaign_id: '',
  voting_start_at: '',
  voting_end_at: ''
});

export default function VotingSessionForm({
  isOpen,
  onClose,
  onSave,
  campaigns,
  submissions
}) {
  const [formData, setFormData] = useState(emptyFormData);
  
  const [selectedSubmissionIds, setSelectedSubmissionIds] = useState([]);
  const [errors, setErrors] = useState({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Filter out non-approved submissions and only keep ones for the selected campaign
  const availableSubmissions = submissions.filter(
    s => s.review_status === 'approved' &&
    s.artwork_campaign_id === formData.campaign_id
  );

  const resetForm = () => {
    setFormData(emptyFormData());
    setSelectedSubmissionIds([]);
    setErrors({});
  };

  const handleClose = () => {
    resetForm();
    onClose();
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    
    // If campaign changes, reset selected submissions
    if (name === 'campaign_id') {
      setSelectedSubmissionIds([]);
    }
    
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: null }));
    }
  };

  const toggleSubmission = (subId) => {
    setSelectedSubmissionIds(prev => 
      prev.includes(subId) ? prev.filter(id => id !== subId) : [...prev, subId]
    );
    if (errors.submissions) {
      setErrors(prev => ({ ...prev, submissions: null }));
    }
  };

  const toggleAllSubmissions = () => {
    if (selectedSubmissionIds.length === availableSubmissions.length) {
      setSelectedSubmissionIds([]);
    } else {
      setSelectedSubmissionIds(availableSubmissions.map(s => s.artwork_submission_id));
    }
    if (errors.submissions) {
      setErrors(prev => ({ ...prev, submissions: null }));
    }
  };

  const validate = () => {
    const newErrors = {};
    if (!formData.campaign_id) newErrors.campaign_id = 'Campaign is required.';
    if (!formData.voting_start_at) newErrors.voting_start_at = 'Voting Start is required.';
    if (!formData.voting_end_at) newErrors.voting_end_at = 'Voting End is required.';
    
    if (formData.voting_start_at && formData.voting_end_at) {
      if (new Date(formData.voting_end_at) <= new Date(formData.voting_start_at)) {
        newErrors.voting_end_at = 'Voting End must be later than Voting Start.';
      }
    }

    if (selectedSubmissionIds.length === 0) {
      newErrors.submissions = 'You must select at least one approved submission.';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!validate()) return;

    const selectedSubsData = availableSubmissions.filter(s => selectedSubmissionIds.includes(s.artwork_submission_id));

    setIsSubmitting(true);
    try {
      await onSave(formData, selectedSubsData);
      resetForm();
    } catch (err) {
      setErrors({ form: err.message || 'Failed to create voting session.' });
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Modal open={isOpen} onClose={handleClose} title="Create Standard Voting Session" size="3xl">
      <form onSubmit={handleSubmit} className="flex flex-col h-full max-h-[85vh]">
        <div className="flex-1 overflow-y-auto p-6">
          {errors.form && (
            <div className="mb-6 rounded-lg bg-red-50 p-4 text-sm text-red-700 border border-red-200">
              {errors.form}
            </div>
          )}

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
            {/* Campaign Selection */}
            <div className="md:col-span-2">
              <label htmlFor="campaign_id" className="block text-sm font-medium text-surface-700">
                Campaign <span className="text-red-500">*</span>
              </label>
              <select
                id="campaign_id"
                name="campaign_id"
                value={formData.campaign_id}
                onChange={handleChange}
                className={`mt-1 block w-full rounded-lg border p-2.5 text-sm ${
                  errors.campaign_id ? 'border-red-300 focus:border-red-500 focus:ring-red-500' : 'border-surface-300 focus:border-primary-500 focus:ring-primary-500'
                }`}
              >
                <option value="">Select a campaign...</option>
                {campaigns.map(c => (
                  <option key={c.artwork_campaign_id} value={c.artwork_campaign_id}>
                    {c.campaign_title} (ID: {c.artwork_campaign_id})
                  </option>
                ))}
              </select>
              {errors.campaign_id && <p className="mt-1 text-sm text-red-600">{errors.campaign_id}</p>}
            </div>

            {/* Voting Start */}
            <div>
              <label htmlFor="voting_start_at" className="block text-sm font-medium text-surface-700">
                Voting Start Date & Time <span className="text-red-500">*</span>
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

            {/* Voting End */}
            <div>
              <label htmlFor="voting_end_at" className="block text-sm font-medium text-surface-700">
                Voting End Date & Time <span className="text-red-500">*</span>
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

          {/* Submissions Selection Area */}
          {formData.campaign_id && (
            <div className="border-t border-surface-200 pt-6">
              <div className="flex items-center justify-between mb-4">
                <div>
                  <h4 className="text-base font-semibold text-surface-900">Eligible Submissions</h4>
                  <p className="text-sm text-surface-500">Select approved submissions to include in this voting session.</p>
                </div>
                {availableSubmissions.length > 0 && (
                  <button
                    type="button"
                    onClick={toggleAllSubmissions}
                    className="text-sm font-medium text-primary-600 hover:text-primary-700"
                  >
                    {selectedSubmissionIds.length === availableSubmissions.length ? 'Deselect All' : 'Select All'}
                  </button>
                )}
              </div>

              {errors.submissions && <p className="mb-4 text-sm font-medium text-red-600 bg-red-50 p-3 rounded-lg">{errors.submissions}</p>}

              {availableSubmissions.length > 0 ? (
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  {availableSubmissions.map(sub => {
                    const isSelected = selectedSubmissionIds.includes(sub.artwork_submission_id);
                    return (
                      <div
                        key={sub.artwork_submission_id}
                        onClick={() => toggleSubmission(sub.artwork_submission_id)}
                        className={`flex items-start gap-4 p-4 rounded-xl border cursor-pointer transition-all ${
                          isSelected 
                            ? 'border-primary-500 bg-primary-50 ring-1 ring-primary-500' 
                            : 'border-surface-200 bg-white hover:border-primary-300'
                        }`}
                      >
                        <div className="flex h-5 items-center mt-0.5">
                          <input
                            type="checkbox"
                            readOnly
                            checked={isSelected}
                            className="h-4 w-4 rounded border-surface-300 text-primary-600 focus:ring-primary-600"
                          />
                        </div>
                        <div className="h-16 w-16 shrink-0 overflow-hidden rounded bg-surface-100 border border-surface-200">
                          {sub.artwork_file_url ? (
                            <img src={sub.artwork_file_url} alt="" className="h-full w-full object-cover" />
                          ) : (
                            <span className="flex h-full items-center justify-center text-[10px] text-surface-400">No Img</span>
                          )}
                        </div>
                        <div className="min-w-0 flex-1">
                          <p className="text-sm font-medium text-surface-900 truncate">{sub.artwork_title}</p>
                          <p className="text-xs text-surface-500 truncate mt-0.5">by {sub.profiles?.display_name || sub.profile_id}</p>
                        </div>
                      </div>
                    );
                  })}
                </div>
              ) : (
                <div className="rounded-lg border border-surface-200 border-dashed p-8 text-center bg-surface-50">
                  <p className="text-sm text-surface-500">No approved submissions found for this campaign.</p>
                </div>
              )}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="shrink-0 flex items-center justify-end gap-3 border-t border-surface-200 p-6 bg-surface-50">
          <button
            type="button"
            onClick={handleClose}
            disabled={isSubmitting}
            className="rounded-lg px-4 py-2.5 text-sm font-medium text-surface-700 hover:bg-surface-200 disabled:opacity-50"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={isSubmitting}
            className="inline-flex items-center justify-center rounded-lg bg-primary-600 px-6 py-2.5 text-sm font-medium text-white hover:bg-primary-700 disabled:opacity-50 min-w-[120px]"
          >
            {isSubmitting ? (
              <div className="h-5 w-5 animate-spin rounded-full border-2 border-white border-t-transparent" />
            ) : (
              'Create Session'
            )}
          </button>
        </div>
      </form>
    </Modal>
  );
}
