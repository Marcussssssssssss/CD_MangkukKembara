/// Represents a vendor (heritage food stall / restaurant) on the treasure map.
class VendorModel {
  final String id;
  final String name;
  final String description;
  final String state;
  final String address;
  final String contactPerson;
  final String? contactNumber;
  final String? email;
  final String businessType;
  final String? coverImageUrl;
  final String? pasarMalamId;
  final double latitude;
  final double longitude;
  final double averageRating;
  final int reviewCount;
  final bool isOpen;
  final List<String> foodCategories;
  final List<String> heritageFoods;
  final double? distanceKm;

  const VendorModel({
    required this.id,
    required this.name,
    required this.description,
    required this.state,
    required this.address,
    required this.contactPerson,
    this.contactNumber,
    this.email,
    required this.businessType,
    this.coverImageUrl,
    this.pasarMalamId,
    required this.latitude,
    required this.longitude,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.isOpen = true,
    this.foodCategories = const [],
    this.heritageFoods = const [],
    this.distanceKm,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    final state = json['states'] as Map<String, dynamic>?;
    final foods = (json['vendor_foods'] as List<dynamic>? ?? const [])
        .map((row) => (row as Map<String, dynamic>)['heritage_foods'])
        .whereType<Map<String, dynamic>>()
        .toList();
    final categories = foods
        .map((food) => food['food_categories'])
        .whereType<Map<String, dynamic>>()
        .map((category) => category['category_name'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    final addressParts = <String?>[
      json['address_line'] as String?,
      state?['state_name'] as String?,
    ].whereType<String>().where((value) => value.trim().isNotEmpty);
    return VendorModel(
      id: json['vendor_id'] as String,
      name: json['vendor_name'] as String,
      description: json['description'] as String? ?? '',
      state: state?['state_name'] as String? ?? '',
      address: addressParts.join(', '),
      contactPerson: json['contact_person'] as String? ?? '',
      contactNumber: json['contact_number'] as String?,
      email: json['email'] as String?,
      businessType: (json['business_type'] as String? ?? '').replaceAll(
        '_',
        ' ',
      ),
      coverImageUrl: (json['cover_image_url'] as String?)?.trim(),
      pasarMalamId: json['pasar_malam_id'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      averageRating: (json['average_rating'] as num? ?? 0).toDouble(),
      reviewCount: (json['review_count'] as num? ?? 0).toInt(),
      isOpen: json['_is_open'] as bool? ?? false,
      foodCategories: categories,
      heritageFoods: foods
          .map((food) => food['food_name'] as String?)
          .whereType<String>()
          .toList(),
      distanceKm: (json['_distance_km'] as num?)?.toDouble(),
    );
  }

  @override
  String toString() => 'VendorModel(id: $id, name: $name)';

  VendorModel copyWith({
    double? distanceKm,
    double? averageRating,
    int? reviewCount,
  }) => VendorModel(
    id: id,
    name: name,
    description: description,
    state: state,
    address: address,
    contactPerson: contactPerson,
    contactNumber: contactNumber,
    email: email,
    businessType: businessType,
    coverImageUrl: coverImageUrl,
    pasarMalamId: pasarMalamId,
    latitude: latitude,
    longitude: longitude,
    averageRating: averageRating ?? this.averageRating,
    reviewCount: reviewCount ?? this.reviewCount,
    isOpen: isOpen,
    foodCategories: foodCategories,
    heritageFoods: heritageFoods,
    distanceKm: distanceKm ?? this.distanceKm,
  );
}
