/// Utility for transforming Cloudinary URLs to request auto-formatted,
/// auto-quality, and dynamically resized images.
class CloudinaryUtils {
  /// Converts a Cloudinary URL into an optimized URL with f_auto, q_auto,
  /// and optional width constraint.
  ///
  /// Example:
  /// Input: `https://res.cloudinary.com/demo/image/upload/mangkukkembara/foods/char-kway-teow.jpg`
  /// Output: `https://res.cloudinary.com/demo/image/upload/f_auto,q_auto,w_800,c_limit/mangkukkembara/foods/char-kway-teow.jpg`
  static String getOptimizedUrl(String? url, {int width = 800}) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmedUrl = url.trim();

    // If it's not a Cloudinary image upload URL, return as-is.
    if (!trimmedUrl.contains('res.cloudinary.com') ||
        !trimmedUrl.contains('/upload/')) {
      return trimmedUrl;
    }

    // Don't re-apply if optimization flags are already present.
    if (trimmedUrl.contains('/upload/f_auto') ||
        trimmedUrl.contains('/upload/q_auto')) {
      return trimmedUrl;
    }

    return trimmedUrl.replaceFirst(
      '/upload/',
      '/upload/f_auto,q_auto,w_$width,c_limit/',
    );
  }
}
