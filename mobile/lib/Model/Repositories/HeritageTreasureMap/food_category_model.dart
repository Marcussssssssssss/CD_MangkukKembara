/// A food category loaded from the food_categories table.
class FoodCategoryModel {
  final String id;
  final String name;

  const FoodCategoryModel({required this.id, required this.name});

  factory FoodCategoryModel.fromJson(Map<String, dynamic> json) {
    return FoodCategoryModel(
      id: json['food_category_id'] as String,
      name: json['category_name'] as String,
    );
  }
}
