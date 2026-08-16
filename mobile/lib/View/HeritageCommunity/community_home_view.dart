import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../ViewModel/AccountManagement/auth_view_model.dart';
import '../../ViewModel/HeritageCommunity/community_feed_view_model.dart';
import '../../core/app_routes.dart';
import '../Widgets/app_bottom_nav.dart';
import '../Widgets/empty_state_widget.dart';
import '../Widgets/error_state_widget.dart';
import '../Widgets/loading_widget.dart';
import '../Widgets/map_home_button.dart';
import '../Widgets/post_card.dart';
import 'artwork_campaign_home_view.dart';

/// Map-inspired palette used only by the Community landing page.
abstract final class _CommunityPageColors {
  static const Color background = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFCCD6C8);
  static const Color darkGreen = Color(0xFF335C31);
  static const Color mediumGreen = Color(0xFF61885B);
  static const Color yellow = Color(0xFFF9B10E);
  static const Color selectedTab = Color(0xFFFEF5E4);
}

/// C1. Heritage Community and artwork campaigns home view.
class CommunityHomeView extends StatefulWidget {
  const CommunityHomeView({super.key});

  @override
  State<CommunityHomeView> createState() => _CommunityHomeViewState();
}

class _CommunityHomeViewState extends State<CommunityHomeView> {
  late final CommunityFeedViewModel _vm;
  final _pageController = PageController();
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _vm = CommunityFeedViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) => _vm.loadPosts());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (_selectedTab == index) return;
    setState(() => _selectedTab = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer2<CommunityFeedViewModel, AuthViewModel>(
        builder: (ctx, vm, auth, _) => MapBackScope(
          child: Scaffold(
            backgroundColor: _CommunityPageColors.background,
            appBar: AppBar(
              backgroundColor: _CommunityPageColors.background,
              foregroundColor: _CommunityPageColors.darkGreen,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: const Text(
                'Heritage Community',
                style: TextStyle(
                  color: _CommunityPageColors.darkGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
              leading: const MapHomeButton(color: _CommunityPageColors.darkGreen),
            ),
            body: Column(
              children: [
                _CommunityTabs(
                  selectedIndex: _selectedTab,
                  onSelected: _selectTab,
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      if (_selectedTab != index) {
                        setState(() => _selectedTab = index);
                      }
                    },
                    children: [
                      _buildCommunityPage(ctx, vm, auth),
                      const ArtworkCampaignPanel(),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: _selectedTab == 0
                ? FloatingActionButton.extended(
                    onPressed: () async {
                      if (!auth.isLoggedIn) {
                        await Navigator.pushNamed(ctx, AppRoutes.login);
                        return;
                      }
                      if (ctx.mounted) {
                        await Navigator.pushNamed(ctx, AppRoutes.createPost);
                        if (ctx.mounted) {
                          await vm.loadPosts(showLoading: false);
                        }
                      }
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create Post'),
                    backgroundColor: _CommunityPageColors.darkGreen,
                    foregroundColor: Colors.white,
                  )
                : null,
            bottomNavigationBar: const AppBottomNav(
              selectedIndex: 1,
              backgroundColor: _CommunityPageColors.background,
              selectedColor: _CommunityPageColors.yellow,
              unselectedColor: _CommunityPageColors.mediumGreen,
              selectedBackgroundColor: _CommunityPageColors.selectedTab,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityPage(
    BuildContext context,
    CommunityFeedViewModel vm,
    AuthViewModel auth,
  ) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: ['Popular', 'New']
                .map(
                  (sort) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(sort, style: const TextStyle(fontSize: 12)),
                      selected: vm.sort == sort,
                      onSelected: (_) => vm.setSort(sort),
                      selectedColor: _CommunityPageColors.selectedTab,
                      labelStyle: TextStyle(
                        color: vm.sort == sort
                            ? _CommunityPageColors.yellow
                            : _CommunityPageColors.mediumGreen,
                        fontWeight: FontWeight.w600,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Expanded(
          child: vm.isLoading
              ? const LoadingWidget()
              : vm.hasError
              ? ErrorStateWidget(
                  message:
                      vm.errorMessage ?? 'Community posts could not be loaded.',
                  onRetry: vm.retry,
                )
              : vm.isEmpty
              ? RefreshableStateView(
                  onRefresh: () => vm.loadPosts(showLoading: false),
                  child: const EmptyStateWidget(
                    icon: Icons.forum_outlined,
                    title: 'No posts yet',
                    subtitle:
                        'Be the first to share your heritage food experience.',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => vm.loadPosts(showLoading: false),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: vm.posts.length,
                    itemBuilder: (_, index) {
                      final post = vm.posts[index];
                      return PostCard(
                        post: post,
                        isLoggedIn: auth.isLoggedIn,
                        primaryColor: _CommunityPageColors.darkGreen,
                        mutedColor: _CommunityPageColors.mediumGreen,
                        ratingColor: _CommunityPageColors.yellow,
                        borderColor: _CommunityPageColors.border,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.postDetail,
                          arguments: post.id,
                        ),
                        onLike: () async {
                          if (!auth.isLoggedIn) {
                            await Navigator.pushNamed(context, AppRoutes.login);
                            return;
                          }
                          vm.toggleLike(
                            post.id,
                            auth.currentUser!.id,
                            post.isLikedByCurrentUser,
                          );
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _CommunityTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _CommunityTabs({required this.selectedIndex, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const labels = ['Heritage Community', 'Heritage Artwork Campaigns'];
    const icons = [Icons.forum_rounded, Icons.palette_rounded];
    return Material(
      color: _CommunityPageColors.background,
      elevation: 2,
      child: Column(
        children: [
          Row(
            children: List.generate(
              labels.length,
              (index) => Expanded(
                child: InkWell(
                  onTap: () => onSelected(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 13,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icons[index],
                          size: 18,
                          color: selectedIndex == index
                              ? _CommunityPageColors.darkGreen
                              : _CommunityPageColors.mediumGreen,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            labels[index],
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selectedIndex == index
                                  ? _CommunityPageColors.darkGreen
                                  : _CommunityPageColors.mediumGreen,
                              fontSize: 12,
                              fontWeight: selectedIndex == index
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                const Divider(height: 2),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOutCubic,
                  left: selectedIndex * constraints.maxWidth / 2,
                  bottom: 0,
                  child: Container(
                    width: constraints.maxWidth / 2,
                    height: 3,
                    color: _CommunityPageColors.yellow,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
