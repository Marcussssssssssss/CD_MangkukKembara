import { supabase } from '../supabase/client';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const EDGE_FUNCTION_NAME = 'cloudinary-upload';

const ALLOWED_IMAGE_TYPES = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
]);

const ALLOWED_VIDEO_TYPES = new Set([
  'video/mp4',
  'video/webm',
]);

/** Default upload size limits (in bytes). */
const SIZE_LIMITS = {
  profileImage: 5 * 1024 * 1024,   // 5 MB — enforced by Edge Function
  image:       10 * 1024 * 1024,   // 10 MB
  video:       50 * 1024 * 1024,   // 50 MB
};

// ---------------------------------------------------------------------------
// Upload result type (mirrors the Edge Function response)
// ---------------------------------------------------------------------------

/**
 * @typedef {Object} CloudinaryUploadResult
 * @property {string} secure_url  — HTTPS delivery URL for the uploaded asset.
 * @property {string} public_id   — Cloudinary public ID.
 * @property {string} mime_type   — Detected MIME type.
 * @property {number} bytes       — File size in bytes.
 * @property {string} sha256      — Content hash.
 */

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Resolve a MIME type from a File object, falling back to the extension.
 *
 * @param {File} file
 * @returns {string}
 */
function resolveMimeType(file) {
  if (file.type) return file.type;

  const ext = file.name.split('.').pop()?.toLowerCase();
  switch (ext) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'mp4':
      return 'video/mp4';
    case 'webm':
      return 'video/webm';
    default:
      return 'application/octet-stream';
  }
}

// ---------------------------------------------------------------------------
// Core upload function
// ---------------------------------------------------------------------------

/**
 * Upload a file to Cloudinary through the authenticated Supabase Edge Function.
 *
 * ## Architecture
 *
 * ```
 * Browser (this function)
 *     ↓  multipart/form-data + Bearer JWT
 * Supabase Edge Function  (cloudinary-upload)
 *     ↓  signed upload (API secret stays server-side)
 * Cloudinary
 *     ↓  secure_url returned
 * Browser
 * ```
 *
 * No Cloudinary credentials are stored in or transmitted from the browser.
 * The Edge Function validates the user's Supabase session, restricts
 * folders and file types, signs the request, and returns the result.
 *
 * @param {File}   file                — A browser File object (from <input> or drag-and-drop).
 * @param {Object} options
 * @param {string} options.folder      — Cloudinary folder path (e.g. "tiffin_designs", "profile_images").
 * @param {number} [options.maxBytes]  — Client-side size limit. Defaults to SIZE_LIMITS.image (10 MB).
 * @returns {Promise<CloudinaryUploadResult>}
 */
export async function uploadMedia(file, { folder, maxBytes = SIZE_LIMITS.image } = {}) {
  // ── Client-side validations (fail fast before network request) ──

  if (!file || file.size === 0) {
    throw new Error('No file selected or the file is empty.');
  }

  if (file.size > maxBytes) {
    const limitMB = (maxBytes / 1024 / 1024).toFixed(0);
    throw new Error(`File exceeds the ${limitMB} MB size limit.`);
  }

  const mimeType = resolveMimeType(file);

  const isImage = ALLOWED_IMAGE_TYPES.has(mimeType);
  const isVideo = ALLOWED_VIDEO_TYPES.has(mimeType);

  if (!isImage && !isVideo) {
    throw new Error(
      'Unsupported file type. Choose a JPG, PNG, WebP image or MP4, WebM video.'
    );
  }

  if (!folder) {
    throw new Error('A Cloudinary folder is required.');
  }

  // ── Build the multipart form ──

  const formData = new FormData();
  formData.append('file', file, file.name);
  formData.append('folder', folder);
  formData.append('mime_type', mimeType);

  // ── Call the Edge Function ──
  // supabase.functions.invoke automatically attaches the Authorization header
  // with the current session JWT.

  const { data, error } = await supabase.functions.invoke(EDGE_FUNCTION_NAME, {
    body: formData,
  });

  if (error) {
    throw new Error(error.message || 'Media upload failed.');
  }

  // The Edge Function returns { secure_url, public_id, mime_type, bytes, sha256 }
  return /** @type {CloudinaryUploadResult} */ (data);
}

// ---------------------------------------------------------------------------
// Convenience wrappers
// ---------------------------------------------------------------------------

/**
 * Upload a profile image (5 MB limit enforced both client-side and server-side).
 *
 * @param {File} file
 * @returns {Promise<CloudinaryUploadResult>}
 */
export async function uploadProfileImage(file) {
  return uploadMedia(file, {
    folder: 'profile_images',
    maxBytes: SIZE_LIMITS.profileImage,
  });
}

/**
 * Upload a tiffin design image.
 *
 * @param {File} file
 * @returns {Promise<CloudinaryUploadResult>}
 */
export async function uploadTiffinImage(file) {
  return uploadMedia(file, {
    folder: 'tiffin_designs',
    maxBytes: SIZE_LIMITS.image,
  });
}

/**
 * Upload a heritage story video.
 *
 * @param {File} file
 * @returns {Promise<CloudinaryUploadResult>}
 */
export async function uploadHeritageVideo(file) {
  return uploadMedia(file, {
    folder: 'heritage_videos',
    maxBytes: SIZE_LIMITS.video,
  });
}

/**
 * Upload an artwork submission image.
 *
 * @param {File} file
 * @returns {Promise<CloudinaryUploadResult>}
 */
export async function uploadArtworkImage(file) {
  return uploadMedia(file, {
    folder: 'artwork_submissions',
    maxBytes: SIZE_LIMITS.image,
  });
}

/**
 * Upload a community post photo.
 *
 * @param {File} file
 * @returns {Promise<CloudinaryUploadResult>}
 */
export async function uploadCommunityPhoto(file) {
  return uploadMedia(file, {
    folder: 'community_posts',
    maxBytes: SIZE_LIMITS.image,
  });
}

// ---------------------------------------------------------------------------
// Re-export constants for use in validation UI
// ---------------------------------------------------------------------------

export { ALLOWED_IMAGE_TYPES, ALLOWED_VIDEO_TYPES, SIZE_LIMITS };
