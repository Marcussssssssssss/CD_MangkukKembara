/// Represents a user's collected tiffin item.
class CollectionItemModel {
  final String id;
  final String userId;
  final String tiffinId;
  final DateTime collectedAt;

  const CollectionItemModel({
    required this.id,
    required this.userId,
    required this.tiffinId,
    required this.collectedAt,
  });

  factory CollectionItemModel.fromJson(Map<String, dynamic> json) =>
      CollectionItemModel(
        id: json['user_tiffin_collection_id'] as String,
        userId: json['profile_id'] as String,
        tiffinId: json['heritage_tiffin_id'] as String,
        collectedAt: DateTime.parse(json['collected_at'] as String),
      );
}
