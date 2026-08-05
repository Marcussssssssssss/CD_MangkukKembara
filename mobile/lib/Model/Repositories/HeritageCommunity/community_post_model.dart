import 'package:intl/intl.dart';

/// Community post (review/experience shared by a user).
class CommunityPostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String vendorId;
  final String vendorName;
  final String vendorState;
  final double vendorRating;
  final String reviewText;
  final String? postComment;
  final int likeCount;
  final int commentCount;
  final bool isLikedByCurrentUser;
  final DateTime postedAt;
  final List<String> photoUrls;

  const CommunityPostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.vendorId,
    required this.vendorName,
    required this.vendorState,
    required this.vendorRating,
    required this.reviewText,
    this.postComment,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLikedByCurrentUser = false,
    required this.postedAt,
    this.photoUrls = const [],
  });

  factory CommunityPostModel.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? author,
    bool isLikedByCurrentUser = false,
  }) {
    final vendor = json['vendors'] as Map<String, dynamic>?;
    final state = vendor?['states'] as Map<String, dynamic>?;
    final photos =
        (json['community_post_photos'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList()
          ..sort(
            (a, b) => ((a['sort_order'] as num?)?.toInt() ?? 0).compareTo(
              (b['sort_order'] as num?)?.toInt() ?? 0,
            ),
          );
    return CommunityPostModel(
      id: json['community_post_id'] as String,
      authorId: json['profile_id'] as String,
      authorName: author?['display_name'] as String? ?? 'Community member',
      authorAvatarUrl: author?['avatar_url'] as String?,
      vendorId: json['vendor_id'] as String,
      vendorName: vendor?['vendor_name'] as String? ?? '',
      vendorState: state?['state_name'] as String? ?? '',
      vendorRating: (json['rating'] as num).toDouble(),
      reviewText: json['written_review'] as String,
      postComment: json['post_comment'] as String?,
      likeCount: (json['like_count'] as num? ?? 0).toInt(),
      commentCount: (json['comment_count'] as num? ?? 0).toInt(),
      isLikedByCurrentUser: isLikedByCurrentUser,
      postedAt: DateTime.parse(json['created_at'] as String),
      photoUrls: photos
          .map((photo) => photo['photo_url'] as String?)
          .whereType<String>()
          .toList(),
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(postedAt);
    if (diff.inDays > 7) return DateFormat('d MMM yyyy').format(postedAt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  CommunityPostModel copyWith({bool? isLikedByCurrentUser, int? likeCount}) {
    return CommunityPostModel(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      vendorId: vendorId,
      vendorName: vendorName,
      vendorState: vendorState,
      vendorRating: vendorRating,
      reviewText: reviewText,
      postComment: postComment,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      postedAt: postedAt,
      photoUrls: photoUrls,
    );
  }
}
