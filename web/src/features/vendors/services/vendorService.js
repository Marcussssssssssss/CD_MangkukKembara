import { supabase, queryRows, insertRows, updateRows, deleteRows } from '../../../services/supabase/api';
import { uploadVendorImage } from '../../../services/cloudinary/upload';
import {
  CONTACT_NUMBER_ERROR,
  isValidContactNumber,
  normalizeContactNumber,
} from './vendorContact';

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
  const [states, foods, tiffins] = await Promise.all([
    queryRows('states', '*', q => q.eq('is_active', true).order('state_name')),
    queryRows('heritage_foods', '*', q => q.eq('is_active', true).order('food_name')),
    queryRows('heritage_tiffins', '*', q => q.neq('status', 'inactive').order('edition_name'))
  ]);

  return { states, foods, tiffins };
}

async function assertVendorSelectionsMatchState(formData) {
  const selectedFoodIds = formData.selected_foods || [];
  const selectedTiffinIds = (formData.selected_tiffins || [])
    .map(tiffin => tiffin.heritage_tiffin_id);

  if (selectedTiffinIds.length > 1) {
    throw new Error('A Vendor can be assigned to only one Tiffin edition.');
  }
  if (!isValidContactNumber(formData.contact_number)) {
    throw new Error(CONTACT_NUMBER_ERROR);
  }

  const [foods, tiffins] = await Promise.all([
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
  const imageResult = formData.cover_image_file
    ? await uploadVendorImage(formData.cover_image_file)
    : null;
  const vendorId = await getNextId('vendors', 'vendor_id', 'V');

  // 1. Insert Vendor
  const vendorPayload = {
    vendor_id: vendorId,
    vendor_name: formData.vendor_name,
    business_type: formData.business_type,
    description: formData.description,
    contact_person: formData.contact_person,
    contact_number: normalizeContactNumber(formData.contact_number) || null,
    email: formData.email,
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
  if (formData.operating_hours && formData.operating_hours.length > 0) {
    // In a real high concurrency environment, getting next ID iteratively like this could collide. 
    // Usually UUIDs are better, but we are adhering to the exact schema VOH0000 format.
    // To prevent collision in this loop, we generate them sequentially or use a fixed counter.
    // Let's improve the ID generator for batch.
    const baseHourId = await getNextId('vendor_operating_hours', 'vendor_operating_hours_id', 'VOH');
    const baseHourNum = parseInt(baseHourId.replace('VOH', ''), 10);
    const safeHoursPayload = formData.operating_hours.map((oh, index) => ({
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
  await assertVendorSelectionsMatchState(formData);
  const imageResult = formData.cover_image_file
    ? await uploadVendorImage(formData.cover_image_file)
    : null;
  // 1. Update Vendor Basic Info
  const vendorPayload = {
    vendor_name: formData.vendor_name,
    business_type: formData.business_type,
    description: formData.description,
    contact_person: formData.contact_person,
    contact_number: normalizeContactNumber(formData.contact_number) || null,
    email: formData.email,
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

  // For relations, the simplest approach for an admin panel is to delete all existing and re-insert,
  // OR update them one by one. Given we don't have cascade delete on everything or we might lose PKs,
  // we will perform deletion then insertion to keep it perfectly synced.

  // 2. Sync Operating Hours
  if (formData.operating_hours) {
    await deleteRows('vendor_operating_hours', q => q.eq('vendor_id', vendorId));
    const baseHourId = await getNextId('vendor_operating_hours', 'vendor_operating_hours_id', 'VOH');
    const baseHourNum = parseInt(baseHourId.replace('VOH', ''), 10);
    const safeHoursPayload = formData.operating_hours.map((oh, index) => ({
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
  const [updatedVendor] = await updateRows(
    'vendors',
    { participation_status: 'inactive', updated_at: new Date().toISOString() },
    q => q.eq('vendor_id', vendorId)
  );
  return updatedVendor;
}
