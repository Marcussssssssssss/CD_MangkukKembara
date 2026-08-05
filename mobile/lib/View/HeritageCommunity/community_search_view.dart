import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../ViewModel/HeritageCommunity/community_feed_view_model.dart';
import '../../ViewModel/AccountManagement/auth_view_model.dart';
import '../Widgets/post_card.dart';
import '../Widgets/loading_widget.dart';
import '../Widgets/empty_state_widget.dart';
import '../Widgets/error_state_widget.dart';

/// C2. Community Search Result View.
class CommunitySearchView extends StatefulWidget {
  final String initialQuery;
  const CommunitySearchView({super.key, required this.initialQuery});

  @override
  State<CommunitySearchView> createState() => _CommunitySearchViewState();
}

class _CommunitySearchViewState extends State<CommunitySearchView> {
  late final CommunityFeedViewModel _vm;
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _vm = CommunityFeedViewModel();
    _ctrl = TextEditingController(text: widget.initialQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) => _vm.loadPosts());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer2<CommunityFeedViewModel, AuthViewModel>(
        builder: (ctx, vm, auth, _) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: TextField(
              controller: _ctrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: const InputDecoration(
                hintText: 'Search community posts...',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
              ),
              onChanged: _vm.setQuery,
            ),
          ),
          body: Column(
            children: [
              // Result count
              if (!vm.isLoading && !vm.hasError)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      Text(
                        '${vm.posts.length} results for "${_ctrl.text}"',
                        style: Theme.of(ctx).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          _ctrl.clear();
                          _vm.setQuery('');
                        },
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: const Text(
                          'Clear',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: vm.isLoading
                    ? const LoadingWidget()
                    : vm.hasError
                    ? ErrorStateWidget(onRetry: _vm.retry)
                    : vm.isEmpty
                    ? RefreshableStateView(
                        onRefresh: () => vm.loadPosts(showLoading: false),
                        child: const EmptyStateWidget(
                          icon: Icons.search_off_rounded,
                          title: 'No posts found',
                          subtitle: 'Try different search terms.',
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => vm.loadPosts(showLoading: false),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: vm.posts.length,
                          itemBuilder: (_, i) => PostCard(
                            post: vm.posts[i],
                            isLoggedIn: auth.isLoggedIn,
                            onTap: () => Navigator.pushNamed(
                              ctx,
                              AppRoutes.postDetail,
                              arguments: vm.posts[i].id,
                            ),
                          ),
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
