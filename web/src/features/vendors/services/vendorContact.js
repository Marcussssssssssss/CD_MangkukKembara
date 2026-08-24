export const CONTACT_NUMBER_PLACEHOLDER = '+60123456789';
export const CONTACT_NUMBER_ERROR = 'Use Malaysian international format, for example +60123456789.';

const MALAYSIA_E164_PATTERN = /^\+60\d{8,10}$/;

export function normalizeContactNumber(value) {
  const rawValue = value?.trim() || '';
  if (!rawValue) return '';

  const digits = rawValue.replace(/\D/g, '');
  if (digits.startsWith('60')) return `+${digits}`;
  if (digits.startsWith('0')) return `+60${digits.slice(1)}`;
  return rawValue;
}

export function isValidContactNumber(value) {
  const contactNumber = normalizeContactNumber(value);
  return contactNumber === '' || MALAYSIA_E164_PATTERN.test(contactNumber);
}
