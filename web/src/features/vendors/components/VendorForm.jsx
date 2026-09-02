import { useCallback, useEffect, useRef, useState } from 'react';
import Modal from '../../../components/Modal';
import EditSaveConfirmation from '../../../components/EditSaveConfirmation';
import {
  ALLOWED_IMAGE_TYPES,
  SIZE_LIMITS,
} from '../../../services/cloudinary/upload';
import VendorLocationPicker from './VendorLocationPicker';
import {
  CONTACT_NUMBER_PLACEHOLDER,
  normalizeContactNumber,
} from '../services/vendorContact';
import {
  validateOperatingHours,
  validateVendorInput,
} from '../services/vendorValidation';

const DEFAULT_HOURS = Array.from({ length: 7 }, (_, i) => ({
  day_of_week: i,
  opening_time: '10:00:00',
  closing_time: '22:00:00',
  is_closed: false
}));

const STATE_NAME_ALIASES = {
  pulaupinang: 'penang',
  malacca: 'melaka',
};

function normalizeStateName(value = '') {
  const normalized = value
    .toLowerCase()
    .replace(/wilayah persekutuan|federal territory of|federal territory|state/g, '')
    .replace(/[^a-z]/g, '');

  return STATE_NAME_ALIASES[normalized] || normalized;
}

function initialFormData(vendor) {
  return {
    vendor_id: vendor?.vendor_id,
    vendor_name: vendor?.vendor_name || '',
    business_type: vendor?.business_type || 'restaurant',
    description: vendor?.description || '',
    contact_person: vendor?.contact_person || '',
    contact_number: normalizeContactNumber(vendor?.contact_number),
    email: vendor?.email || '',
    address_line: vendor?.address_line || '',
    latitude: vendor?.latitude ?? '',
    longitude: vendor?.longitude ?? '',
    google_place_id: vendor?.google_place_id || null,
    cover_image_url: vendor?.cover_image_url || null,
    state_id: vendor?.state_id || '',
    participation_status: vendor?.participation_status || 'active',
  };
}

function initialHours(vendor) {
  if (!vendor) return DEFAULT_HOURS.map(hours => ({ ...hours }));

  const existingHours = vendor.vendor_operating_hours || [];
  return DEFAULT_HOURS.map(defaultDay => {
    const existing = existingHours.find(
      hours => Number(hours.day_of_week) === defaultDay.day_of_week
    );
    return existing
      ? { ...existing }
      : { ...defaultDay, is_closed: true };
  });
}

export default function VendorForm(props) {
  if (!props.isOpen || !props.referenceData) return null;
  const formKey = props.vendor?.vendor_id || 'new-vendor';
  return <VendorFormContent key={formKey} {...props} />;
}

function VendorFormContent({ vendor, isOpen, onClose, onSave, referenceData }) {
  const [formData, setFormData] = useState(() => initialFormData(vendor));
  const selectedStateId = useRef(formData.state_id);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isConfirmingSave, setIsConfirmingSave] = useState(false);
  const [errors, setErrors] = useState({});
  const [coverImageFile, setCoverImageFile] = useState(null);
  const [coverImagePreview, setCoverImagePreview] = useState(
    () => vendor?.cover_image_url || ''
  );
  const coverImageInputRef = useRef(null);
  const coverImageObjectUrl = useRef(null);
  const formRef = useRef(null);

  // Complex relation state
  const [selectedFoods, setSelectedFoods] = useState(
    () => (vendor?.vendor_foods || [])
      .map(vf => vf.heritage_food_id || vf.heritage_foods?.heritage_food_id)
      .filter(Boolean)
  );
  const [selectedTiffins, setSelectedTiffins] = useState(
    () => vendor?.vendor_tiffins?.[0]
      ? [{
          heritage_tiffin_id: vendor.vendor_tiffins[0].heritage_tiffin_id
            || vendor.vendor_tiffins[0].heritage_tiffins?.heritage_tiffin_id,
        }].filter(tiffin => Boolean(tiffin.heritage_tiffin_id))
      : []
  );
  const [operatingHours, setOperatingHours] = useState(() => initialHours(vendor));

  useEffect(() => () => {
    if (coverImageObjectUrl.current) {
      URL.revokeObjectURL(coverImageObjectUrl.current);
    }
  }, []);

  const foodsForState = referenceData.foods.filter(
    food => food.state_id === formData.state_id
  );
  const tiffinsForState = referenceData.tiffins.filter(
    tiffin => tiffin.state_id === formData.state_id
  );

  const handleChange = (e) => {
    const { name, value } = e.target;
    if (name === 'state_id') {
      selectedStateId.current = value;
      setSelectedFoods([]);
      setSelectedTiffins([]);
    }
    setFormData(prev => ({ ...prev, [name]: value }));
    if (errors[name] || (name === 'participation_status' && errors.operating_hours)) {
      setErrors(prev => ({
        ...prev,
        [name]: null,
        ...(name === 'participation_status' ? { operating_hours: null } : {}),
      }));
    }
  };

  const handleLocationChange = useCallback((location) => {
    setFormData(prev => ({ ...prev, ...location }));
    setErrors(prev => ({ ...prev, location: null }));
  }, []);

  const handleLocationStateDetected = useCallback((detectedStateName) => {
    const normalizedDetectedState = normalizeStateName(detectedStateName);
    const matchedState = referenceData.states.find(
      state => normalizeStateName(state.state_name) === normalizedDetectedState
    );

    if (!matchedState) {
      setErrors(prev => ({
        ...prev,
        state_id: 'The location state could not be matched automatically. Select the correct state.',
      }));
      return;
    }

    if (selectedStateId.current !== matchedState.state_id) {
      selectedStateId.current = matchedState.state_id;
      setSelectedFoods([]);
      setSelectedTiffins([]);
    }

    setFormData(prev => ({ ...prev, state_id: matchedState.state_id }));
    setErrors(prev => ({ ...prev, state_id: null }));
  }, [referenceData.states]);

  const handleFoodToggle = (foodId) => {
    setSelectedFoods(prev => 
      prev.includes(foodId) ? prev.filter(id => id !== foodId) : [...prev, foodId]
    );
  };

  const handleTiffinSelect = (tiffinId) => {
    setSelectedTiffins(
      tiffinId ? [{ heritage_tiffin_id: tiffinId }] : []
    );
  };

  const handleCoverImageChange = (event) => {
    const file = event.target.files?.[0] || null;
    if (!file) return;

    if (!ALLOWED_IMAGE_TYPES.has(file.type || '')) {
      setErrors(prev => ({ ...prev, cover_image: 'Choose a JPG, PNG, or WebP image.' }));
      event.target.value = '';
      return;
    }
    if (file.size > SIZE_LIMITS.image) {
      setErrors(prev => ({ ...prev, cover_image: 'The image must not exceed 10 MB.' }));
      event.target.value = '';
      return;
    }

    if (coverImageObjectUrl.current) {
      URL.revokeObjectURL(coverImageObjectUrl.current);
    }
    const previewUrl = URL.createObjectURL(file);
    coverImageObjectUrl.current = previewUrl;
    setCoverImageFile(file);
    setCoverImagePreview(previewUrl);
    setErrors(prev => ({ ...prev, cover_image: null }));
  };

  const handleContactNumberBlur = () => {
    setFormData(prev => ({
      ...prev,
      contact_number: normalizeContactNumber(prev.contact_number),
    }));
  };

  const handleRemoveCoverImage = () => {
    if (coverImageObjectUrl.current) {
      URL.revokeObjectURL(coverImageObjectUrl.current);
      coverImageObjectUrl.current = null;
    }
    if (coverImageInputRef.current) coverImageInputRef.current.value = '';
    setCoverImageFile(null);
    setCoverImagePreview('');
    setFormData(prev => ({ ...prev, cover_image_url: null }));
    setErrors(prev => ({ ...prev, cover_image: null }));
  };

  const handleHourChange = (dayOfWeek, field, value) => {
    setOperatingHours(prev => 
      prev.map(oh => oh.day_of_week === dayOfWeek ? { ...oh, [field]: value } : oh)
    );
    setErrors(prev => {
      if (!prev.operating_hours) return prev;
      const nextOperatingHoursErrors = { ...prev.operating_hours };
      delete nextOperatingHoursErrors[dayOfWeek];
      delete nextOperatingHoursErrors._form;
      return {
        ...prev,
        operating_hours: Object.keys(nextOperatingHoursErrors).length > 0
          ? nextOperatingHoursErrors
          : null,
      };
    });
  };

  const handleHourBlur = (dayOfWeek) => {
    const nextValidation = validateOperatingHours(
      operatingHours,
      formData.participation_status,
    );
    setErrors(prev => {
      const nextOperatingHoursErrors = { ...(prev.operating_hours || {}) };
      if (nextValidation[dayOfWeek]) {
        nextOperatingHoursErrors[dayOfWeek] = nextValidation[dayOfWeek];
      } else {
        delete nextOperatingHoursErrors[dayOfWeek];
      }
      if (nextValidation._form) {
        nextOperatingHoursErrors._form = nextValidation._form;
      } else {
        delete nextOperatingHoursErrors._form;
      }
      return {
        ...prev,
        operating_hours: Object.keys(nextOperatingHoursErrors).length > 0
          ? nextOperatingHoursErrors
          : null,
      };
    });
  };

  const validate = () => {
    return validateVendorInput({
      ...formData,
      operating_hours: operatingHours,
    });
  };

  const validateBeforeSave = () => {
    const validationErrors = validate();
    if (Object.keys(validationErrors).length > 0) {
      setErrors(validationErrors);
      requestAnimationFrame(() => {
        const firstInvalid = formRef.current?.querySelector(
          '[aria-invalid="true"], [data-validation-error="true"]'
        );
        firstInvalid?.scrollIntoView({ behavior: 'smooth', block: 'center' });
        firstInvalid?.focus?.({ preventScroll: true });
      });
      return false;
    }

    return true;
  };

  const saveVendor = async () => {
    setIsConfirmingSave(false);

    setIsSubmitting(true);
    setErrors({});

    // Construct final payload matching the shape expected by service
    const finalData = {
      ...formData,
      operating_hours: operatingHours,
      selected_foods: selectedFoods,
      selected_tiffins: selectedTiffins,
      cover_image_file: coverImageFile,
    };

    try {
      await onSave(finalData);
    } catch (err) {
      setErrors({ submit: err.message || 'An error occurred while saving.' });
      setIsSubmitting(false); // only re-enable on error, otherwise modal closes
    }
  };

  const handleSaveRequest = () => {
    if (!validateBeforeSave()) return;

    if (vendor) {
      setIsConfirmingSave(true);
      return;
    }

    saveVendor();
  };

  const DAYS = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  return (
    <>
      <Modal
        open={isOpen}
        onClose={isSubmitting || isConfirmingSave ? undefined : onClose}
        title={vendor ? 'Edit Heritage Vendor' : 'Add New Heritage Vendor'}
        size="xl"
        closeOnBackdrop={false}
      >
        <form
          ref={formRef}
          onSubmit={event => event.preventDefault()}
          className="flex min-h-0 flex-1 flex-col"
          noValidate
        >
        <div className="min-h-0 flex-1 overflow-y-auto p-6">
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
                  <label htmlFor="vendor_name" className="block text-sm font-medium text-surface-900">
                    Vendor Name <span className="text-red-500" aria-hidden="true">*</span>
                  </label>
                  <input
                    type="text"
                    id="vendor_name"
                    name="vendor_name"
                    value={formData.vendor_name}
                    onChange={handleChange}
                    maxLength={150}
                    aria-invalid={Boolean(errors.vendor_name)}
                    aria-describedby={errors.vendor_name ? 'vendor-name-error' : undefined}
                    className={`mt-2 block w-full rounded-lg border ${errors.vendor_name ? 'border-red-500' : 'border-surface-300'} px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500`}
                  />
                  {errors.vendor_name && <p id="vendor-name-error" className="mt-1 text-xs text-red-600" role="alert">{errors.vendor_name}</p>}
                </div>

                <div>
                  <label htmlFor="business_type" className="block text-sm font-medium text-surface-900">
                    Business Type <span className="text-red-500" aria-hidden="true">*</span>
                  </label>
                  <select
                    id="business_type"
                    name="business_type"
                    value={formData.business_type}
                    onChange={handleChange}
                    aria-invalid={Boolean(errors.business_type)}
                    aria-describedby={errors.business_type ? 'vendor-business-type-error' : undefined}
                    className={`mt-2 block w-full rounded-lg border ${errors.business_type ? 'border-red-500' : 'border-surface-300'} px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500`}
                  >
                    <option value="restaurant">Restaurant</option>
                    <option value="cafe">Cafe</option>
                    <option value="food_stall">Food Stall</option>
                    <option value="night_market_stall">Night Market Stall</option>
                  </select>
                  {errors.business_type && (
                    <p id="vendor-business-type-error" className="mt-1 text-xs text-red-600" role="alert">
                      {errors.business_type}
                    </p>
                  )}
                </div>

                <div>
                  <label htmlFor="participation_status" className="block text-sm font-medium text-surface-900">
                    Participation Status <span className="text-red-500" aria-hidden="true">*</span>
                  </label>
                  <select
                    id="participation_status"
                    name="participation_status"
                    value={formData.participation_status}
                    onChange={handleChange}
                    aria-invalid={Boolean(errors.participation_status)}
                    aria-describedby={errors.participation_status ? 'vendor-participation-status-error' : undefined}
                    className={`mt-2 block w-full rounded-lg border ${errors.participation_status ? 'border-red-500' : 'border-surface-300'} px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500`}
                  >
                    <option value="active">Active</option>
                    <option value="pending">Pending</option>
                    <option value="inactive">Inactive</option>
                  </select>
                  {errors.participation_status && (
                    <p id="vendor-participation-status-error" className="mt-1 text-xs text-red-600" role="alert">
                      {errors.participation_status}
                    </p>
                  )}
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

                <div className="sm:col-span-2">
                  <div className="flex items-baseline justify-between gap-3">
                    <label htmlFor="vendor_cover_image" className="block text-sm font-medium text-surface-900">
                      Vendor Image
                    </label>
                    <span className="text-xs text-surface-500">Optional</span>
                  </div>

                  <div className="mt-2 grid gap-4 rounded-xl border border-surface-200 bg-surface-50 p-4 sm:grid-cols-[12rem_minmax(0,1fr)] sm:items-center">
                    <div className="aspect-[4/3] overflow-hidden rounded-lg border border-surface-200 bg-white">
                      {coverImagePreview ? (
                        <img
                          src={coverImagePreview}
                          alt="Vendor image preview"
                          className="h-full w-full object-cover"
                        />
                      ) : (
                        <div className="flex h-full flex-col items-center justify-center gap-2 text-surface-400">
                          <svg className="h-8 w-8" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" aria-hidden="true">
                            <rect x="3" y="4" width="18" height="16" rx="2" />
                            <circle cx="9" cy="10" r="2" />
                            <path d="m4 17 4-4 3 3 3-4 6 6" strokeLinecap="round" strokeLinejoin="round" />
                          </svg>
                          <span className="text-xs font-medium">No image selected</span>
                        </div>
                      )}
                    </div>

                    <div>
                      <input
                        ref={coverImageInputRef}
                        id="vendor_cover_image"
                        type="file"
                        accept="image/jpeg,image/png,image/webp"
                        onChange={handleCoverImageChange}
                        disabled={isSubmitting}
                        className="sr-only"
                        aria-describedby="vendor-cover-image-help"
                      />
                      <div className="flex flex-wrap gap-2">
                        <button
                          type="button"
                          onClick={() => coverImageInputRef.current?.click()}
                          disabled={isSubmitting}
                          className="rounded-lg border border-primary-300 bg-white px-3 py-2 text-sm font-semibold text-primary-700 hover:bg-primary-50 disabled:cursor-not-allowed disabled:opacity-50"
                        >
                          {coverImagePreview ? 'Replace image' : 'Choose image'}
                        </button>
                        {coverImagePreview && (
                          <button
                            type="button"
                            onClick={handleRemoveCoverImage}
                            disabled={isSubmitting}
                            className="rounded-lg px-3 py-2 text-sm font-medium text-red-600 hover:bg-red-50 disabled:cursor-not-allowed disabled:opacity-50"
                          >
                            Remove
                          </button>
                        )}
                      </div>
                      <p id="vendor-cover-image-help" className="mt-2 text-xs leading-5 text-surface-500">
                        JPG, PNG, or WebP; maximum 10 MB. A landscape storefront or food-stall photo works best.
                      </p>
                      {coverImageFile && (
                        <p className="mt-1 truncate text-xs font-medium text-surface-700">{coverImageFile.name}</p>
                      )}
                      {errors.cover_image && (
                        <p className="mt-1 text-xs font-medium text-red-600" role="alert">{errors.cover_image}</p>
                      )}
                    </div>
                  </div>
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
                    maxLength={100}
                    aria-invalid={Boolean(errors.contact_person)}
                    aria-describedby={errors.contact_person ? 'vendor-contact-person-error' : undefined}
                    className={`mt-2 block w-full rounded-lg border ${errors.contact_person ? 'border-red-500' : 'border-surface-300'} px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500`}
                  />
                  {errors.contact_person && <p id="vendor-contact-person-error" className="mt-1 text-xs text-red-600" role="alert">{errors.contact_person}</p>}
                </div>
                <div>
                  <label htmlFor="contact_number" className="block text-sm font-medium text-surface-900">Contact Number</label>
                  <input
                    type="tel"
                    id="contact_number"
                    name="contact_number"
                    value={formData.contact_number}
                    onChange={handleChange}
                    onBlur={handleContactNumberBlur}
                    inputMode="tel"
                    autoComplete="tel"
                    maxLength={13}
                    placeholder={CONTACT_NUMBER_PLACEHOLDER}
                    aria-invalid={Boolean(errors.contact_number)}
                    aria-describedby={errors.contact_number ? 'vendor-contact-number-error' : 'vendor-contact-number-help'}
                    className={`mt-2 block w-full rounded-lg border ${errors.contact_number ? 'border-red-500' : 'border-surface-300'} px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500`}
                  />
                  {errors.contact_number ? (
                    <p id="vendor-contact-number-error" className="mt-1 text-xs font-medium text-red-600" role="alert">
                      {errors.contact_number}
                    </p>
                  ) : (
                    <p id="vendor-contact-number-help" className="mt-1 text-xs text-surface-500">
                      Use +60 followed by 8 to 10 digits, without spaces or hyphens.
                    </p>
                  )}
                </div>
                <div className="sm:col-span-2">
                  <label htmlFor="email" className="block text-sm font-medium text-surface-900">Email Address</label>
                  <input
                    type="email"
                    id="email"
                    name="email"
                    value={formData.email}
                    onChange={handleChange}
                    maxLength={150}
                    aria-invalid={Boolean(errors.email)}
                    aria-describedby={errors.email ? 'vendor-email-error' : undefined}
                    className={`mt-2 block w-full rounded-lg border ${errors.email ? 'border-red-500' : 'border-surface-300'} px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500`}
                  />
                  {errors.email && <p id="vendor-email-error" className="mt-1 text-xs text-red-600" role="alert">{errors.email}</p>}
                </div>

                <div className="sm:col-span-2">
                  <VendorLocationPicker
                    value={formData}
                    error={errors.location}
                    disabled={isSubmitting}
                    onChange={handleLocationChange}
                    onStateDetected={handleLocationStateDetected}
                  />
                </div>

                <div className="sm:col-span-2 sm:max-w-md">
                  <label htmlFor="state_id" className="block text-sm font-medium text-surface-900">
                    State <span className="text-red-500" aria-hidden="true">*</span>
                  </label>
                  <select
                    id="state_id"
                    name="state_id"
                    value={formData.state_id}
                    onChange={handleChange}
                    aria-invalid={Boolean(errors.state_id)}
                    aria-describedby={errors.state_id ? 'vendor-state-error' : 'vendor-state-help'}
                    className={`mt-2 block w-full rounded-lg border ${errors.state_id ? 'border-red-500' : 'border-surface-300'} px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500`}
                  >
                    <option value="" disabled>Select State...</option>
                    {referenceData?.states?.map((state) => (
                      <option key={state.state_id} value={state.state_id}>
                        {state.state_name}
                      </option>
                    ))}
                  </select>
                  {errors.state_id ? (
                    <p id="vendor-state-error" className="mt-1 text-xs font-medium text-red-600" role="alert">
                      {errors.state_id}
                    </p>
                  ) : (
                    <p id="vendor-state-help" className="mt-1 text-xs leading-5 text-surface-500">
                      Matched automatically from the selected location. Confirm it before saving.
                    </p>
                  )}
                </div>
              </div>
            </div>

            {/* Operating Hours */}
            <div>
              <h4 className="text-base font-semibold text-surface-900 border-b border-surface-200 pb-2 mb-4">Operating Hours</h4>
              <p className="mb-3 text-xs leading-5 text-surface-500">
                Opening and closing times must be different. A closing time earlier than the opening time is treated as the next day.
              </p>
              {errors.operating_hours?._form && (
                <p
                  className="mb-3 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-xs font-medium text-red-700"
                  role="alert"
                  tabIndex={-1}
                  data-validation-error="true"
                >
                  {errors.operating_hours._form}
                </p>
              )}
              <div className="space-y-3">
                {operatingHours.map((oh) => {
                  const dayError = errors.operating_hours?.[oh.day_of_week];
                  const errorId = `vendor-hours-${oh.day_of_week}-error`;
                  return (
                    <div key={oh.day_of_week}>
                      <div className={`flex flex-wrap items-center gap-4 rounded-lg border p-3 text-sm ${dayError ? 'border-red-300 bg-red-50/60' : 'border-surface-200 bg-surface-50'}`}>
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
                          <div className="flex min-w-64 flex-1 flex-wrap items-center gap-2">
                            <input
                              type="time"
                              step="1"
                              value={oh.opening_time || '00:00:00'}
                              onChange={(e) => handleHourChange(oh.day_of_week, 'opening_time', e.target.value)}
                              onBlur={() => handleHourBlur(oh.day_of_week)}
                              aria-label={`Opening time for ${DAYS[oh.day_of_week]}`}
                              aria-invalid={Boolean(dayError)}
                              aria-describedby={dayError ? errorId : undefined}
                              className={`rounded-lg border ${dayError ? 'border-red-500' : 'border-surface-300'} px-2 py-1 focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500`}
                            />
                            <span className="text-surface-500">to</span>
                            <input
                              type="time"
                              step="1"
                              value={oh.closing_time || '00:00:00'}
                              onChange={(e) => handleHourChange(oh.day_of_week, 'closing_time', e.target.value)}
                              onBlur={() => handleHourBlur(oh.day_of_week)}
                              aria-label={`Closing time for ${DAYS[oh.day_of_week]}`}
                              aria-invalid={Boolean(dayError)}
                              aria-describedby={dayError ? errorId : undefined}
                              className={`rounded-lg border ${dayError ? 'border-red-500' : 'border-surface-300'} px-2 py-1 focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500`}
                            />
                          </div>
                        )}
                      </div>
                      {dayError && (
                        <p id={errorId} className="mt-1 text-xs font-medium text-red-600" role="alert">
                          {DAYS[oh.day_of_week]}: {dayError}
                        </p>
                      )}
                    </div>
                  );
                })}
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
                  <p className="text-sm text-surface-500">
                    {formData.state_id
                      ? 'No active heritage food is configured for this state.'
                      : 'Confirm the vendor location first to see Heritage Foods for its state.'}
                  </p>
                )}
              </div>
            </div>

            {/* Tiffin Assignment */}
            <fieldset>
              <legend className="w-full border-b border-surface-200 pb-2 text-base font-semibold text-surface-900">
                Assigned Tiffin Edition
              </legend>
              <p className="mb-4 mt-2 text-sm text-surface-500">
                Select one edition for this vendor, or leave the vendor unassigned.
              </p>
              <div className="space-y-4">
                {tiffinsForState.length > 0 && (
                  <label className={`flex cursor-pointer items-start gap-3 rounded-lg border p-4 ${selectedTiffins.length === 0 ? 'border-primary-300 bg-primary-50/30' : 'border-surface-200 bg-surface-50 hover:bg-surface-100'}`}>
                    <input
                      type="radio"
                      name="assigned_tiffin"
                      checked={selectedTiffins.length === 0}
                      onChange={() => handleTiffinSelect('')}
                      className="mt-0.5 h-5 w-5 border-surface-300 text-primary-600 focus:ring-primary-500"
                    />
                    <span>
                      <span className="block text-sm font-semibold text-surface-900">No edition assigned</span>
                      <span className="mt-1 block text-xs text-surface-500">The vendor can be assigned an edition later.</span>
                    </span>
                  </label>
                )}
                {tiffinsForState.map((tiffin) => {
                  const isSelected = selectedTiffins.some(t => t.heritage_tiffin_id === tiffin.heritage_tiffin_id);
                  return (
                    <div key={tiffin.heritage_tiffin_id} className={`p-4 rounded-lg border ${isSelected ? 'border-primary-300 bg-primary-50/30' : 'border-surface-200 bg-surface-50'}`}>
                      <div className="flex items-center justify-between">
                        <label className="flex items-center gap-3 cursor-pointer">
                          <input 
                            type="radio"
                            name="assigned_tiffin"
                            checked={isSelected}
                            onChange={() => handleTiffinSelect(tiffin.heritage_tiffin_id)}
                            className="h-5 w-5 border-surface-300 text-primary-600 focus:ring-primary-500"
                          />
                          <span className="text-sm font-bold text-surface-900">{tiffin.edition_name}</span>
                        </label>
                      </div>
                    </div>
                  );
                })}
                {tiffinsForState.length === 0 && (
                  <p className="text-sm text-surface-500">
                    {formData.state_id
                      ? 'No active Tiffin edition is available for this state.'
                      : 'Confirm the vendor location first to see Tiffins available in its state.'}
                  </p>
                )}
              </div>
            </fieldset>

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
            type="button"
            onClick={handleSaveRequest}
            disabled={isSubmitting}
            className="flex items-center gap-2 rounded-lg bg-primary-600 px-6 py-2 text-sm font-medium text-white hover:bg-primary-700 disabled:opacity-50"
          >
            {isSubmitting && (
              <svg className="h-4 w-4 animate-spin text-white" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
              </svg>
            )}
            {isSubmitting ? 'Saving...' : vendor ? 'Save Changes' : 'Create Vendor'}
          </button>
        </div>
        </form>
      </Modal>
      <EditSaveConfirmation
        open={Boolean(vendor) && isConfirmingSave}
        entityName="Vendor"
        recordName={formData.vendor_name}
        isSaving={isSubmitting}
        onCancel={() => setIsConfirmingSave(false)}
        onConfirm={saveVendor}
      />
    </>
  );
}
