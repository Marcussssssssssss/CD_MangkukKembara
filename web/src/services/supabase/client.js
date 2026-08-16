import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  console.warn(
    '[MangkukKembara] Supabase environment variables are not set.\n' +
      'Copy .env.example to .env.local and add your project credentials.'
  );
}

/**
 * Shared Supabase client singleton.
 *
 * Every module that needs Supabase should import from here rather than
 * calling createClient again. This ensures a single GoTrue session is
 * maintained across the entire application.
 *
 * When env vars are missing the client is created with a placeholder URL
 * so the application can still render (login will simply fail). The
 * console warning above tells the developer how to fix it.
 */
export const supabase = createClient(
  supabaseUrl || 'https://placeholder.supabase.co',
  supabaseAnonKey || 'placeholder-anon-key'
);
