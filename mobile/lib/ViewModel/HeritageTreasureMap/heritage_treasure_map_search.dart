import 'package:flutter/foundation.dart';

import '../../Model/Repositories/HeritageTreasureMap/vendor_model.dart';

/// Search and filter rules used by the Heritage Treasure Map views.
abstract final class HeritageTreasureMapSearch {
  static const Map<String, String> _stateAliases = {
    'penang': 'penang',
    'pulau pinang': 'penang',
    'kuala lumpur': 'kuala lumpur',
    'wp kuala lumpur': 'kuala lumpur',
    'w.p. kuala lumpur': 'kuala lumpur',
    'wilayah persekutuan kl': 'kuala lumpur',
    'wilayah persekutuan kuala lumpur': 'kuala lumpur',
    'labuan': 'labuan',
    'wilayah persekutuan labuan': 'labuan',
    'putrajaya': 'putrajaya',
    'wilayah persekutuan putrajaya': 'putrajaya',
  };

  static const Map<String, String> _databaseStateNames = {
    'penang': 'Penang',
    'kuala lumpur': 'Kuala Lumpur',
    'labuan': 'Labuan',
    'putrajaya': 'Putrajaya',
  };

  static List<VendorModel> filterVendors(
    Iterable<VendorModel> vendors, {
    String query = '',
    String state = 'All States',
    String foodCategory = 'All',
    String? foodCategoryId,
  }) {
    final vendorList = vendors.toList();
    final filteredVendors = vendorList
        .where(
          (vendor) =>
              _matchesState(vendor, state) &&
              _matchesFoodCategory(vendor, foodCategory, foodCategoryId) &&
              matchesVendor(vendor, query),
        )
        .toList();

    final matchedFoodRecords = <String>[];
    if (foodCategoryId != null && foodCategoryId.isNotEmpty) {
      for (final vendor in vendorList) {
        for (var index = 0; index < vendor.heritageFoods.length; index++) {
          if (index < vendor.foodCategoryIds.length &&
              vendor.foodCategoryIds[index] == foodCategoryId) {
            matchedFoodRecords.add(
              '${vendor.id}:${vendor.heritageFoods[index]}',
            );
          }
        }
      }
    }
    debugPrint(
      '[TreasureMap][FoodCategory] '
      'selected_category_id=${foodCategoryId ?? 'All'}',
    );
    debugPrint(
      '[TreasureMap][FoodCategory] '
      'matched_food_records=$matchedFoodRecords',
    );
    debugPrint(
      '[TreasureMap][FoodCategory] '
      'matched_vendors=${filteredVendors.map((vendor) => '${vendor.id}:${vendor.name}').toList()}',
    );
    return filteredVendors;
  }

  static bool matchesVendor(VendorModel vendor, String query) {
    final terms = _terms(query);
    if (terms.isEmpty) return true;

    final searchableText = _normalize(
      [
        vendor.name,
        vendor.description,
        vendor.state,
        vendor.address,
        vendor.businessType,
        ...vendor.heritageFoods,
        ...vendor.foodCategories,
      ].join(' '),
    );

    return terms.every(searchableText.contains);
  }

  static bool _matchesState(VendorModel vendor, String state) {
    return _normalize(state) == 'all states' ||
        normalizeStateName(vendor.state) == normalizeStateName(state);
  }

  /// Converts a UI state label to the canonical value used for comparisons.
  static String normalizeStateName(String state) {
    final normalized = _normalize(state);
    return _stateAliases[normalized] ?? normalized;
  }

  /// Converts a UI state label to the database's display value for filters.
  static String? databaseStateName(String state) {
    if (_normalize(state) == 'all states') return null;
    final canonical = normalizeStateName(state);
    return _databaseStateNames[canonical] ?? state.trim();
  }

  static bool _matchesFoodCategory(
    VendorModel vendor,
    String category,
    String? categoryId,
  ) {
    if (category == 'All') return true;
    return categoryId != null && vendor.foodCategoryIds.contains(categoryId);
  }

  static List<String> _terms(String value) {
    return _normalize(
      value,
    ).split(RegExp(r'\s+')).where((term) => term.isNotEmpty).toList();
  }

  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
