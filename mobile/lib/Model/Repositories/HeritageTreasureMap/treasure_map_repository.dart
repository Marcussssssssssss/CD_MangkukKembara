import '../../Services/supabase_api_service.dart';
import 'operating_hour_model.dart';
import 'pasar_malam_model.dart';
import 'tiffin_availability_model.dart';
import 'vendor_model.dart';

class TreasureMapRepository {
  final SupabaseApiService _api;

  TreasureMapRepository({SupabaseApiService? api})
    : _api = api ?? SupabaseApiService();

  Future<List<VendorModel>> fetchVendors({
    String? query,
    String? state,
    String? foodCategory,
    bool standaloneOnly = false,
  }) async {
    var request = _api.client
        .from('vendors')
        .select('''
      *,
      states!inner(state_name),
      vendor_operating_hours(day_of_week, opening_time, closing_time, is_closed),
      vendor_foods(
        heritage_foods(food_name, food_categories(category_name))
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

    if (foodCategory != null && foodCategory.isNotEmpty) {
      vendors = vendors
          .where((vendor) => vendor.foodCategories.contains(foodCategory))
          .toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final normalized = query.trim().toLowerCase();
      vendors = vendors.where((vendor) {
        return vendor.name.toLowerCase().contains(normalized) ||
            vendor.state.toLowerCase().contains(normalized) ||
            vendor.heritageFoods.any(
              (food) => food.toLowerCase().contains(normalized),
            );
      }).toList();
    }
    return vendors;
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
      )
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
        vendor_foods(heritage_foods(food_name, food_categories(category_name)))
      ''')
          .eq('pasar_malam_id', pasarMalamId)
          .eq('participation_status', 'active')
          .order('vendor_name'),
    );
    final now = DateTime.now();
    return rows.map((raw) {
      final json = Map<String, dynamic>.from(raw);
      json['_is_open'] = _isOpenNow(
        (json['vendor_operating_hours'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList(),
        now,
      );
      return VendorModel.fromJson(json);
    }).toList();
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

  Future<List<String>> fetchFoodCategoryNames() async {
    final rows = await _api.guard(
      () => _api.client
          .from('food_categories')
          .select('category_name')
          .eq('is_active', true)
          .order('category_name'),
    );
    return rows.map((row) => row['category_name'] as String).toList();
  }

  Future<VendorModel?> fetchVendorById(String id) async {
    final raw = await _api.guard(
      () => _api.client
          .from('vendors')
          .select('''
        *,
        states(state_name),
        vendor_operating_hours(day_of_week, opening_time, closing_time, is_closed),
        vendor_foods(heritage_foods(food_name, food_categories(category_name)))
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
    return VendorModel.fromJson(json);
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

  Future<List<TiffinAvailabilityModel>> fetchTiffinAvailability(
    String vendorId,
  ) async {
    final rows = await _api.guard(
      () => _api.client
          .from('vendor_tiffin_availability')
          .select('''
        *, heritage_tiffins(edition_name)
      ''')
          .eq('vendor_id', vendorId)
          .neq('availability_status', 'unavailable'),
    );
    return rows.map(TiffinAvailabilityModel.fromJson).toList();
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
}
