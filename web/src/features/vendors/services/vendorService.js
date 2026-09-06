import { supabase, queryRows, insertRows, updateRows, deleteRows } from '../../../services/supabase/api';
import { uploadVendorImage } from '../../../services/cloudinary/upload';
import { normalizeContactNumber } from './vendorContact';
import {
  firstVendorValidationMessage,
  normalizeOperatingHours,
  validateVendorInput,
} from './vendorValidation';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

async function getNextId(table, column, prefix) {
  const { data, error } = await supabase
    .from(table)
    .select(column)
    .order(column, { ascending: false })
    .limit(1);

  if (error) throw error;

  let nextNum = 1;
  if (data && data.length > 0 && data[0][column]) {
    const numPart = data[0][column].replace(prefix, '');
    nextNum = parseInt(numPart, 10) + 1;
  }
  
  return `${prefix}${String(nextNum).padStart(4, '0')}`;
}

function toRelationArray(relation) {
  if (!relation) return [];
  return Array.isArray(relation) ? relation : [relation];
}

async function assertVendorExists(vendorId) {
  if (!/^V[0-9]{4}$/.test(vendorId || '')) {
    throw new Error('A valid Vendor is required.');
  }
  const vendors = await queryRows(
    'vendors',
    'vendor_id, participation_status',
    query => query.eq('vendor_id', vendorId).limit(1),
  );
  if (!vendors[0]) throw new Error('The selected Vendor no longer exists.');
  return vendors[0];
}

async function assertVendorIdentityAvailable(formData, currentVendorId = null) {
  const vendorName = formData.vendor_name.trim();
  const addressLine = formData.address_line.trim();
  const duplicates = await queryRows(
    'vendors',
    'vendor_id',
    query => {
      const duplicateQuery = query
        .eq('vendor_name', vendorName)
        .eq('address_line', addressLine);
      return currentVendorId
        ? duplicateQuery.neq('vendor_id', currentVendorId).limit(1)
        : duplicateQuery.limit(1);
    },
  );
  if (duplicates.length > 0) {
    throw new Error('A Vendor with this name and address already exists.');
  }
}

// ---------------------------------------------------------------------------
// Service Exports
// ---------------------------------------------------------------------------

/**
 * Fetch all vendors with their nested relations.
 */
export async function fetchVendors() {
  const data = await queryRows(
    'vendors',
    `*, 
     states(state_name), 
     vendor_foods(vendor_food_id, heritage_food_id, is_featured, heritage_foods(heritage_food_id, food_name)),
     vendor_tiffins(vendor_tiffin_id, heritage_tiffin_id, heritage_tiffins(heritage_tiffin_id, edition_name)),
     vendor_operating_hours(*)`,
    q => q.order('created_at', { ascending: false })
  );
  
  return data.map(vendor => ({
    ...vendor,
    contact_number: normalizeContactNumber(vendor.contact_number),
    // The unique vendor_id constraint makes this a one-to-one relation in
    // PostgREST, so Supabase returns an object instead of an array. Keep the
    // UI-facing shape stable for the dashboard, details, and edit form.
    vendor_tiffins: toRelationArray(vendor.vendor_tiffins),
  }));
}

/**
 * Fetch all reference data needed for the Vendor Forms.
 */
export async function fetchReferenceData() {
  const [states, foods, categories, tiffins] = await Promise.all([
    queryRows('states', '*', q => q.eq('is_active', true).order('state_name')),
    queryRows('heritage_foods', '*', q => q.eq('is_active', true).order('food_name')),
    queryRows('food_categories', '*', q => q.eq('is_active', true).order('category_name')),
    queryRows('heritage_tiffins', '*', q => q.neq('status', 'inactive').order('edition_name'))
  ]);

  return { states, foods, categories, tiffins };
}

async function assertVendorSelectionsMatchState(formData) {
  const validationErrors = validateVendorInput(formData);
  if (Object.keys(validationErrors).length > 0) {
    throw new Error(firstVendorValidationMessage(validationErrors));
  }

  if (formData.selected_foods && !Array.isArray(formData.selected_foods)) {
    throw new Error('Heritage Food selections are invalid.');
  }
  if (formData.selected_tiffins && !Array.isArray(formData.selected_tiffins)) {
    throw new Error('Tiffin selections are invalid.');
  }

  const rawFoodIds = formData.selected_foods || [];
  const selectedFoodIds = [...new Set(rawFoodIds)];
  const rawTiffinIds = (formData.selected_tiffins || [])
    .map(tiffin => tiffin.heritage_tiffin_id);
  const selectedTiffinIds = [...new Set(rawTiffinIds)];

  if (selectedFoodIds.length !== rawFoodIds.length) {
    throw new Error('A Heritage Food cannot be selected more than once.');
  }
  if (selectedTiffinIds.length !== rawTiffinIds.length || selectedTiffinIds.length > 1) {
    throw new Error('A Vendor can be assigned to only one Tiffin edition.');
  }
  if (selectedFoodIds.some(foodId => !/^HF[0-9]{4}$/.test(foodId || ''))) {
    throw new Error('One or more Heritage Food selections are invalid.');
  }
  if (selectedTiffinIds.some(tiffinId => !/^HT[0-9]{4}$/.test(tiffinId || ''))) {
    throw new Error('The selected Tiffin edition is invalid.');
  }

  const [states, foods, tiffins] = await Promise.all([
    queryRows('states', 'state_id', query => (
      query.eq('state_id', formData.state_id).eq('is_active', true).limit(1)
    )),
    selectedFoodIds.length
      ? queryRows('heritage_foods', 'heritage_food_id, state_id', query => (
        query.in('heritage_food_id', selectedFoodIds).eq('is_active', true)
      ))
      : [],
    selectedTiffinIds.length
      ? queryRows('heritage_tiffins', 'heritage_tiffin_id, state_id', query => (
        query.in('heritage_tiffin_id', selectedTiffinIds).neq('status', 'inactive')
      ))
      : [],
  ]);

  if (!states[0]) {
    throw new Error('The selected Vendor state is no longer active.');
  }
  if (
    foods.length !== selectedFoodIds.length
    || foods.some(food => food.state_id !== formData.state_id)
  ) {
    throw new Error('Every selected Heritage Food must belong to the Vendor state.');
  }
  if (
    tiffins.length !== selectedTiffinIds.length
    || tiffins.some(tiffin => tiffin.state_id !== formData.state_id)
  ) {
    throw new Error('Every selected Tiffin must belong to the Vendor state.');
  }
}

/**
 * Create a new Vendor with its relations.
 */
export async function createVendor(formData) {
  await assertVendorSelectionsMatchState(formData);
  await assertVendorIdentityAvailable(formData);

  const normalizedHours = normalizeOperatingHours(formData.operating_hours);
  const imageResult = formData.cover_image_file
    ? await uploadVendorImage(formData.cover_image_file)
    : null;
  const vendorId = await getNextId('vendors', 'vendor_id', 'V');

  // 1. Insert Vendor
  const vendorPayload = {
    vendor_id: vendorId,
    vendor_name: formData.vendor_name.trim(),
    business_type: formData.business_type,
    description: formData.description?.trim() || null,
    contact_person: formData.contact_person?.trim() || null,
    contact_number: normalizeContactNumber(formData.contact_number) || null,
    email: formData.email?.trim() || null,
    address_line: formData.address_line.trim(),
    latitude: Number(formData.latitude),
    longitude: Number(formData.longitude),
    google_place_id: formData.google_place_id || null,
    cover_image_url: imageResult?.secure_url || formData.cover_image_url || null,
    state_id: formData.state_id,
    participation_status: formData.participation_status,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  };

  const [insertedVendor] = await insertRows('vendors', [vendorPayload]);

  // 2. Insert Operating Hours
  if (normalizedHours.length > 0) {
    // In a real high concurrency environment, getting next ID iteratively like this could collide. 
    // Usually UUIDs are better, but we are adhering to the exact schema VOH0000 format.
    // To prevent collision in this loop, we generate them sequentially or use a fixed counter.
    // Let's improve the ID generator for batch.
    const baseHourId = await getNextId('vendor_operating_hours', 'vendor_operating_hours_id', 'VOH');
    const baseHourNum = parseInt(baseHourId.replace('VOH', ''), 10);
    const safeHoursPayload = normalizedHours.map((oh, index) => ({
      vendor_operating_hours_id: `VOH${String(baseHourNum + index).padStart(4, '0')}`,
      vendor_id: vendorId,
      day_of_week: oh.day_of_week,
      opening_time: oh.is_closed ? null : oh.opening_time,
      closing_time: oh.is_closed ? null : oh.closing_time,
      is_closed: oh.is_closed
    }));
    await insertRows('vendor_operating_hours', safeHoursPayload);
  }

  // 3. Insert Foods
  if (formData.selected_foods && formData.selected_foods.length > 0) {
    const baseFoodId = await getNextId('vendor_foods', 'vendor_food_id', 'VF');
    const baseFoodNum = parseInt(baseFoodId.replace('VF', ''), 10);
    const foodsPayload = formData.selected_foods.map((foodId, index) => ({
      vendor_food_id: `VF${String(baseFoodNum + index).padStart(4, '0')}`,
      vendor_id: vendorId,
      heritage_food_id: foodId,
      is_featured: false
    }));
    await insertRows('vendor_foods', foodsPayload);
  }

  // 4. Insert Tiffins
  const selectedTiffin = formData.selected_tiffins?.[0];
  if (selectedTiffin) {
    const vendorTiffinId = await getNextId('vendor_tiffins', 'vendor_tiffin_id', 'VT');
    await insertRows('vendor_tiffins', [{
      vendor_tiffin_id: vendorTiffinId,
      vendor_id: vendorId,
      heritage_tiffin_id: selectedTiffin.heritage_tiffin_id
    }]);
  }

  return insertedVendor;
}

/**
 * Update an existing Vendor.
 */
export async function updateVendor(vendorId, formData) {
  await assertVendorExists(vendorId);
  await assertVendorSelectionsMatchState(formData);
  await assertVendorIdentityAvailable(formData, vendorId);

  const normalizedHours = normalizeOperatingHours(formData.operating_hours);
  const imageResult = formData.cover_image_file
    ? await uploadVendorImage(formData.cover_image_file)
    : null;
  // 1. Update Vendor Basic Info
  const vendorPayload = {
    vendor_name: formData.vendor_name.trim(),
    business_type: formData.business_type,
    description: formData.description?.trim() || null,
    contact_person: formData.contact_person?.trim() || null,
    contact_number: normalizeContactNumber(formData.contact_number) || null,
    email: formData.email?.trim() || null,
    address_line: formData.address_line.trim(),
    latitude: Number(formData.latitude),
    longitude: Number(formData.longitude),
    google_place_id: formData.google_place_id || null,
    cover_image_url: imageResult?.secure_url || formData.cover_image_url || null,
    state_id: formData.state_id,
    participation_status: formData.participation_status,
    updated_at: new Date().toISOString(),
  };

  const [updatedVendor] = await updateRows(
    'vendors', 
    vendorPayload, 
    q => q.eq('vendor_id', vendorId)
  );
  if (!updatedVendor) {
    throw new Error('The selected Vendor could not be updated. Refresh and try again.');
  }

  // For relations, the simplest approach for an admin panel is to delete all existing and re-insert,
  // OR update them one by one. Given we don't have cascade delete on everything or we might lose PKs,
  // we will perform deletion then insertion to keep it perfectly synced.

  // 2. Sync Operating Hours
  if (normalizedHours) {
    await deleteRows('vendor_operating_hours', q => q.eq('vendor_id', vendorId));
    const baseHourId = await getNextId('vendor_operating_hours', 'vendor_operating_hours_id', 'VOH');
    const baseHourNum = parseInt(baseHourId.replace('VOH', ''), 10);
    const safeHoursPayload = normalizedHours.map((oh, index) => ({
      vendor_operating_hours_id: `VOH${String(baseHourNum + index).padStart(4, '0')}`,
      vendor_id: vendorId,
      day_of_week: oh.day_of_week,
      opening_time: oh.is_closed ? null : oh.opening_time,
      closing_time: oh.is_closed ? null : oh.closing_time,
      is_closed: oh.is_closed
    }));
    if (safeHoursPayload.length > 0) {
      await insertRows('vendor_operating_hours', safeHoursPayload);
    }
  }

  // 3. Sync Foods
  if (formData.selected_foods) {
    await deleteRows('vendor_foods', q => q.eq('vendor_id', vendorId));
    const baseFoodId = await getNextId('vendor_foods', 'vendor_food_id', 'VF');
    const baseFoodNum = parseInt(baseFoodId.replace('VF', ''), 10);
    const foodsPayload = formData.selected_foods.map((foodId, index) => ({
      vendor_food_id: `VF${String(baseFoodNum + index).padStart(4, '0')}`,
      vendor_id: vendorId,
      heritage_food_id: foodId,
      is_featured: false
    }));
    if (foodsPayload.length > 0) {
      await insertRows('vendor_foods', foodsPayload);
    }
  }

  // 4. Sync Tiffins
  if (formData.selected_tiffins) {
    await deleteRows('vendor_tiffins', q => q.eq('vendor_id', vendorId));
    const selectedTiffin = formData.selected_tiffins[0];
    if (selectedTiffin) {
      const vendorTiffinId = await getNextId('vendor_tiffins', 'vendor_tiffin_id', 'VT');
      await insertRows('vendor_tiffins', [{
        vendor_tiffin_id: vendorTiffinId,
        vendor_id: vendorId,
        heritage_tiffin_id: selectedTiffin.heritage_tiffin_id
      }]);
    }
  }

  return updatedVendor;
}

/**
 * Deactivate a Vendor (Soft Delete)
 */
export async function deactivateVendor(vendorId) {
  const vendor = await assertVendorExists(vendorId);
  if (vendor.participation_status === 'inactive') {
    throw new Error('This Vendor is already inactive.');
  }

  const [updatedVendor] = await updateRows(
    'vendors',
    { participation_status: 'inactive', updated_at: new Date().toISOString() },
    q => q.eq('vendor_id', vendorId)
  );
  if (!updatedVendor) {
    throw new Error('The selected Vendor could not be deactivated. Refresh and try again.');
  }
  return updatedVendor;
}
