import 'package:url_launcher/url_launcher.dart';

import '../../core/app_exception.dart';

class MediaPlaybackService {
  Future<void> open(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !uri.hasScheme) {
      throw const AppException('This media URL is invalid.');
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      throw const AppException('Could not open this media item.');
    }
  }
}
