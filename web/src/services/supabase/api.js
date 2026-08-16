import { supabase } from './client';

// ---------------------------------------------------------------------------
// Generic query helpers
// ---------------------------------------------------------------------------

/**
 * Run a Supabase SELECT and return the data array.
 *
 * Throws on error so callers can use try/catch or let the error propagate
 * to an error boundary.
 *
 * @template T
 * @param {string} table    — Table or view name.
 * @param {string} [select] — Column selection string (default '*').
 * @param {(query: import('@supabase/supabase-js').PostgrestFilterBuilder<any,any,any>) => import('@supabase/supabase-js').PostgrestFilterBuilder<any,any,any>} [filter]
 *   — Optional callback to chain .eq(), .order(), .limit(), etc.
 * @returns {Promise<T[]>}
 *
 * @example
 * const tiffins = await queryRows('heritage_tiffins', '*, heritage_foods(food_name)', q =>
 *   q.eq('status', 'active').order('created_at', { ascending: false })
 * );
 */
export async function queryRows(table, select = '*', filter) {
  let query = supabase.from(table).select(select);
  if (filter) query = filter(query);
  const { data, error } = await query;
  if (error) throw error;
  return data ?? [];
}

/**
 * Run a Supabase SELECT and return a single row.
 *
 * @template T
 * @param {string} table
 * @param {string} [select]
 * @param {(query: import('@supabase/supabase-js').PostgrestFilterBuilder<any,any,any>) => import('@supabase/supabase-js').PostgrestFilterBuilder<any,any,any>} filter
 * @returns {Promise<T | null>}
 */
export async function queryRow(table, select = '*', filter) {
  let query = supabase.from(table).select(select);
  if (filter) query = filter(query);
  const { data, error } = await query.maybeSingle();
  if (error) throw error;
  return data;
}

/**
 * Insert one or more rows and return the inserted data.
 *
 * @template T
 * @param {string} table
 * @param {T | T[]} rows
 * @returns {Promise<T[]>}
 */
export async function insertRows(table, rows) {
  const { data, error } = await supabase
    .from(table)
    .insert(rows)
    .select();
  if (error) throw error;
  return data ?? [];
}

/**
 * Update rows matching a filter and return the updated data.
 *
 * @template T
 * @param {string} table
 * @param {Partial<T>} values — Columns to update.
 * @param {(query: import('@supabase/supabase-js').PostgrestFilterBuilder<any,any,any>) => import('@supabase/supabase-js').PostgrestFilterBuilder<any,any,any>} filter
 * @returns {Promise<T[]>}
 */
export async function updateRows(table, values, filter) {
  let query = supabase.from(table).update(values);
  if (filter) query = filter(query);
  const { data, error } = await query.select();
  if (error) throw error;
  return data ?? [];
}

/**
 * Delete rows matching a filter.
 *
 * @param {string} table
 * @param {(query: import('@supabase/supabase-js').PostgrestFilterBuilder<any,any,any>) => import('@supabase/supabase-js').PostgrestFilterBuilder<any,any,any>} filter
 * @returns {Promise<void>}
 */
export async function deleteRows(table, filter) {
  let query = supabase.from(table).delete();
  if (filter) query = filter(query);
  const { error } = await query;
  if (error) throw error;
}

// ---------------------------------------------------------------------------
// Re-export the client for cases that need direct access
// ---------------------------------------------------------------------------

export { supabase };
