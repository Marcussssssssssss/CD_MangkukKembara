import '../../Services/supabase_api_service.dart';
import 'food_category_model.dart';
import 'operating_hour_model.dart';
import 'pasar_malam_model.dart';
import 'vendor_tiffin_model.dart';
import 'vendor_model.dart';

class TreasureMapRepository {
  final SupabaseApiService _api;

  TreasureMapRepository({SupabaseApiService? api})
    : _api = api ?? SupabaseApiService();

  Future<List<VendorModel>> fetchVendors({
    String? query,
    String? state,
    String? foodCategoryId,
    bool standaloneOnly = false,
  }) async {
    var request = _api.client
        .from('vendors')
        .select('''
      *,
      states!inner(state_name),
      vendor_operating_hours(day_of_week, opening_time, closing_time, is_closed),
      vendor_foods(
        heritage_foods(
          food_name, food_category_id,
          food_categories(food_category_id, category_name)
        )
      )
    ''')
        .eq('participation_status', 'active');
    if (standaloneOnly) {
      request = request.isFilter('pasar_malam_id', null);
    }
    if (state != null && state.isNotEmpty) {
      request = request.eq('states.state_name', state);
    }
    final rows = await _api.guard(() => request.order('vendor_name'));
    final now = DateTime.now();
    var vendors = rows.map((raw) {
      final json = Map<String, dynamic>.from(raw);
      json['_is_open'] = _isOpenNow(
        (json['vendor_operating_hours'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList(),
        now,
      );
      return VendorModel.fromJson(json);
    }).toList();

    if (foodCategoryId != null && foodCategoryId.isNotEmpty) {
      vendors = vendors
          .where((vendor) => vendor.foodCategoryIds.contains(foodCategoryId))
          .toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      vendors = vendors
          .where((vendor) => _matchesVendorQuery(vendor, query))
          .toList();
    }
    return _withRatingSummaries(vendors);
  }

  Future<List<PasarMalamModel>> fetchPasarMalam({
    String? query,
    String? state,
  }) async {
    var request = _api.client
        .from('pasar_malam')
        .select('''
      *, states!inner(state_name),
      pasar_malam_operating_hours(
        day_of_week, opening_time, closing_time, is_closed
      ),
      vendors(vendor_id, participation_status)
    ''')
        .eq('is_active', true);
    if (state != null && state.isNotEmpty) {
      request = request.eq('states.state_name', state);
    }
    final rows = await _api.guard(() => request.order('pasar_malam_name'));
    final now = DateTime.now();
    var markets = rows.map((raw) {
      final json = Map<String, dynamic>.from(raw);
      json['_is_open'] = _isOpenNow(
        (json['pasar_malam_operating_hours'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList(),
        now,
      );
      return PasarMalamModel.fromJson(json);
    }).toList();
    if (query != null && query.trim().isNotEmpty) {
      final normalized = query.trim().toLowerCase();
      markets = markets
          .where(
            (market) =>
                market.name.toLowerCase().contains(normalized) ||
                market.state.toLowerCase().contains(normalized),
          )
          .toList();
    }
    return markets;
  }

  /// Active stalls for one Pasar Malam, linked by vendors.pasar_malam_id.
  Future<List<VendorModel>> fetchVendorsByPasarMalam(
    String pasarMalamId,
  ) async {
    final rows = await _api.guard(
      () => _api.client
          .from('vendors')
          .select('''
        *, states!inner(state_name),
        vendor_operating_hours(day_of_week, opening_time, closing_time, is_closed),
        vendor_foods(
          heritage_foods(
            food_name, food_category_id,
            food_categories(food_category_id, category_name)
          )
        )
      ''')
          .eq('pasar_malam_id', pasarMalamId)
          .eq('participation_status', 'active')
          .order('vendor_name'),
    );
    final now = DateTime.now();
    final vendors = rows.map((raw) {
      final json = Map<String, dynamic>.from(raw);
      json['_is_open'] = _isOpenNow(
        (json['vendor_operating_hours'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList(),
        now,
      );
      return VendorModel.fromJson(json);
    }).toList();
    return _withRatingSummaries(vendors);
  }

  Future<List<String>> fetchStateNames() async {
    final rows = await _api.guard(
      () => _api.client
          .from('states')
          .select('state_name')
          .eq('is_active', true)
          .order('state_name'),
    );
    return rows.map((row) => row['state_name'] as String).toList();
  }

  Future<List<FoodCategoryModel>> fetchFoodCategories() async {
    final rows = await _api.guard(
      () => _api.client
          .from('food_categories')
          .select('food_category_id, category_name')
          .order('category_name'),
    );
    return rows.map(FoodCategoryModel.fromJson).toList();
  }

  Future<VendorModel?> fetchVendorById(String id) async {
    final raw = await _api.guard(
      () => _api.client
          .from('vendors')
          .select('''
        *,
        states(state_name),
        vendor_operating_hours(day_of_week, opening_time, closing_time, is_closed),
        vendor_foods(
          heritage_foods(
            food_name, food_category_id,
            food_categories(food_category_id, category_name)
          )
        )
      ''')
          .eq('vendor_id', id)
          .eq('participation_status', 'active')
          .maybeSingle(),
    );
    if (raw == null) return null;
    final json = Map<String, dynamic>.from(raw);
    json['_is_open'] = _isOpenNow(
      (json['vendor_operating_hours'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList(),
      DateTime.now(),
    );
    final vendor = VendorModel.fromJson(json);
    return (await _withRatingSummaries([vendor])).single;
  }

  /// Calculates ratings from published community reviews instead of relying
  /// on the denormalized vendor columns, which may be stale.
  Future<({double averageRating, int reviewCount})> fetchVendorRatingSummary(
    String vendorId,
  ) async {
    final summaries = await _fetchRatingSummaries([vendorId]);
    return summaries[vendorId] ?? (averageRating: 0.0, reviewCount: 0);
  }

  Future<List<VendorModel>> _withRatingSummaries(
    List<VendorModel> vendors,
  ) async {
    if (vendors.isEmpty) return vendors;
    final summaries = await _fetchRatingSummaries(
      vendors.map((vendor) => vendor.id).toList(),
    );
    return vendors.map((vendor) {
      final summary = summaries[vendor.id];
      return vendor.copyWith(
        averageRating: summary?.averageRating ?? 0,
        reviewCount: summary?.reviewCount ?? 0,
      );
    }).toList();
  }

  Future<Map<String, ({double averageRating, int reviewCount})>>
  _fetchRatingSummaries(List<String> vendorIds) async {
    if (vendorIds.isEmpty) return {};
    final rows = await _api.guard(
      () => _api.client
          .from('community_posts')
          .select('vendor_id, rating')
          .inFilter('vendor_id', vendorIds)
          .eq('status', 'published'),
    );
    final ratings = <String, List<double>>{};
    for (final row in rows) {
      final vendorId = row['vendor_id'] as String;
      ratings
          .putIfAbsent(vendorId, () => [])
          .add((row['rating'] as num).toDouble());
    }
    return {
      for (final entry in ratings.entries)
        entry.key: (
          averageRating:
              entry.value.reduce((sum, rating) => sum + rating) /
              entry.value.length,
          reviewCount: entry.value.length,
        ),
    };
  }

  Future<List<OperatingHourModel>> fetchOperatingHours(String vendorId) async {
    final rows = await _api.guard(
      () => _api.client
          .from('vendor_operating_hours')
          .select()
          .eq('vendor_id', vendorId)
          .order('day_of_week'),
    );
    return rows.map(OperatingHourModel.fromJson).toList();
  }

  Future<List<VendorTiffinModel>> fetchVendorTiffins(String vendorId) async {
    final rows = await _api.guard(
      () => _api.client
          .from('vendor_tiffins')
          .select('''
        *, heritage_tiffins(edition_name, artworks(image_url))
      ''')
          .eq('vendor_id', vendorId),
    );
    return rows.map(VendorTiffinModel.fromJson).toList();
  }

  static bool _isOpenNow(
    List<Map<String, dynamic>> operatingHours,
    DateTime now,
  ) {
    final today = operatingHours.where(
      (row) => (row['day_of_week'] as num?)?.toInt() == now.weekday % 7,
    );
    if (today.isEmpty) return false;
    final hours = today.first;
    if (hours['is_closed'] == true) return false;
    final open = _minutes(hours['opening_time'] as String?);
    final close = _minutes(hours['closing_time'] as String?);
    if (open == null || close == null) return false;
    final current = now.hour * 60 + now.minute;
    return close >= open
        ? current >= open && current < close
        : current >= open || current < close;
  }

  static int? _minutes(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  static bool _matchesVendorQuery(VendorModel vendor, String query) {
    final terms = query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList();
    if (terms.isEmpty) return true;

    final searchableText = [
      vendor.name,
      vendor.description,
      vendor.state,
      vendor.address,
      vendor.businessType,
      ...vendor.heritageFoods,
      ...vendor.foodCategories,
    ].join(' ').toLowerCase();

    return terms.every(searchableText.contains);
  }
}
