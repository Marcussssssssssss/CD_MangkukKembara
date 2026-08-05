class HeritageFoodModel {
  final String id;
  final String name;
  final String? categoryName;
  final String? originStateName;
  final String? originSummary;
  final String? culturalSignificance;
  final String? imageUrl;

  const HeritageFoodModel({
    required this.id,
    required this.name,
    this.categoryName,
    this.originStateName,
    this.originSummary,
    this.culturalSignificance,
    this.imageUrl,
  });

  factory HeritageFoodModel.fromJson(Map<String, dynamic> json) {
    final category = json['food_categories'] as Map<String, dynamic>?;
    final state = json['states'] as Map<String, dynamic>?;
    return HeritageFoodModel(
      id: json['heritage_food_id'] as String,
      name: json['food_name'] as String,
      categoryName: category?['category_name'] as String?,
      originStateName: state?['state_name'] as String?,
      originSummary: json['origin_summary'] as String?,
      culturalSignificance: json['cultural_significance'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }
}
