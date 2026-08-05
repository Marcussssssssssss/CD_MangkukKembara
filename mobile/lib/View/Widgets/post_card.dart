import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../Model/Repositories/HeritageCommunity/community_post_model.dart';
import 'rating_bar.dart';

/// Community post card used in the feed and search results.
class PostCard extends StatelessWidget {
  final CommunityPostModel post;
  final VoidCallback onTap;
  final VoidCallback? onLike;
  final bool isLoggedIn;

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.onLike,
    this.isLoggedIn = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author row
              Row(
                children: [
                  _Avatar(
                    name: post.authorName,
                    imageUrl: post.authorAvatarUrl,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          post.timeAgo,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  RatingBar(
                    rating: post.vendorRating,
                    size: 14,
                    showLabel: true,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Vendor tag
              Row(
                children: [
                  const Icon(
                    Icons.storefront_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${post.vendorName} · ${post.vendorState}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Review text
              Text(
                post.reviewText,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              if (post.photoUrls.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 70,
                  child: Row(
                    children: post.photoUrls.take(3).map((url) {
                      final isLast =
                          post.photoUrls.length > 3 && url == post.photoUrls[2];
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (_, _, _) => const ColoredBox(
                                    color: AppColors.surfaceVariant,
                                    child: Icon(Icons.broken_image_outlined),
                                  ),
                                ),
                              ),
                              if (isLast && post.photoUrls.length > 3)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    color: Colors.black38,
                                    child: Center(
                                      child: Text(
                                        '+${post.photoUrls.length - 3}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Action row
              Row(
                children: [
                  _ActionButton(
                    icon: post.isLikedByCurrentUser
                        ? Icons.favorite_rounded
                        : Icons.favorite_outline_rounded,
                    label: '${post.likeCount}',
                    color: post.isLikedByCurrentUser
                        ? AppColors.error
                        : AppColors.textHint,
                    onTap: onLike,
                  ),
                  const SizedBox(width: 16),
                  _ActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '${post.commentCount}',
                    color: AppColors.textHint,
                    onTap: onTap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  const _Avatar({required this.name, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.primary,
      backgroundImage: imageUrl == null ? null : NetworkImage(imageUrl!),
      child: imageUrl == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
