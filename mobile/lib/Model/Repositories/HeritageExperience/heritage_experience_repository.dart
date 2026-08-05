import '../../../core/app_exception.dart';
import '../../Services/supabase_api_service.dart';
import 'artist_model.dart';
import 'artwork_model.dart';
import 'heritage_media_model.dart';
import 'heritage_food_model.dart';
import 'heritage_story_model.dart';
import 'heritage_tiffin_model.dart';
import 'qr_scan_result_model.dart';

class HeritageExperienceRepository {
  final SupabaseApiService _api;

  HeritageExperienceRepository({SupabaseApiService? api})
    : _api = api ?? SupabaseApiService();

  Future<List<HeritageTiffinModel>> fetchTiffins({String? state}) async {
    var request = _api.client
        .from('heritage_tiffins')
        .select('''
      *, states!inner(state_name, state_code), artworks(profile_id)
    ''')
        .eq('status', 'active');
    if (state != null && state.isNotEmpty) {
      request = request.eq('states.state_name', state);
    }
    final rows = await _api.guard(() => request.order('edition_name'));
    return rows.map(HeritageTiffinModel.fromJson).toList();
  }

  Future<HeritageTiffinModel?> fetchTiffinById(String id) async {
    final json = await _api.guard(
      () => _api.client
          .from('heritage_tiffins')
          .select('''
        *, states(state_name, state_code), artworks(profile_id)
      ''')
          .eq('heritage_tiffin_id', id)
          .eq('status', 'active')
          .maybeSingle(),
    );
    return json == null ? null : HeritageTiffinModel.fromJson(json);
  }

  Future<Set<String>> fetchCollectedTiffinIds(String userId) async {
    final user = _api.requireUser();
    if (user.id != userId) {
      throw const AppException('Collection access denied.');
    }
    final profileId = await _currentProfileId(userId);
    final rows = await _api.guard(
      () => _api.client
          .from('user_tiffin_collection')
          .select('heritage_tiffin_id')
          .eq('profile_id', profileId),
    );
    return rows.map((row) => row['heritage_tiffin_id'] as String).toSet();
  }

  /// Returns only active tiffins collected by the authenticated user.
  Future<List<HeritageTiffinModel>> fetchCollectedTiffins(
    String userId, {
    String? state,
  }) async {
    final ids = await fetchCollectedTiffinIds(userId);
    if (ids.isEmpty) return [];
    var request = _api.client
        .from('heritage_tiffins')
        .select('*, states!inner(state_name, state_code), artworks(profile_id)')
        .eq('status', 'active')
        .inFilter('heritage_tiffin_id', ids.toList());
    if (state != null && state.isNotEmpty) {
      request = request.eq('states.state_name', state);
    }
    final rows = await _api.guard(() => request.order('edition_name'));
    return rows.map(HeritageTiffinModel.fromJson).toList();
  }

  Future<int> fetchTotalActiveTiffinCount() async {
    final rows = await _api.guard(
      () => _api.client
          .from('heritage_tiffins')
          .select('heritage_tiffin_id')
          .eq('status', 'active'),
    );
    return rows.length;
  }

  Future<QrScanResultModel> scanQrCode(String userId, String codeValue) async {
    final user = _api.requireUser();
    if (user.id != userId) {
      throw const AppException('QR collection access denied.');
    }
    if (codeValue.trim().isEmpty) {
      throw const AppException('The QR code is empty.');
    }
    final qr = await _api.guard(
      () => _api.client
          .from('tiffin_qr_codes')
          .select('''
        tiffin_qr_code_id, heritage_tiffin_id, expires_at,
        heritage_tiffins!inner(edition_name, status, states(state_name))
      ''')
          .eq('code_value', codeValue.trim())
          .eq('is_active', true)
          .eq('heritage_tiffins.status', 'active')
          .maybeSingle(),
    );
    if (qr == null) {
      throw const AppException('The QR code is invalid or inactive.');
    }
    final expiresAt = DateTime.tryParse(qr['expires_at'] as String? ?? '');
    if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
      throw const AppException('The QR code has expired.');
    }
    final profileId = await _currentProfileId(userId);
    final tiffinId = qr['heritage_tiffin_id'] as String;
    final existing = await _api.guard(
      () => _api.client
          .from('user_tiffin_collection')
          .select('user_tiffin_collection_id')
          .eq('profile_id', profileId)
          .eq('heritage_tiffin_id', tiffinId)
          .maybeSingle(),
    );
    final isNew = existing == null;
    if (isNew) {
      await _api.guard(
        () => _api.client.from('user_tiffin_collection').insert({
          'profile_id': profileId,
          'heritage_tiffin_id': tiffinId,
          'tiffin_qr_code_id': qr['tiffin_qr_code_id'],
        }),
      );
    }
    final tiffin = qr['heritage_tiffins'] as Map<String, dynamic>;
    return QrScanResultModel.fromJson({
      'heritage_tiffin_id': tiffinId,
      'newly_collected': isNew,
    }, tiffin);
  }

  Future<ArtistModel?> fetchArtistById(String id) async {
    final json = await _api.guard(
      () => _api.client
          .from('public_profiles')
          .select(
            'profile_id, display_name, avatar_url, biography, website_url',
          )
          .eq('profile_id', id)
          .maybeSingle(),
    );
    return json == null ? null : ArtistModel.fromJson(json);
  }

  Future<ArtworkModel?> fetchArtworkById(String id) async {
    final json = await _api.guard(
      () => _api.client
          .from('artworks')
          .select()
          .eq('artwork_id', id)
          .eq('status', 'published')
          .maybeSingle(),
    );
    return json == null ? null : ArtworkModel.fromJson(json);
  }

  Future<List<HeritageStoryModel>> fetchStoriesByTiffinId(
    String tiffinId,
  ) async {
    final rows = await _api.guard(
      () => _api.client
          .from('heritage_stories')
          .select()
          .eq('heritage_tiffin_id', tiffinId)
          .eq('is_published', true)
          .order('sort_order'),
    );
    return rows.map(HeritageStoryModel.fromJson).toList();
  }

  Future<List<HeritageMediaModel>> fetchMediaByTiffinId(String tiffinId) async {
    final rows = await _api.guard(
      () => _api.client
          .from('heritage_media')
          .select()
          .eq('heritage_tiffin_id', tiffinId)
          .eq('is_published', true)
          .order('sort_order'),
    );
    return rows.map(HeritageMediaModel.fromJson).toList();
  }

  Future<HeritageMediaModel?> fetchMediaById(String id) async {
    final json = await _api.guard(
      () => _api.client
          .from('heritage_media')
          .select()
          .eq('heritage_media_id', id)
          .eq('is_published', true)
          .maybeSingle(),
    );
    return json == null ? null : HeritageMediaModel.fromJson(json);
  }

  Future<HeritageFoodModel?> fetchFoodByTiffinId(String tiffinId) async {
    final row = await _api.guard(
      () => _api.client
          .from('heritage_tiffins')
          .select('''
        heritage_foods(
          *, food_categories(category_name), states(state_name)
        )
      ''')
          .eq('heritage_tiffin_id', tiffinId)
          .eq('status', 'active')
          .maybeSingle(),
    );
    final food = row?['heritage_foods'] as Map<String, dynamic>?;
    return food == null ? null : HeritageFoodModel.fromJson(food);
  }

  Future<String> _currentProfileId(String userId) async {
    final user = _api.requireUser();
    if (user.id != userId) {
      throw const AppException('Profile access denied.');
    }
    final profile = await _api.guard(
      () => _api.client
          .from('profiles')
          .select('profile_id')
          .eq('auth_user_id', userId)
          .maybeSingle(),
    );
    if (profile == null) {
      throw const AppException(
        'Your account profile is missing. Please contact support.',
      );
    }
    return profile['profile_id'] as String;
  }
}
