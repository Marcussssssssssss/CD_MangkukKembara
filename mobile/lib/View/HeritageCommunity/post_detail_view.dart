import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Repositories/HeritageCommunity/community_comment_model.dart';
import '../../ViewModel/AccountManagement/auth_view_model.dart';
import '../../ViewModel/HeritageCommunity/post_detail_view_model.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../Widgets/app_network_image.dart';
import '../Widgets/error_state_widget.dart';
import '../Widgets/loading_widget.dart';
import '../Widgets/rating_bar.dart';

/// C3. Community Post Details View.
class PostDetailView extends StatefulWidget {
  final String postId;

  const PostDetailView({super.key, required this.postId});

  @override
  State<PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends State<PostDetailView> {
  late final PostDetailViewModel _vm;
  final _scrollController = ScrollController();
  final _commentsKey = GlobalKey();
  int _photoIndex = 0;

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
    _scrollController.dispose();
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer2<PostDetailViewModel, AuthViewModel>(
        builder: (context, vm, auth, _) => Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(title: const Text('Post')),
          body: vm.isLoading
              ? const LoadingSpinner()
              : vm.hasError || vm.post == null
              ? ErrorStateWidget(onRetry: () => vm.retry(widget.postId))
              : RefreshIndicator(
                  onRefresh: () =>
                      vm.loadPost(widget.postId, showLoading: false),
                  child: _buildContent(context, vm, auth),
                ),
          bottomNavigationBar: vm.post == null || vm.isLoading
              ? null
              : _buildBottomBar(context, vm, auth),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    PostDetailViewModel vm,
    AuthViewModel auth,
  ) {
    final post = vm.post!;
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Avatar(
                      name: post.authorName,
                      imageUrl: post.authorAvatarUrl,
                      radius: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorName,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            post.timeAgo,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    RatingBar(rating: post.vendorRating, size: 17),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
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
                        size: 15,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        [
                          post.vendorName,
                          post.vendorState,
                        ].where((value) => value.isNotEmpty).join(' · '),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (post.photoUrls.isNotEmpty) _buildPhotoCarousel(post.photoUrls),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
            child: Text(
              post.reviewText,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.55),
            ),
          ),
          const Divider(thickness: 8, color: AppColors.surfaceVariant),
          Padding(
            key: _commentsKey,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Row(
              children: [
                Text(
                  'Comments',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                Text(
                  '${vm.totalCommentCount}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppColors.textHint),
                ),
              ],
            ),
          ),
          if (vm.comments.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Text(
                'No comments yet. Be the first!',
                style: TextStyle(color: AppColors.textHint, fontSize: 13),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: vm.comments
                    .map(
                      (comment) => _CommentTile(
                        comment: comment,
                        onReply: () => _startReply(context, vm, auth, comment),
                      ),
                    )
                    .toList(),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPhotoCarousel(List<String> photoUrls) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: PageView.builder(
            itemCount: photoUrls.length,
            onPageChanged: (index) => setState(() => _photoIndex = index),
            itemBuilder: (context, index) => ColoredBox(
              color: AppColors.surfaceVariant,
              child: AppNetworkImage(
                imageUrl: photoUrls[index],
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                targetOptimizationWidth: 1200,
              ),
            ),
          ),
        ),
        if (photoUrls.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                photoUrls.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: index == _photoIndex ? 18 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: index == _photoIndex
                        ? AppColors.primary
                        : AppColors.divider,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    PostDetailViewModel vm,
    AuthViewModel auth,
  ) {
    final post = vm.post!;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  readOnly: true,
                  enableInteractiveSelection: false,
                  onTap: () => _startComment(context, vm, auth),
                  decoration: InputDecoration(
                    hintText: auth.isLoggedIn
                        ? 'Say something...'
                        : 'Login to comment',
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _BottomAction(
                tooltip: post.isLikedByCurrentUser ? 'Unlike' : 'Like',
                icon: post.isLikedByCurrentUser
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: post.isLikedByCurrentUser
                    ? AppColors.error
                    : AppColors.textPrimary,
                count: post.likeCount,
                busy: vm.isTogglingLike,
                onPressed: () => _toggleLike(context, vm, auth),
              ),
              _BottomAction(
                tooltip: 'Go to comments',
                icon: Icons.chat_bubble_outline_rounded,
                count: vm.totalCommentCount,
                onPressed: _scrollToComments,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleLike(
    BuildContext context,
    PostDetailViewModel vm,
    AuthViewModel auth,
  ) async {
    if (!auth.isLoggedIn) {
      await Navigator.pushNamed(context, AppRoutes.login);
      return;
    }
    await vm.toggleLike(auth.currentUser!.id);
    if (mounted && vm.errorMessage != null) {
      _showError(vm.errorMessage!);
    }
  }

  Future<void> _startComment(
    BuildContext context,
    PostDetailViewModel vm,
    AuthViewModel auth,
  ) async {
    if (!auth.isLoggedIn) {
      await Navigator.pushNamed(context, AppRoutes.login);
      return;
    }
    final commented = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => _TextComposerSheet(
        label: 'Add a comment',
        hintText: 'Say something...',
        sendTooltip: 'Send comment',
        onSubmit: (text) => vm.submitComment(widget.postId, text, null),
        errorMessage: () => vm.errorMessage,
      ),
    );
    if (commented == true && mounted) _scrollToComments();
  }

  Future<void> _startReply(
    BuildContext context,
    PostDetailViewModel vm,
    AuthViewModel auth,
    CommunityCommentModel parent,
  ) async {
    if (!auth.isLoggedIn) {
      await Navigator.pushNamed(context, AppRoutes.login);
      return;
    }
    final replied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => _TextComposerSheet(
        label: 'Reply to ${parent.authorName}',
        hintText: 'Reply to ${parent.authorName}',
        sendTooltip: 'Send reply',
        onSubmit: (text) => vm.submitComment(widget.postId, text, parent.id),
        errorMessage: () => vm.errorMessage,
      ),
    );
    if (replied == true && mounted) _scrollToComments();
  }

  void _scrollToComments() {
    final commentsContext = _commentsKey.currentContext;
    if (commentsContext == null) return;
    Scrollable.ensureVisible(
      commentsContext,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final int count;
  final VoidCallback onPressed;
  final Color color;
  final bool busy;

  const _BottomAction({
    required this.tooltip,
    required this.icon,
    required this.count,
    required this.onPressed,
    this.color = AppColors.textPrimary,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: busy ? null : onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(icon, size: 24, color: color),
            Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommunityCommentModel comment;
  final VoidCallback? onReply;

  const _CommentTile({required this.comment, this.onReply});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(
                name: comment.authorName,
                imageUrl: comment.authorAvatarUrl,
                radius: 17,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.authorName,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      comment.body,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          comment.timeAgo,
                          style: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 11,
                          ),
                        ),
                        if (onReply != null) ...[
                          const SizedBox(width: 14),
                          GestureDetector(
                            onTap: onReply,
                            child: const Text(
                              'Reply',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 14),
              child: Column(
                children: comment.replies
                    .map((reply) => _CommentTile(comment: reply))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double radius;

  const _Avatar({
    required this.name,
    required this.imageUrl,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary,
      backgroundImage: imageUrl == null ? null : NetworkImage(imageUrl!),
      child: imageUrl == null
          ? Text(
              initial,
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * .72,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }
}

class _TextComposerSheet extends StatefulWidget {
  final String label;
  final String hintText;
  final String sendTooltip;
  final Future<bool> Function(String text) onSubmit;
  final String? Function() errorMessage;

  const _TextComposerSheet({
    required this.label,
    required this.hintText,
    required this.sendTooltip,
    required this.onSubmit,
    required this.errorMessage,
  });

  @override
  State<_TextComposerSheet> createState() => _TextComposerSheetState();
}

class _TextComposerSheetState extends State<_TextComposerSheet> {
  final _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    final succeeded = await widget.onSubmit(text);
    if (!mounted) return;
    if (succeeded) {
      Navigator.pop(context, true);
      return;
    }
    setState(() => _isSending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.errorMessage() ?? 'Message could not be posted.'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.label,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: AppColors.textHint),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                autofocus: true,
                maxLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  suffixIconConstraints: const BoxConstraints(minWidth: 48),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_controller.text.isNotEmpty)
                        IconButton(
                          tooltip: 'Clear text',
                          onPressed: _isSending
                              ? null
                              : () {
                                  _controller.clear();
                                  setState(() {});
                                },
                          icon: const Icon(Icons.close_rounded, size: 20),
                        ),
                      IconButton(
                        tooltip: widget.sendTooltip,
                        onPressed: _controller.text.trim().isEmpty || _isSending
                            ? null
                            : _send,
                        icon: _isSending
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
