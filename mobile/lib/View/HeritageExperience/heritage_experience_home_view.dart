import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_routes.dart';
import '../../core/constants.dart';
import '../../ViewModel/HeritageExperience/heritage_experience_view_model.dart';
import '../../ViewModel/AccountManagement/auth_view_model.dart';
import '../Widgets/app_bottom_nav.dart';
import '../Widgets/map_home_button.dart';
import '../Widgets/tiffin_card.dart';
import '../Widgets/loading_widget.dart';
import '../Widgets/empty_state_widget.dart';
import '../Widgets/error_state_widget.dart';

/// Shared green-and-yellow visual language for the Experience landing page.
abstract final class _ExperiencePageColors {
  static const Color background = Color(0xFFFFFFFF);
  static const Color softBackground = Color(0xFFF5F7F3);
  static const Color searchField = Color(0xFFEEF3EC);
  static const Color border = Color(0xFFCCD6C8);
  static const Color darkGreen = Color(0xFF335C31);
  static const Color mediumGreen = Color(0xFF61885B);
  static const Color yellow = Color(0xFFF9B10E);
  static const Color selectedTab = Color(0xFFFEF5E4);
  static const Color text = Color(0xFF283427);
}

/// B1. Heritage Experience Home View.
class HeritageExperienceHomeView extends StatefulWidget {
  const HeritageExperienceHomeView({super.key});

  @override
  State<HeritageExperienceHomeView> createState() =>
      _HeritageExperienceHomeViewState();
}

class _HeritageExperienceHomeViewState
    extends State<HeritageExperienceHomeView> {
  late final HeritageExperienceViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = HeritageExperienceViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthViewModel>();
      _vm.loadTiffins(userId: auth.isLoggedIn ? auth.currentUser?.id : null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer2<HeritageExperienceViewModel, AuthViewModel>(
        builder: (ctx, vm, auth, _) => MapBackScope(
          child: Scaffold(
            backgroundColor: _ExperiencePageColors.background,
            appBar: AppBar(
              backgroundColor: _ExperiencePageColors.background,
              foregroundColor: _ExperiencePageColors.darkGreen,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: const Text(
                'Heritage Experience',
                style: TextStyle(
                  color: _ExperiencePageColors.darkGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
              leading: const MapHomeButton(color: _ExperiencePageColors.darkGreen),
              actions: [
                if (auth.isLoggedIn)
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    tooltip: 'Scan QR',
                    onPressed: () =>
                        Navigator.pushNamed(ctx, AppRoutes.qrScanner),
                  ),
              ],
            ),
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: vm.isLoading
                  ? const LoadingWidget(
                      key: ValueKey('loading'),
                      itemCount: 6,
                      useGrid: true,
                    )
                  : vm.hasError
                  ? ErrorStateWidget(
                      key: const ValueKey('error'),
                      message:
                          vm.errorMessage ??
                          'Your collection could not be loaded.',
                      onRetry: () => _vm.retry(
                        userId: auth.isLoggedIn ? auth.currentUser?.id : null,
                      ),
                    )
                  : RefreshIndicator(
                      key: const ValueKey('content'),
                      onRefresh: () => _vm.loadTiffins(
                        userId: auth.isLoggedIn ? auth.currentUser?.id : null,
                        showLoading: false,
                      ),
                      child: _buildBody(ctx, vm, auth),
                    ),
            ),
            bottomNavigationBar: const AppBottomNav(
              selectedIndex: 0,
              backgroundColor: _ExperiencePageColors.background,
              selectedColor: _ExperiencePageColors.yellow,
              unselectedColor: _ExperiencePageColors.mediumGreen,
              selectedBackgroundColor: _ExperiencePageColors.selectedTab,
            ),
            floatingActionButton: auth.isLoggedIn
                ? FloatingActionButton.extended(
                    onPressed: () =>
                        Navigator.pushNamed(ctx, AppRoutes.qrScanner),
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('Scan QR'),
                    backgroundColor: _ExperiencePageColors.darkGreen,
                    foregroundColor: Colors.white,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext ctx,
    HeritageExperienceViewModel vm,
    AuthViewModel auth,
  ) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              // Collection progress section
              _buildProgressSection(ctx, vm, auth),

              // State filter
              _buildStateFilter(ctx, vm),

              // Section label
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Text(
                      'Heritage Tiffins',
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        color: _ExperiencePageColors.darkGreen,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${vm.tiffins.length} editions',
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: _ExperiencePageColors.darkGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tiffin grid
        vm.isEmpty
            ? SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateWidget(
                  icon: Icons.kitchen_outlined,
                  title: auth.isLoggedIn
                      ? 'No collected tiffins yet'
                      : 'Log in to view your collection',
                  subtitle: auth.isLoggedIn
                      ? vm.selectedState == 'All States'
                            ? 'Scan a participating tiffin QR code to begin your heritage collection.'
                            : 'You have not collected a tiffin from this state.'
                      : 'Your collected heritage tiffins will appear here.',
                  actionLabel: auth.isLoggedIn
                      ? vm.selectedState == 'All States'
                            ? null
                            : 'Show All'
                      : 'Login',
                  onAction: auth.isLoggedIn
                      ? vm.selectedState == 'All States'
                            ? null
                            : () => _vm.setStateFilter('All States')
                      : () => Navigator.pushNamed(ctx, AppRoutes.login),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate((_, i) {
                    final t = vm.tiffins[i];
                    return TiffinCard(
                      tiffin: t,
                      primaryColor: _ExperiencePageColors.darkGreen,
                      mutedColor: _ExperiencePageColors.mediumGreen,
                      borderColor: _ExperiencePageColors.border,
                      backgroundAsset: i % 3 == 1 || i % 3 == 2
                          ? 'asset/image/tiffin_background_yellow.png'
                          : 'asset/image/tiffin_background_green.png',
                      onTap: () => Navigator.pushNamed(
                        ctx,
                        AppRoutes.tiffinExperience,
                        arguments: t.id,
                      ),
                    );
                  }, childCount: vm.tiffins.length),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 268,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildProgressSection(
    BuildContext ctx,
    HeritageExperienceViewModel vm,
    AuthViewModel auth,
  ) {
    if (!auth.isLoggedIn) {
      return _GuestPromptBanner(
        onLogin: () => Navigator.pushNamed(ctx, AppRoutes.login),
      );
    }
    final progress = vm.totalCount > 0
        ? vm.collectedCount / vm.totalCount
        : 0.0;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _ExperiencePageColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ExperiencePageColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(24),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Progress ring
          SizedBox(
            width: 124,
            height: 124,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 7,
                  backgroundColor: _ExperiencePageColors.softBackground,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    _ExperiencePageColors.yellow,
                  ),
                ),
                SizedBox(
                  width: 104,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${vm.collectedCount} / ${vm.totalCount}',
                      style: const TextStyle(
                        color: _ExperiencePageColors.darkGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Collection',
                  style: const TextStyle(
                    color: _ExperiencePageColors.darkGreen,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You\'ve collected ${vm.collectedCount} of ${vm.totalCount} tiffins.',
                  style: TextStyle(
                    color: _ExperiencePageColors.darkGreen,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: _ExperiencePageColors.searchField,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    _ExperiencePageColors.yellow,
                  ),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateFilter(BuildContext ctx, HeritageExperienceViewModel vm) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: AppConstants.malaysianStates
            .take(8)
            .map(
              (state) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(state, style: const TextStyle(fontSize: 12)),
                  selected: vm.selectedState == state,
                  onSelected: (_) => _vm.setStateFilter(state),
                  backgroundColor: _ExperiencePageColors.background,
                  selectedColor: _ExperiencePageColors.selectedTab,
                  side: BorderSide(
                    color: vm.selectedState == state
                        ? _ExperiencePageColors.yellow
                        : _ExperiencePageColors.mediumGreen,
                  ),
                  labelStyle: TextStyle(
                    color: vm.selectedState == state
                        ? _ExperiencePageColors.yellow
                        : _ExperiencePageColors.mediumGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _GuestPromptBanner extends StatelessWidget {
  final VoidCallback onLogin;
  const _GuestPromptBanner({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ExperiencePageColors.softBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ExperiencePageColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            color: _ExperiencePageColors.yellow,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Track Your Collection',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: _ExperiencePageColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Login to collect tiffins and track your progress.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onLogin,
            child: const Text(
              'Login',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
