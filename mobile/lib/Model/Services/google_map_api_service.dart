import 'package:url_launcher/url_launcher.dart';

/// Opens directions in the platform's installed map application or browser.
class GoogleMapApiService {
  Future<bool> openDirections({
    required double latitude,
    required double longitude,
    String travelMode = 'driving',
  }) {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$latitude,$longitude',
      'travelmode': travelMode,
    });
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
