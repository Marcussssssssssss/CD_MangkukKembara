/// Heritage food served by a vendor.
class HeritageFoodModel {
  final String id;
  final String name;
  final String category;
  final String origin;
  final String description;
  final String? culturalSignificance;
  final String? imageUrl;

  const HeritageFoodModel({
    required this.id,
    required this.name,
    required this.category,
    required this.origin,
    required this.description,
    this.culturalSignificance,
    this.imageUrl,
  });

  factory HeritageFoodModel.fromJson(Map<String, dynamic> json) {
    final category = json['food_categories'] as Map<String, dynamic>?;
    final state = json['states'] as Map<String, dynamic>?;
    return HeritageFoodModel(
      id: json['heritage_food_id'] as String,
      name: json['food_name'] as String,
      category: category?['category_name'] as String? ?? '',
      origin: state?['state_name'] as String? ?? '',
      description: json['origin_summary'] as String? ?? '',
      culturalSignificance: json['cultural_significance'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }
}
