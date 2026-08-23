import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const imageTypes = new Set(['image/jpeg', 'image/png', 'image/webp']);
const videoTypes = new Set(['video/mp4', 'video/webm']);
const imageLimit = 10 * 1024 * 1024;
const profileImageLimit = 5 * 1024 * 1024;
const videoLimit = 50 * 1024 * 1024;

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

async function hexDigest(algorithm: AlgorithmIdentifier, value: BufferSource) {
  const digest = await crypto.subtle.digest(algorithm, value);
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}

function isApprovedFolder(folder: string, userId: string, isAdmin: boolean) {
  if (!/^[a-zA-Z0-9/_-]+$/.test(folder) || folder.includes('..')) return false;

  const authenticatedFolders = new Set([
    'profile_images',
    'artwork_submissions',
    'community_posts',
  ]);
  const adminFolders = new Set(['tiffin_designs', 'heritage_videos']);
  const userScopedPrefixes = [
    `mangkukkembara/community/${userId}`,
    `mangkukkembara/artwork-submissions/${userId}`,
    `mangkukkembara/profile/${userId}`,
  ];

  return authenticatedFolders.has(folder)
    || (isAdmin && adminFolders.has(folder))
    || userScopedPrefixes.some(
      (prefix) => folder === prefix || folder.startsWith(`${prefix}/`),
    );
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (request.method !== 'POST') return json({ error: 'Method not allowed.' }, 405);

  try {
    const authorization = request.headers.get('Authorization');
    if (!authorization) return json({ error: 'Authentication is required.' }, 401);

    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY');
    if (!supabaseUrl || !supabaseAnonKey) {
      return json({ error: 'Supabase function environment is incomplete.' }, 500);
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false },
    });
    const { data: authData, error: authError } = await supabase.auth.getUser();
    if (authError || !authData.user) {
      return json({ error: 'Your session is invalid or expired.' }, 401);
    }

    const { data: profile } = await supabase
      .from('profiles')
      .select('role, is_active')
      .eq('auth_user_id', authData.user.id)
      .maybeSingle();
    const isAdmin = profile?.role === 'admin' && profile?.is_active === true;

    const incoming = await request.formData();
    const file = incoming.get('file');
    const folder = incoming.get('folder')?.toString().trim() || '';
    const requestedMimeType = incoming.get('mime_type')?.toString() || '';
    if (!(file instanceof File) || file.size === 0) {
      return json({ error: 'No file was provided.' }, 400);
    }
    if (!isApprovedFolder(folder, authData.user.id, isAdmin)) {
      return json({ error: 'Upload folder is not allowed.' }, 403);
    }

    const mimeType = file.type || requestedMimeType;
    const isImage = imageTypes.has(mimeType);
    const isVideo = videoTypes.has(mimeType);
    if (!isImage && !isVideo) {
      return json({ error: 'Choose a JPG, PNG, WebP, MP4, or WebM file.' }, 415);
    }

    const maxBytes = isVideo
      ? videoLimit
      : folder === 'profile_images'
        ? profileImageLimit
        : imageLimit;
    if (file.size > maxBytes) {
      return json({
        error: `The selected file exceeds ${Math.round(maxBytes / 1024 / 1024)} MB.`,
      }, 413);
    }

    const cloudName = Deno.env.get('CLOUDINARY_CLOUD_NAME');
    const apiKey = Deno.env.get('CLOUDINARY_API_KEY');
    const apiSecret = Deno.env.get('CLOUDINARY_API_SECRET');
    if (!cloudName || !apiKey || !apiSecret) {
      return json({ error: 'Cloudinary credentials are not configured.' }, 500);
    }

    const timestamp = Math.floor(Date.now() / 1000).toString();
    const signatureSource = new TextEncoder().encode(
      `folder=${folder}&timestamp=${timestamp}${apiSecret}`,
    );
    const signature = await hexDigest('SHA-1', signatureSource);
    const fileBytes = await file.arrayBuffer();

    const cloudinaryForm = new FormData();
    cloudinaryForm.append('file', file, file.name);
    cloudinaryForm.append('api_key', apiKey);
    cloudinaryForm.append('timestamp', timestamp);
    cloudinaryForm.append('folder', folder);
    cloudinaryForm.append('signature', signature);

    const resourceType = isVideo ? 'video' : 'image';
    const uploadResponse = await fetch(
      `https://api.cloudinary.com/v1_1/${cloudName}/${resourceType}/upload`,
      { method: 'POST', body: cloudinaryForm },
    );
    const uploadResult = await uploadResponse.json();
    if (!uploadResponse.ok) {
      return json({
        error: uploadResult?.error?.message || 'Cloudinary rejected the upload.',
      }, 502);
    }

    return json({
      secure_url: uploadResult.secure_url,
      public_id: uploadResult.public_id,
      mime_type: mimeType,
      bytes: uploadResult.bytes ?? file.size,
      sha256: await hexDigest('SHA-256', fileBytes),
    });
  } catch (error) {
    console.error('cloudinary-upload failed', error);
    return json({ error: 'The media upload could not be completed.' }, 500);
  }
});
