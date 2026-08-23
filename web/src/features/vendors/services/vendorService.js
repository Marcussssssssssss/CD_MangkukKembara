import { supabase, queryRows, insertRows, updateRows, deleteRows } from '../../../services/supabase/api';

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
     vendor_foods(heritage_foods(heritage_food_id, food_name)), 
     vendor_tiffins(heritage_tiffins(heritage_tiffin_id, edition_name)),
     vendor_operating_hours(*)`,
    q => q.order('created_at', { ascending: false })
  );
  
  return data;
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
  const vendorId = await getNextId('vendors', 'vendor_id', 'V');

  // 1. Insert Vendor
  const vendorPayload = {
    vendor_id: vendorId,
    vendor_name: formData.vendor_name,
    business_type: formData.business_type,
    description: formData.description,
    contact_person: formData.contact_person,
    contact_number: formData.contact_number,
    email: formData.email,
    address_line: formData.address_line,
    latitude: formData.latitude || 0,
    longitude: formData.longitude || 0,
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
  if (formData.selected_tiffins && formData.selected_tiffins.length > 0) {
    const baseTiffinId = await getNextId('vendor_tiffins', 'vendor_tiffin_id', 'VT');
    const baseTiffinNum = parseInt(baseTiffinId.replace('VT', ''), 10);
    const tiffinsPayload = formData.selected_tiffins.map((t, index) => ({
      vendor_tiffin_id: `VT${String(baseTiffinNum + index).padStart(4, '0')}`,
      vendor_id: vendorId,
      heritage_tiffin_id: t.heritage_tiffin_id
    }));
    await insertRows('vendor_tiffins', tiffinsPayload);
  }

  return insertedVendor;
}

/**
 * Update an existing Vendor.
 */
export async function updateVendor(vendorId, formData) {
  await assertVendorSelectionsMatchState(formData);
  // 1. Update Vendor Basic Info
  const vendorPayload = {
    vendor_name: formData.vendor_name,
    business_type: formData.business_type,
    description: formData.description,
    contact_person: formData.contact_person,
    contact_number: formData.contact_number,
    email: formData.email,
    address_line: formData.address_line,
    latitude: formData.latitude || 0,
    longitude: formData.longitude || 0,
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
    const baseTiffinId = await getNextId('vendor_tiffins', 'vendor_tiffin_id', 'VT');
    const baseTiffinNum = parseInt(baseTiffinId.replace('VT', ''), 10);
    const tiffinsPayload = formData.selected_tiffins.map((t, index) => ({
      vendor_tiffin_id: `VT${String(baseTiffinNum + index).padStart(4, '0')}`,
      vendor_id: vendorId,
      heritage_tiffin_id: t.heritage_tiffin_id
    }));
    if (tiffinsPayload.length > 0) {
      await insertRows('vendor_tiffins', tiffinsPayload);
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
