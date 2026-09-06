import 'package:flutter_test/flutter_test.dart';

import 'package:mangkuk_kembara/Model/Services/google_map_api_service.dart';
import 'package:mangkuk_kembara/ViewModel/HeritageTreasureMap/route_navigation_view_model.dart';

void main() {
  test('Google Maps directions URI includes every supported travel mode', () {
    final service = GoogleMapApiService();
    final travelModes = TravelMode.values.map((mode) => mode.name).toList();

    expect(travelModes, ['driving', 'walking', 'transit']);

    for (final travelMode in travelModes) {
      final uri = service.buildDirectionsUri(
        latitude: 1.5535,
        longitude: 110.3593,
        travelMode: travelMode,
      );

      expect(uri.scheme, 'https');
      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/dir/');
      expect(uri.queryParameters['api'], '1');
      expect(uri.queryParameters['destination'], '1.5535,110.3593');
      expect(uri.queryParameters['travelmode'], travelMode);
      expect(uri.queryParameters['dir_action'], 'navigate');
    }
  });
}
