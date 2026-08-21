import { useState } from 'react';
import Modal from '../../../components/Modal';

const formatDateLocal = (dateStr) => {
  if (!dateStr) return '';
  const date = new Date(dateStr);
  if (Number.isNaN(date.getTime())) return '';
  const pad = (number) => String(number).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
};

const localToday = () => formatDateLocal(new Date());

const initialFormData = (campaign) => ({
  campaign_title: campaign?.campaign_title || '',
  state_id: campaign?.state_id || '',
  description: campaign?.description || '',
  submission_start_at: campaign ? formatDateLocal(campaign.submission_start_at) : localToday(),
  submission_end_at: formatDateLocal(campaign?.submission_end_at),
  status: campaign?.status || 'active',
});

export default function CampaignForm(props) {
  if (!props.isOpen) return null;

  const formKey = props.campaign?.artwork_campaign_id || 'new-campaign';
  return <CampaignFormContent key={formKey} {...props} />;
}

function CampaignFormContent({ campaign, isOpen, onClose, onSave, referenceData }) {
  const [formData, setFormData] = useState(() => initialFormData(campaign));
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errors, setErrors] = useState({});

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
    if (errors[name]) {
      setErrors((prev) => ({ ...prev, [name]: null }));
    }
  };



  const validate = () => {
    const newErrors = {};
    if (!formData.campaign_title?.trim()) newErrors.campaign_title = 'Campaign Title is required.';
    if (!formData.state_id) newErrors.state_id = 'State is required.';
    if (!formData.description?.trim()) newErrors.description = 'Description is required.';
    if (!formData.submission_start_at) newErrors.submission_start_at = 'Submission Start is required.';
    if (!formData.submission_end_at) newErrors.submission_end_at = 'Submission End is required.';
    if (!campaign && formData.submission_start_at < localToday()) {
      newErrors.submission_start_at = 'Submission Start cannot be before today.';
    }
    
    if (formData.submission_start_at && formData.submission_end_at) {
      if (new Date(formData.submission_end_at) <= new Date(formData.submission_start_at)) {
        newErrors.submission_end_at = 'Submission End must be after Submission Start.';
      }
    }



    return newErrors;
  };

  const availableStates = referenceData?.states || [];
  const campaignState = campaign?.states;
  const stateOptions = campaignState && !availableStates.some((state) => state.state_id === campaignState.state_id)
    ? [...availableStates, campaignState]
    : availableStates;

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    const validationErrors = validate();
    if (Object.keys(validationErrors).length > 0) {
      setErrors(validationErrors);
      return;
    }

    setIsSubmitting(true);
    setErrors({});

    try {
      await onSave(formData);
    } catch (err) {
      setErrors({ submit: err.message || 'An error occurred while saving.' });
      setIsSubmitting(false);
    }
  };

  return (
    <Modal 
      open={isOpen} 
      onClose={isSubmitting ? undefined : onClose} 
      title={campaign ? 'Edit Campaign' : 'Add New Campaign'} 
      size="xl"
    >
      <form onSubmit={handleSubmit} className="flex flex-col">
        <div className="p-6 overflow-y-auto max-h-[80vh]">
          {errors.submit && (
            <div className="mb-6 rounded-lg border border-red-500/20 bg-red-50 p-4 text-sm text-red-600">
              {errors.submit}
            </div>
          )}

          <div className="space-y-8">
            
            {/* Basic Information */}
            <div>
              <h4 className="text-base font-semibold text-surface-900 border-b border-surface-200 pb-2 mb-4">Campaign Details</h4>
              <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
                <div className="sm:col-span-2">
                  <label htmlFor="campaign_title" className="block text-sm font-medium text-surface-900">Campaign Title (Theme/Topic)</label>
                  <input
                    type="text"
                    id="campaign_title"
                    name="campaign_title"
                    value={formData.campaign_title || ''}
                    onChange={handleChange}
                    className={`mt-2 block w-full rounded-lg border ${errors.campaign_title ? 'border-red-500' : 'border-surface-300'} px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500`}
                  />
                  {errors.campaign_title && <p className="mt-1 text-xs text-red-500">{errors.campaign_title}</p>}
                </div>

                {!campaign && <div className="sm:col-span-2">
                  <label htmlFor="state_id" className="block text-sm font-medium text-surface-900">
                    State <span className="text-red-500">*</span>
                  </label>
                  <select
                    id="state_id"
                    name="state_id"
                    value={formData.state_id || ''}
                    onChange={handleChange}
                    disabled={!!campaign}
                    className={`mt-2 block w-full rounded-lg border ${errors.state_id ? 'border-red-500' : 'border-surface-300'} px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500 disabled:cursor-not-allowed disabled:bg-surface-100 disabled:text-surface-600`}
                  >
                    <option value="">Select a state</option>
                    {stateOptions.map((state) => (
                      <option key={state.state_id} value={state.state_id}>
                        {state.state_name}{state.state_code ? ` (${state.state_code})` : ''}
                      </option>
                    ))}
                  </select>
                  {errors.state_id && <p className="mt-1 text-xs text-red-500">{errors.state_id}</p>}
                </div>}

                <div className="sm:col-span-2">
                  <label htmlFor="description" className="block text-sm font-medium text-surface-900">Description</label>
                  <textarea
                    id="description"
                    name="description"
                    rows={3}
                    value={formData.description || ''}
                    onChange={handleChange}
                    className={`mt-2 block w-full rounded-lg border ${errors.description ? 'border-red-500' : 'border-surface-300'} px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500`}
                  />
                  {errors.description && <p className="mt-1 text-xs text-red-500">{errors.description}</p>}
                </div>

                {!campaign && <div>
                  <label htmlFor="submission_start_at" className="block text-sm font-medium text-surface-900">Submission Start Date</label>
                  <input
                    type="date"
                    id="submission_start_at"
                    name="submission_start_at"
                    value={formData.submission_start_at || ''}
                    onChange={handleChange}
                    min={localToday()}
                    className={`mt-2 block w-full rounded-lg border ${errors.submission_start_at ? 'border-red-500' : 'border-surface-300'} px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500`}
                  />
                  {errors.submission_start_at && <p className="mt-1 text-xs text-red-500">{errors.submission_start_at}</p>}
                  <p className="mt-1 text-xs text-surface-500">Select today or a future date.</p>
                </div>}
                
                <div className={campaign ? 'sm:col-span-2' : undefined}>
                  <label htmlFor="submission_end_at" className="block text-sm font-medium text-surface-900">Submission End Date</label>
                  <input
                    type="date"
                    id="submission_end_at"
                    name="submission_end_at"
                    value={formData.submission_end_at || ''}
                    onChange={handleChange}
                    min={formData.submission_start_at || undefined}
                    className={`mt-2 block w-full rounded-lg border ${errors.submission_end_at ? 'border-red-500' : 'border-surface-300'} px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500`}
                  />
                  {errors.submission_end_at && <p className="mt-1 text-xs text-red-500">{errors.submission_end_at}</p>}
                </div>

              </div>
            </div>



          </div>
        </div>

        <div className="flex items-center justify-end gap-3 border-t border-surface-200 bg-surface-50 p-4 shrink-0">
          <button
            type="button"
            onClick={onClose}
            disabled={isSubmitting}
            className="rounded-lg px-4 py-2 text-sm font-medium text-surface-700 hover:bg-surface-100 disabled:opacity-50"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={isSubmitting}
            className="flex items-center gap-2 rounded-lg bg-primary-600 px-6 py-2 text-sm font-medium text-white hover:bg-primary-700 disabled:opacity-50"
          >
            {isSubmitting && (
              <svg className="h-4 w-4 animate-spin text-white" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
              </svg>
            )}
            {isSubmitting ? 'Saving...' : (campaign ? 'Save Changes' : 'Create Campaign')}
          </button>
        </div>
      </form>
    </Modal>
  );
}
