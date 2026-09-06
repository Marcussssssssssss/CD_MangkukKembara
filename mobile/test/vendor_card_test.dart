import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mangkuk_kembara/Model/Repositories/HeritageTreasureMap/vendor_model.dart';
import 'package:mangkuk_kembara/View/Widgets/app_network_image.dart';
import 'package:mangkuk_kembara/View/Widgets/vendor_card.dart';

void main() {
  testWidgets('vendor card uses the cover image when a URL exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VendorCard(
            vendor: _vendor(coverImageUrl: 'https://example.com/vendor.jpg'),
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.byType(AppNetworkImage), findsOneWidget);
  });

  testWidgets('vendor card keeps the fallback when no URL exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VendorCard(vendor: _vendor(), onTap: () {}),
        ),
      ),
    );

    expect(find.byType(AppNetworkImage), findsNothing);
    expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
  });
}

VendorModel _vendor({String? coverImageUrl}) {
  return VendorModel(
    id: 'V0001',
    name: 'Test Vendor',
    description: '',
    state: 'Penang',
    address: '1 Test Street',
    contactPerson: '',
    businessType: 'restaurant',
    coverImageUrl: coverImageUrl,
    latitude: 5.4141,
    longitude: 100.3288,
  );
}
