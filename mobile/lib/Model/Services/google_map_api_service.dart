import 'package:url_launcher/url_launcher.dart';

/// Opens directions in the platform's installed map application or browser.
class GoogleMapApiService {
  Uri buildDirectionsUri({
    required double latitude,
    required double longitude,
    String travelMode = 'driving',
  }) => Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': '$latitude,$longitude',
    'travelmode': travelMode,
  });

  Future<bool> openDirections({
    required double latitude,
    required double longitude,
    String travelMode = 'driving',
  }) {
    final uri = buildDirectionsUri(
      latitude: latitude,
      longitude: longitude,
      travelMode: travelMode,
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
