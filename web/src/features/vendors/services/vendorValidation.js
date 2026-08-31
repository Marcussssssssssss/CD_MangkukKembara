import {
  CONTACT_NUMBER_ERROR,
  isValidContactNumber,
} from './vendorContact.js';
import { hasValidVendorLocation } from './vendorLocation.js';

export const VENDOR_BUSINESS_TYPES = new Set([
  'restaurant',
  'cafe',
  'food_stall',
  'night_market_stall',
]);

export const VENDOR_PARTICIPATION_STATUSES = new Set([
  'pending',
  'active',
  'inactive',
]);

const TIME_PATTERN = /^(?:[01]\d|2[0-3]):[0-5]\d(?::[0-5]\d)?$/;
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function normalizeOperatingTime(value) {
  const time = typeof value === 'string' ? value.trim() : '';
  if (!TIME_PATTERN.test(time)) return null;
  return time.length === 5 ? `${time}:00` : time;
}

export function validateOperatingHours(hours, participationStatus = 'active') {
  const hourErrors = {};
  if (!Array.isArray(hours)) {
    return { _form: 'Operating hours are required.' };
  }

  if (hours.length !== 7) {
    hourErrors._form = 'Set operating hours for all seven days.';
  }

  const seenDays = new Set();
  let declaredOpenDays = 0;

  hours.forEach((hoursForDay) => {
    const day = Number(hoursForDay?.day_of_week);
    if (!Number.isInteger(day) || day < 0 || day > 6) {
      hourErrors._form = 'Operating hours contain an invalid day.';
      return;
    }
    if (seenDays.has(day)) {
      hourErrors[day] = 'Only one operating-hours entry is allowed for this day.';
      return;
    }
    seenDays.add(day);

    if (typeof hoursForDay.is_closed !== 'boolean') {
      hourErrors[day] = 'Choose whether the vendor is open or closed.';
      return;
    }
    if (hoursForDay.is_closed) return;

    declaredOpenDays += 1;
    const openingTime = normalizeOperatingTime(hoursForDay.opening_time);
    const closingTime = normalizeOperatingTime(hoursForDay.closing_time);
    if (!openingTime || !closingTime) {
      hourErrors[day] = 'Enter a valid opening and closing time.';
    } else if (openingTime === closingTime) {
      hourErrors[day] = 'Opening and closing times must be different.';
    }
  });

  if (participationStatus === 'active' && declaredOpenDays === 0) {
    hourErrors._form = 'An active vendor must be open on at least one day.';
  }

  return hourErrors;
}

export function normalizeOperatingHours(hours) {
  return [...hours]
    .sort((left, right) => left.day_of_week - right.day_of_week)
    .map((hoursForDay) => ({
      ...hoursForDay,
      day_of_week: Number(hoursForDay.day_of_week),
      opening_time: hoursForDay.is_closed
        ? null
        : normalizeOperatingTime(hoursForDay.opening_time),
      closing_time: hoursForDay.is_closed
        ? null
        : normalizeOperatingTime(hoursForDay.closing_time),
      is_closed: Boolean(hoursForDay.is_closed),
    }));
}

export function validateVendorInput(formData) {
  const errors = {};
  const vendorName = formData?.vendor_name?.trim() || '';
  const contactPerson = formData?.contact_person?.trim() || '';
  const email = formData?.email?.trim() || '';

  if (!vendorName) {
    errors.vendor_name = 'Vendor name is required.';
  } else if (vendorName.length > 150) {
    errors.vendor_name = 'Vendor name must not exceed 150 characters.';
  }

  if (!VENDOR_BUSINESS_TYPES.has(formData?.business_type)) {
    errors.business_type = 'Select a valid business type.';
  }
  if (!VENDOR_PARTICIPATION_STATUSES.has(formData?.participation_status)) {
    errors.participation_status = 'Select a valid participation status.';
  }
  if (contactPerson.length > 100) {
    errors.contact_person = 'Contact person must not exceed 100 characters.';
  }
  if (!isValidContactNumber(formData?.contact_number)) {
    errors.contact_number = CONTACT_NUMBER_ERROR;
  }
  if (email && (email.length > 150 || !EMAIL_PATTERN.test(email))) {
    errors.email = 'Enter a valid email address of no more than 150 characters.';
  }
  if (!/^S[0-9]{4}$/.test(formData?.state_id || '')) {
    errors.state_id = 'Select a valid state.';
  }
  if (!hasValidVendorLocation(formData)) {
    errors.location = 'Search for and confirm the vendor location before saving.';
  }

  const operatingHoursErrors = validateOperatingHours(
    formData?.operating_hours,
    formData?.participation_status,
  );
  if (Object.keys(operatingHoursErrors).length > 0) {
    errors.operating_hours = operatingHoursErrors;
  }

  return errors;
}

export function firstVendorValidationMessage(errors) {
  const fieldOrder = [
    'vendor_name',
    'business_type',
    'participation_status',
    'contact_person',
    'contact_number',
    'email',
    'location',
    'state_id',
  ];
  for (const field of fieldOrder) {
    if (errors[field]) return errors[field];
  }

  const operatingHoursErrors = errors.operating_hours;
  if (operatingHoursErrors?._form) return operatingHoursErrors._form;
  if (operatingHoursErrors) {
    const firstDayError = Object.values(operatingHoursErrors).find(Boolean);
    if (firstDayError) return firstDayError;
  }
  return 'Review the highlighted Vendor information.';
}
