import { useState } from 'react';
import Modal from '../../../components/Modal';

const DEFAULT_HOURS = Array.from({ length: 7 }, (_, i) => ({
  day_of_week: i,
  opening_time: '10:00:00',
  closing_time: '22:00:00',
  is_closed: false
}));

function initialFormData(vendor, referenceData) {
  return {
    vendor_id: vendor?.vendor_id,
    vendor_name: vendor?.vendor_name || '',
    business_type: vendor?.business_type || 'restaurant',
    description: vendor?.description || '',
    contact_person: vendor?.contact_person || '',
    contact_number: vendor?.contact_number || '',
    email: vendor?.email || '',
    address_line: vendor?.address_line || '',
    latitude: vendor?.latitude ?? 0,
    longitude: vendor?.longitude ?? 0,
    state_id: vendor?.state_id || referenceData?.states?.[0]?.state_id || '',
    participation_status: vendor?.participation_status || 'active',
  };
}

function initialHours(vendor) {
  if (!vendor?.vendor_operating_hours?.length) return DEFAULT_HOURS;
  return DEFAULT_HOURS.map(defaultDay => {
    const existing = vendor.vendor_operating_hours.find(
      hours => hours.day_of_week === defaultDay.day_of_week
    );
    return existing ? { ...existing } : defaultDay;
  });
}

export default function VendorForm(props) {
  if (!props.isOpen || !props.referenceData) return null;
  const formKey = props.vendor?.vendor_id || 'new-vendor';
  return <VendorFormContent key={formKey} {...props} />;
}

function VendorFormContent({ vendor, isOpen, onClose, onSave, referenceData }) {
  const [formData, setFormData] = useState(() => initialFormData(vendor, referenceData));
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errors, setErrors] = useState({});

  // Complex relation state
  const [selectedFoods, setSelectedFoods] = useState(
    () => vendor?.vendor_foods?.map(vf => vf.heritage_food_id) || []
  );
  const [selectedTiffins, setSelectedTiffins] = useState(
    () => (vendor?.vendor_tiffins || []).map(vt => ({
      heritage_tiffin_id: vt.heritage_tiffin_id,
    }))
  );
  const [operatingHours, setOperatingHours] = useState(() => initialHours(vendor));

  const foodsForState = referenceData.foods.filter(
    food => food.state_id === formData.state_id
  );
  const tiffinsForState = referenceData.tiffins.filter(
    tiffin => tiffin.state_id === formData.state_id
  );

  const handleChange = (e) => {
    const { name, value } = e.target;
    if (name === 'state_id') {
      setSelectedFoods([]);
      setSelectedTiffins([]);
    }
    setFormData(prev => ({ ...prev, [name]: value }));
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: null }));
    }
  };

  const handleFoodToggle = (foodId) => {
    setSelectedFoods(prev => 
      prev.includes(foodId) ? prev.filter(id => id !== foodId) : [...prev, foodId]
    );
  };

  const handleTiffinToggle = (tiffinId) => {
    setSelectedTiffins(prev => {
      if (prev.find(t => t.heritage_tiffin_id === tiffinId)) {
        return prev.filter(t => t.heritage_tiffin_id !== tiffinId);
      } else {
        return [...prev, { heritage_tiffin_id: tiffinId }];
      }
    });
  };

  const handleHourChange = (dayOfWeek, field, value) => {
    setOperatingHours(prev => 
      prev.map(oh => oh.day_of_week === dayOfWeek ? { ...oh, [field]: value } : oh)
    );
  };

  const validate = () => {
    const newErrors = {};
    if (!formData.vendor_name?.trim()) newErrors.vendor_name = 'Vendor Name is required.';
    if (!formData.business_type) newErrors.business_type = 'Business Type is required.';
    if (!formData.state_id) newErrors.state_id = 'State is required.';
    if (!formData.address_line?.trim()) newErrors.address_line = 'Address is required.';
    if (formData.latitude === '' || formData.latitude === null) newErrors.latitude = 'Latitude is required.';
    if (formData.longitude === '' || formData.longitude === null) newErrors.longitude = 'Longitude is required.';
    return newErrors;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    const validationErrors = validate();
    if (Object.keys(validationErrors).length > 0) {
      setErrors(validationErrors);
      return;
    }

    setIsSubmitting(true);
    setErrors({});

    // Construct final payload matching the shape expected by service
    const finalData = {
      ...formData,
      operating_hours: operatingHours,
      selected_foods: selectedFoods,
      selected_tiffins: selectedTiffins
    };

    try {
      await onSave(finalData);
    } catch (err) {
      setErrors({ submit: err.message || 'An error occurred while saving.' });
      setIsSubmitting(false); // only re-enable on error, otherwise modal closes
    }
  };

  const DAYS = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  return (
    <Modal 
      open={isOpen} 
      onClose={isSubmitting ? undefined : onClose} 
      title={vendor ? 'Edit Heritage Vendor' : 'Add New Heritage Vendor'} 
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
              <h4 className="text-base font-semibold text-surface-900 border-b border-surface-200 pb-2 mb-4">Basic Information</h4>
              <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
                <div className="sm:col-span-2">
                  <label htmlFor="vendor_name" className="block text-sm font-medium text-surface-900">Vendor Name</label>
                  <input
                    type="text"
                    id="vendor_name"
                    name="vendor_name"
                    value={formData.vendor_name}
                    onChange={handleChange}
                    className={`mt-2 block w-full rounded-lg border ${errors.vendor_name ? 'border-red-500' : 'border-surface-300'} px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500`}
                  />
                  {errors.vendor_name && <p className="mt-1 text-xs text-red-500">{errors.vendor_name}</p>}
                </div>

                <div>
                  <label htmlFor="business_type" className="block text-sm font-medium text-surface-900">Business Type</label>
                  <select
                    id="business_type"
                    name="business_type"
                    value={formData.business_type}
                    onChange={handleChange}
                    required
                    className="mt-2 block w-full rounded-lg border border-surface-300 px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
                  >
                    <option value="restaurant">Restaurant</option>
                    <option value="cafe">Cafe</option>
                    <option value="food_stall">Food Stall</option>
                    <option value="night_market_stall">Night Market Stall</option>
                  </select>
                </div>

                <div>
                  <label htmlFor="participation_status" className="block text-sm font-medium text-surface-900">Participation Status</label>
                  <select
                    id="participation_status"
                    name="participation_status"
                    value={formData.participation_status}
                    onChange={handleChange}
                    required
                    className="mt-2 block w-full rounded-lg border border-surface-300 px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
                  >
                    <option value="active">Active</option>
                    <option value="pending">Pending</option>
                    <option value="inactive">Inactive</option>
                  </select>
                </div>

                <div className="sm:col-span-2">
                  <label htmlFor="description" className="block text-sm font-medium text-surface-900">Description</label>
                  <textarea
                    id="description"
                    name="description"
                    rows={3}
                    value={formData.description}
                    onChange={handleChange}
                    className="mt-2 block w-full rounded-lg border border-surface-300 px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
                  />
                </div>
              </div>
            </div>

            {/* Contact Information */}
            <div>
              <h4 className="text-base font-semibold text-surface-900 border-b border-surface-200 pb-2 mb-4">Contact & Location</h4>
              <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
                <div>
                  <label htmlFor="contact_person" className="block text-sm font-medium text-surface-900">Contact Person</label>
                  <input
                    type="text"
                    id="contact_person"
                    name="contact_person"
                    value={formData.contact_person}
                    onChange={handleChange}
                    className="mt-2 block w-full rounded-lg border border-surface-300 px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
                  />
                </div>
                <div>
                  <label htmlFor="contact_number" className="block text-sm font-medium text-surface-900">Contact Number</label>
                  <input
                    type="text"
                    id="contact_number"
                    name="contact_number"
                    value={formData.contact_number}
                    onChange={handleChange}
                    className="mt-2 block w-full rounded-lg border border-surface-300 px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
                  />
                </div>
                <div className="sm:col-span-2">
                  <label htmlFor="email" className="block text-sm font-medium text-surface-900">Email Address</label>
                  <input
                    type="email"
                    id="email"
                    name="email"
                    value={formData.email}
                    onChange={handleChange}
                    className="mt-2 block w-full rounded-lg border border-surface-300 px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
                  />
                </div>

                <div>
                  <label htmlFor="state_id" className="block text-sm font-medium text-surface-900">State</label>
                  <select
                    id="state_id"
                    name="state_id"
                    value={formData.state_id}
                    onChange={handleChange}
                    className={`mt-2 block w-full rounded-lg border ${errors.state_id ? 'border-red-500' : 'border-surface-300'} px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500`}
                  >
                    <option value="" disabled>Select State...</option>
                    {referenceData?.states?.map((state) => (
                      <option key={state.state_id} value={state.state_id}>
                        {state.state_name}
                      </option>
                    ))}
                  </select>
                  {errors.state_id && <p className="mt-1 text-xs text-red-500">{errors.state_id}</p>}
                </div>
                
                <div className="sm:col-span-2">
                  <label htmlFor="address_line" className="block text-sm font-medium text-surface-900">Full Address</label>
                  <textarea
                    id="address_line"
                    name="address_line"
                    rows={2}
                    value={formData.address_line}
                    onChange={handleChange}
                    className={`mt-2 block w-full rounded-lg border ${errors.address_line ? 'border-red-500' : 'border-surface-300'} px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500`}
                  />
                  {errors.address_line && <p className="mt-1 text-xs text-red-500">{errors.address_line}</p>}
                </div>

                <div>
                  <label htmlFor="latitude" className="block text-sm font-medium text-surface-900">Latitude</label>
                  <input
                    type="number"
                    step="any"
                    id="latitude"
                    name="latitude"
                    value={formData.latitude}
                    onChange={handleChange}
                    className={`mt-2 block w-full rounded-lg border ${errors.latitude ? 'border-red-500' : 'border-surface-300'} px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500`}
                  />
                  {errors.latitude && <p className="mt-1 text-xs text-red-500">{errors.latitude}</p>}
                </div>
                <div>
                  <label htmlFor="longitude" className="block text-sm font-medium text-surface-900">Longitude</label>
                  <input
                    type="number"
                    step="any"
                    id="longitude"
                    name="longitude"
                    value={formData.longitude}
                    onChange={handleChange}
                    className={`mt-2 block w-full rounded-lg border ${errors.longitude ? 'border-red-500' : 'border-surface-300'} px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500`}
                  />
                  {errors.longitude && <p className="mt-1 text-xs text-red-500">{errors.longitude}</p>}
                </div>
              </div>
            </div>

            {/* Operating Hours */}
            <div>
              <h4 className="text-base font-semibold text-surface-900 border-b border-surface-200 pb-2 mb-4">Operating Hours</h4>
              <div className="space-y-3">
                {operatingHours.map((oh) => (
                  <div key={oh.day_of_week} className="flex items-center gap-4 text-sm">
                    <div className="w-24 font-medium text-surface-900">
                      {DAYS[oh.day_of_week]}
                    </div>
                    <label className="flex items-center gap-2">
                      <input 
                        type="checkbox" 
                        checked={oh.is_closed}
                        onChange={(e) => handleHourChange(oh.day_of_week, 'is_closed', e.target.checked)}
                        className="rounded border-surface-300 text-primary-600 focus:ring-primary-500"
                      />
                      <span>Closed</span>
                    </label>
                    
                    {!oh.is_closed && (
                      <div className="flex items-center gap-2 flex-1">
                        <input 
                          type="time" 
                          step="1"
                          value={oh.opening_time || '00:00:00'}
                          onChange={(e) => handleHourChange(oh.day_of_week, 'opening_time', e.target.value)}
                          className="rounded-lg border border-surface-300 px-2 py-1 focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
                        />
                        <span>to</span>
                        <input 
                          type="time" 
                          step="1"
                          value={oh.closing_time || '00:00:00'}
                          onChange={(e) => handleHourChange(oh.day_of_week, 'closing_time', e.target.value)}
                          className="rounded-lg border border-surface-300 px-2 py-1 focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
                        />
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </div>

            {/* Heritage Foods Selection */}
            <div>
              <h4 className="text-base font-semibold text-surface-900 border-b border-surface-200 pb-2 mb-4">Heritage Foods Associated</h4>
              <div className="flex flex-wrap gap-3">
                {foodsForState.map((food) => (
                  <label key={food.heritage_food_id} className="flex items-center gap-2 bg-surface-50 p-2 rounded-lg border border-surface-200 cursor-pointer hover:bg-surface-100">
                    <input 
                      type="checkbox" 
                      checked={selectedFoods.includes(food.heritage_food_id)}
                      onChange={() => handleFoodToggle(food.heritage_food_id)}
                      className="rounded border-surface-300 text-primary-600 focus:ring-primary-500"
                    />
                    <span className="text-sm font-medium">{food.food_name}</span>
                  </label>
                ))}
                {foodsForState.length === 0 && (
                  <p className="text-sm text-surface-500">No active heritage food is configured for this state.</p>
                )}
              </div>
            </div>

            {/* Tiffin Availability */}
            <div>
              <h4 className="text-base font-semibold text-surface-900 border-b border-surface-200 pb-2 mb-4">Available Tiffins</h4>
              <div className="space-y-4">
                {tiffinsForState.map((tiffin) => {
                  const isSelected = selectedTiffins.some(t => t.heritage_tiffin_id === tiffin.heritage_tiffin_id);
                  return (
                    <div key={tiffin.heritage_tiffin_id} className={`p-4 rounded-lg border ${isSelected ? 'border-primary-300 bg-primary-50/30' : 'border-surface-200 bg-surface-50'}`}>
                      <div className="flex items-center justify-between">
                        <label className="flex items-center gap-3 cursor-pointer">
                          <input 
                            type="checkbox" 
                            checked={isSelected}
                            onChange={() => handleTiffinToggle(tiffin.heritage_tiffin_id)}
                            className="w-5 h-5 rounded border-surface-300 text-primary-600 focus:ring-primary-500"
                          />
                          <span className="text-sm font-bold text-surface-900">{tiffin.edition_name}</span>
                        </label>
                      </div>
                    </div>
                  );
                })}
                {tiffinsForState.length === 0 && (
                  <p className="text-sm text-surface-500">No active Tiffin edition is available for this state.</p>
                )}
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
            {isSubmitting ? 'Saving...' : 'Save Vendor'}
          </button>
        </div>
      </form>
    </Modal>
  );
}
