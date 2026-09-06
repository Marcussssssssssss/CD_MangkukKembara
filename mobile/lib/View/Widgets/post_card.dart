import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../Model/Repositories/HeritageCommunity/community_post_model.dart';
import 'app_network_image.dart';
import 'rating_bar.dart';

/// Community post card used in the feed and search results.
class PostCard extends StatelessWidget {
  final CommunityPostModel post;
  final VoidCallback onTap;
  final VoidCallback? onLike;
  final bool isLoggedIn;
  final Color? primaryColor;
  final Color? mutedColor;
  final Color? ratingColor;
  final Color? borderColor;

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.onLike,
    this.isLoggedIn = false,
    this.primaryColor,
    this.mutedColor,
    this.ratingColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? AppColors.primary;
    final muted = mutedColor ?? AppColors.textHint;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor ?? Colors.transparent),
      ),
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
                    backgroundColor: primary,
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
                    filledColor: ratingColor,
                    labelColor: muted,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Vendor tag
              Row(
                children: [
                  Icon(Icons.storefront_rounded, size: 14, color: primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${post.vendorName} · ${post.vendorState}',
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(color: primary),
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
                  height: 150,
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
                                child: AppNetworkImage(
                                  imageUrl: url,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  targetOptimizationWidth: 600,
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
                    color: post.isLikedByCurrentUser ? AppColors.error : muted,
                    onTap: onLike,
                  ),
                  const SizedBox(width: 16),
                  _ActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '${post.commentCount}',
                    color: muted,
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
  final Color backgroundColor;
  const _Avatar({
    required this.name,
    this.imageUrl,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: backgroundColor,
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Icon(icon, key: ValueKey(icon), size: 18, color: color),
          ),
          const SizedBox(width: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              label,
              key: ValueKey(label),
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
