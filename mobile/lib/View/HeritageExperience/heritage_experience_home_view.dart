import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
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
import '../Widgets/login_required_dialog.dart';

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
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Heritage Experience'),
              leading: const MapHomeButton(),
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
            bottomNavigationBar: const AppBottomNav(selectedIndex: 0),
            floatingActionButton: auth.isLoggedIn
                ? FloatingActionButton.extended(
                    onPressed: () =>
                        Navigator.pushNamed(ctx, AppRoutes.qrScanner),
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('Scan QR'),
                    backgroundColor: AppColors.primary,
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
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      '${vm.tiffins.length} editions',
                      style: Theme.of(ctx).textTheme.bodySmall,
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
                      : () => showLoginRequiredDialog(ctx),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate((_, i) {
                    final t = vm.tiffins[i];
                    return TiffinCard(
                      tiffin: t,
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
                    childAspectRatio: 0.75,
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
        onLogin: () async {
          await showLoginRequiredDialog(ctx);
        },
      );
    }
    final progress = vm.totalCount > 0
        ? vm.collectedCount / vm.totalCount
        : 0.0;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(100),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Progress ring
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withAlpha(60),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.accent,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${vm.collectedCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '/ ${vm.totalCount}',
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 10,
                      ),
                    ),
                  ],
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
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You\'ve collected ${vm.collectedCount} of ${vm.totalCount} tiffins.',
                  style: TextStyle(
                    color: Colors.white.withAlpha(220),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withAlpha(40),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.accent,
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
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: vm.selectedState == state
                        ? Colors.white
                        : AppColors.textSecondary,
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
        color: AppColors.accentContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.accentDark,
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
                    color: AppColors.textPrimary,
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
