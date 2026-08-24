import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function optionalText(value: unknown, maxLength: number) {
  const text = typeof value === 'string' ? value.trim() : '';
  if (!text) return null;
  if (text.length > maxLength) throw new Error(`Text must not exceed ${maxLength} characters.`);
  return text;
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (request.method !== 'POST') return json({ error: 'Method not allowed.' }, 405);

  try {
    const authorization = request.headers.get('Authorization');
    if (!authorization) return json({ error: 'Authentication is required.' }, 401);

    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    if (!supabaseUrl || !anonKey || !serviceRoleKey) {
      return json({ error: 'Supabase function environment is incomplete.' }, 500);
    }

    const authClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false },
    });
    const { data: authData, error: authError } = await authClient.auth.getUser();
    if (authError || !authData.user) return json({ error: 'Your session is invalid or expired.' }, 401);

    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });
    const { data: profile } = await adminClient
      .from('profiles')
      .select('role, is_active')
      .eq('auth_user_id', authData.user.id)
      .maybeSingle();
    if (profile?.role !== 'admin' || profile?.is_active !== true) {
      return json({ error: 'Administrator access is required.' }, 403);
    }

    const input = await request.json();
    const foodName = optionalText(input?.food_name, 150);
    const stateId = optionalText(input?.state_id, 5);
    const categoryId = optionalText(input?.food_category_id, 6);
    const originSummary = optionalText(input?.origin_summary, 5000);
    const culturalSignificance = optionalText(input?.cultural_significance, 5000);
    const imageUrl = optionalText(input?.image_url, 2000);

    if (!foodName) return json({ error: 'Food name is required.' }, 400);
    if (!stateId || !/^S[0-9]{4}$/.test(stateId)) return json({ error: 'A valid state is required.' }, 400);
    if (!categoryId || !/^FC[0-9]{4}$/.test(categoryId)) return json({ error: 'A valid category is required.' }, 400);
    if (imageUrl && !/^https:\/\//i.test(imageUrl)) return json({ error: 'The food image URL must use HTTPS.' }, 400);

    const [{ data: state }, { data: category }, { data: duplicate }] = await Promise.all([
      adminClient.from('states').select('state_id').eq('state_id', stateId).eq('is_active', true).maybeSingle(),
      adminClient.from('food_categories').select('food_category_id').eq('food_category_id', categoryId).eq('is_active', true).maybeSingle(),
      adminClient.from('heritage_foods').select('heritage_food_id').eq('state_id', stateId).ilike('food_name', foodName).limit(1).maybeSingle(),
    ]);
    if (!state) return json({ error: 'The selected state is no longer active.' }, 400);
    if (!category) return json({ error: 'The selected food category is no longer active.' }, 400);
    if (duplicate) return json({ error: 'A Heritage Food with this name already exists for the selected state.' }, 409);

    for (let attempt = 0; attempt < 3; attempt += 1) {
      const { data: latest } = await adminClient
        .from('heritage_foods')
        .select('heritage_food_id')
        .order('heritage_food_id', { ascending: false })
        .limit(1)
        .maybeSingle();
      const latestNumber = Number.parseInt(latest?.heritage_food_id?.slice(2) || '0', 10);
      const heritageFoodId = `HF${String(latestNumber + 1).padStart(4, '0')}`;

      const { data: created, error: insertError } = await adminClient
        .from('heritage_foods')
        .insert({
          heritage_food_id: heritageFoodId,
          food_category_id: categoryId,
          state_id: stateId,
          food_name: foodName,
          origin_summary: originSummary,
          cultural_significance: culturalSignificance,
          image_url: imageUrl,
          is_active: true,
        })
        .select('*')
        .single();

      if (!insertError) return json({ heritage_food: created }, 201);
      if (insertError.code !== '23505') {
        console.error('heritage food insert failed', insertError);
        return json({ error: 'The Heritage Food could not be created.' }, 500);
      }
    }

    return json({ error: 'The Heritage Food ID was allocated by another request. Please try again.' }, 409);
  } catch (error) {
    console.error('admin-create-heritage-food failed', error);
    return json({ error: error instanceof Error ? error.message : 'The Heritage Food could not be created.' }, 400);
  }
});
