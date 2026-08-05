/// A comment on a community post.
class CommunityCommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String body;
  final String? parentCommentId; // null = top-level comment
  final DateTime postedAt;
  final List<CommunityCommentModel> replies;

  const CommunityCommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.body,
    this.parentCommentId,
    required this.postedAt,
    this.replies = const [],
  });

  factory CommunityCommentModel.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? author,
    List<CommunityCommentModel> replies = const [],
  }) => CommunityCommentModel(
    id: json['community_comment_id'] as String,
    postId: json['community_post_id'] as String,
    authorId: json['profile_id'] as String,
    authorName: author?['display_name'] as String? ?? 'Community member',
    authorAvatarUrl: author?['avatar_url'] as String?,
    body: json['comment_text'] as String,
    parentCommentId: json['parent_comment_id'] as String?,
    postedAt: DateTime.parse(json['created_at'] as String),
    replies: replies,
  );

  String get timeAgo {
    final diff = DateTime.now().difference(postedAt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
