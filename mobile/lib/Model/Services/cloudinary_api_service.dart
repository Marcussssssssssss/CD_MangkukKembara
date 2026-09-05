import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_exception.dart';
import '../../core/backend_config.dart';
import 'supabase_api_service.dart';

class CloudinaryUploadResult {
  final String secureUrl;
  final String publicId;
  final String mimeType;
  final int bytes;
  final String sha256;

  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
    required this.mimeType,
    required this.bytes,
    required this.sha256,
  });

  factory CloudinaryUploadResult.fromJson(Map<String, dynamic> json) {
    return CloudinaryUploadResult(
      secureUrl: json['secure_url'] as String,
      publicId: json['public_id'] as String,
      mimeType: json['mime_type'] as String,
      bytes: (json['bytes'] as num).toInt(),
      sha256: json['sha256'] as String,
    );
  }
}

/// Uploads media through the authenticated Supabase Edge Function.
/// No Cloudinary API key, secret, or cloud name is stored in Flutter.
class CloudinaryApiService {
  static const _allowedImageExtensions = {'jpg', 'jpeg', 'png', 'webp'};

  final SupabaseApiService _supabase;
  final http.Client _httpClient;

  CloudinaryApiService({SupabaseApiService? supabase, http.Client? httpClient})
    : _supabase = supabase ?? SupabaseApiService(),
      _httpClient = httpClient ?? http.Client();

  Future<CloudinaryUploadResult> uploadImage(
    XFile file, {
    required String folder,
    int maxBytes = 10 * 1024 * 1024,
    bool webpOnly = false,
  }) async {
    _supabase.requireUser();
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) throw const AppException('The selected file is empty.');
    if (bytes.length > maxBytes) {
      throw AppException(
        'The selected image exceeds ${(maxBytes / 1024 / 1024).toStringAsFixed(0)} MB.',
      );
    }

    final extension = file.name.split('.').last.toLowerCase();
    if (webpOnly && file.mimeType != 'image/webp') {
      throw const AppException(
        'Artwork images must be converted to WebP before upload.',
      );
    }
    if (!webpOnly && !_allowedImageExtensions.contains(extension)) {
      throw const AppException('Choose a JPG, PNG, or WebP image.');
    }
    final mimeType = webpOnly
        ? 'image/webp'
        : file.mimeType ?? _mimeForExtension(extension);
    final uploadFilename = webpOnly
        ? 'artwork_${DateTime.now().millisecondsSinceEpoch}.webp'
        : file.name;
    final session = _supabase.currentSession;
    if (session == null) throw const AuthenticationRequiredException();

    final uri = Uri.parse(
      '${BackendConfig.supabaseUrl}/functions/v1/'
      '${BackendConfig.cloudinaryUploadFunction}',
    );
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${session.accessToken}'
      ..headers['apikey'] = BackendConfig.supabaseAnonKey
      ..fields['folder'] = folder
      ..fields['mime_type'] = mimeType
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: uploadFilename,
          contentType: MediaType.parse(mimeType),
        ),
      );

    try {
      final streamed = await _httpClient.send(request);
      final response = await http.Response.fromStream(streamed);
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppException(
          payload['error']?.toString() ?? 'Image upload failed.',
        );
      }
      return CloudinaryUploadResult.fromJson(payload);
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException('Image upload failed. Check your connection.', error);
    }
  }

  static String _mimeForExtension(String extension) => switch (extension) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'application/octet-stream',
  };
}
