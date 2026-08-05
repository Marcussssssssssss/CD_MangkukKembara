/// Heritage story linked to a tiffin edition.
class HeritageStoryModel {
  final String id;
  final String tiffinId;
  final String title;
  final String body;
  final int storyOrder;

  const HeritageStoryModel({
    required this.id,
    required this.tiffinId,
    required this.title,
    required this.body,
    required this.storyOrder,
  });

  factory HeritageStoryModel.fromJson(Map<String, dynamic> json) =>
      HeritageStoryModel(
        id: json['heritage_story_id'] as String,
        tiffinId: json['heritage_tiffin_id'] as String,
        title: json['title'] as String,
        body: json['story_body'] as String,
        storyOrder: (json['sort_order'] as num? ?? 0).toInt(),
      );
}
