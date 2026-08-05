import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../ViewModel/HeritageCommunity/post_detail_view_model.dart';
import '../../ViewModel/AccountManagement/auth_view_model.dart';
import '../../Model/Repositories/HeritageCommunity/community_comment_model.dart';
import '../Widgets/loading_widget.dart';
import '../Widgets/error_state_widget.dart';
import '../Widgets/rating_bar.dart';
import '../Widgets/login_required_dialog.dart';

/// C3. Community Post Details View.
class PostDetailView extends StatefulWidget {
  final String postId;
  const PostDetailView({super.key, required this.postId});

  @override
  State<PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends State<PostDetailView> {
  late final PostDetailViewModel _vm;
  final _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm = PostDetailViewModel();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _vm.loadPost(widget.postId),
    );
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer2<PostDetailViewModel, AuthViewModel>(
        builder: (ctx, vm, auth, _) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('Post')),
          body: vm.isLoading
              ? const LoadingSpinner()
              : vm.hasError || vm.post == null
              ? ErrorStateWidget(onRetry: () => _vm.retry(widget.postId))
              : RefreshIndicator(
                  onRefresh: () =>
                      vm.loadPost(widget.postId, showLoading: false),
                  child: _buildContent(ctx, vm, auth),
                ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext ctx,
    PostDetailViewModel vm,
    AuthViewModel auth,
  ) {
    final p = vm.post!;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author + date
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primary,
                      backgroundImage: p.authorAvatarUrl == null
                          ? null
                          : NetworkImage(p.authorAvatarUrl!),
                      child: p.authorAvatarUrl == null
                          ? Text(
                              p.authorName[0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.authorName,
                            style: Theme.of(ctx).textTheme.titleSmall,
                          ),
                          Text(
                            p.timeAgo,
                            style: Theme.of(ctx).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    RatingBar(rating: p.vendorRating, size: 16),
                  ],
                ),
                const SizedBox(height: 12),

                // Vendor badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.storefront_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${p.vendorName} · ${p.vendorState}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Review
                Text(
                  p.reviewText,
                  style: Theme.of(
                    ctx,
                  ).textTheme.bodyLarge?.copyWith(height: 1.6),
                ),
                if (p.postComment != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      p.postComment!,
                      style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],

                // Photos
                if (p.photoUrls.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: p.photoUrls.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            p.photoUrls[i],
                            width: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox(
                              width: 120,
                              child: ColoredBox(
                                color: AppColors.surfaceVariant,
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // Comment count
                const SizedBox(height: 14),
                Row(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 20,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${vm.totalCommentCount}',
                          style: const TextStyle(
                            color: AppColors.textHint,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Divider(height: 28),

                // Comments
                Text('Comments', style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 12),
                if (vm.comments.isEmpty)
                  const Text(
                    'No comments yet. Be the first!',
                    style: TextStyle(color: AppColors.textHint, fontSize: 13),
                  ),
                ...vm.comments.map(
                  (c) => _CommentTile(
                    comment: c,
                    onReply: () async {
                      if (!auth.isLoggedIn) {
                        await showLoginRequiredDialog(ctx);
                        return;
                      }
                      await _showReplyDialog(ctx, vm, c);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Comment input
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: vm.isTogglingLike
                      ? null
                      : () async {
                          if (!auth.isLoggedIn) {
                            await showLoginRequiredDialog(ctx);
                            return;
                          }
                          await _vm.toggleLike(auth.currentUser!.id);
                          if (ctx.mounted && vm.errorMessage != null) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(vm.errorMessage!)),
                            );
                          }
                        },
                  icon: vm.isTogglingLike
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          p.isLikedByCurrentUser
                              ? Icons.favorite_rounded
                              : Icons.favorite_outline_rounded,
                          color: p.isLikedByCurrentUser
                              ? AppColors.error
                              : null,
                        ),
                  label: Text(
                    '${p.isLikedByCurrentUser ? 'Unlike' : 'Like'} · ${p.likeCount}',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              !auth.isLoggedIn
                  ? GestureDetector(
                      onTap: () => showLoginRequiredDialog(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 16,
                              color: AppColors.textHint,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Login to comment',
                              style: TextStyle(
                                color: AppColors.textHint,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Write a comment...',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: vm.isSubmittingComment
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  color: AppColors.primary,
                                ),
                          onPressed: vm.isSubmittingComment
                              ? null
                              : () async {
                                  final text = _commentCtrl.text.trim();
                                  if (text.isEmpty) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Comment cannot be empty.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  final ok = await _vm.submitComment(
                                    widget.postId,
                                    text,
                                    null,
                                  );
                                  if (ok) {
                                    _commentCtrl.clear();
                                  } else if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          vm.errorMessage ??
                                              'Comment could not be posted.',
                                        ),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                },
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showReplyDialog(
    BuildContext context,
    PostDetailViewModel vm,
    CommunityCommentModel parent,
  ) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Reply to ${parent.authorName}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Write a reply...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reply cannot be empty.')),
                );
                return;
              }
              final ok = await vm.submitComment(widget.postId, text, parent.id);
              if (!dialogContext.mounted) return;
              if (ok) {
                Navigator.pop(dialogContext);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(vm.errorMessage ?? 'Reply failed.')),
                );
              }
            },
            child: const Text('Reply'),
          ),
        ],
      ),
    );
    controller.dispose();
  }
}

class _CommentTile extends StatelessWidget {
  final CommunityCommentModel comment;
  final VoidCallback? onReply;
  const _CommentTile({required this.comment, this.onReply});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                backgroundImage: comment.authorAvatarUrl == null
                    ? null
                    : NetworkImage(comment.authorAvatarUrl!),
                child: comment.authorAvatarUrl == null
                    ? Text(
                        comment.authorName[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            comment.authorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            comment.timeAgo,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        comment.body,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (comment.parentCommentId == null && onReply != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: onReply,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(48, 30),
                            ),
                            child: const Text('Reply'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Replies
          ...comment.replies.map(
            (r) => Padding(
              padding: const EdgeInsets.only(left: 42, top: 6),
              child: _CommentTile(comment: r),
            ),
          ),
        ],
      ),
    );
  }
}
