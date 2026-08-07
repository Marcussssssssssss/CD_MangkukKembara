import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../ViewModel/AccountManagement/auth_view_model.dart';
import '../../ViewModel/AccountManagement/profile_view_model.dart';
import '../Widgets/app_bottom_nav.dart';
import '../Widgets/map_home_button.dart';
import '../Widgets/loading_widget.dart';
import '../Widgets/error_state_widget.dart';

/// D1. Account Profile View (logged-in user).
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final ProfileViewModel _profileVm;

  @override
  void initState() {
    super.initState();
    _profileVm = ProfileViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthViewModel>();
      if (auth.isLoggedIn && auth.currentUser != null) {
        _profileVm.loadProfile(auth.currentUser!.id);
      } else {
        // Guest — redirect to guest view
        Navigator.pushReplacementNamed(context, AppRoutes.guestAccount);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _profileVm,
      child: Consumer2<ProfileViewModel, AuthViewModel>(
        builder: (ctx, vm, auth, _) {
          if (!auth.isLoggedIn) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) =>
                  Navigator.pushReplacementNamed(ctx, AppRoutes.guestAccount),
            );
            return const Scaffold(body: LoadingSpinner());
          }
          return MapBackScope(
            child: Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: const Text('My Account'),
                leading: const MapHomeButton(),
              ),
              body: vm.isLoading
                  ? const LoadingSpinner()
                  : vm.errorMessage != null
                  ? ErrorStateWidget(
                      message: vm.errorMessage!,
                      onRetry: () =>
                          _profileVm.loadProfile(auth.currentUser!.id),
                    )
                  : _buildContent(ctx, vm, auth),
              bottomNavigationBar: const AppBottomNav(selectedIndex: 2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext ctx,
    ProfileViewModel vm,
    AuthViewModel auth,
  ) {
    final p = vm.profile;
    return RefreshIndicator(
      onRefresh: () => vm.loadProfile(auth.currentUser!.id, showLoading: false),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Profile header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.accent,
                    backgroundImage: p?.avatarUrl == null
                        ? null
                        : NetworkImage(p!.avatarUrl!),
                    child: p?.avatarUrl == null
                        ? Text(
                            (p?.displayName ?? auth.displayName).isNotEmpty
                                ? (p?.displayName ?? auth.displayName)[0]
                                      .toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 32,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    p?.displayName ?? auth.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    auth.currentUser?.email ?? '',
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (p?.city != null || p?.country != null)
                    Text(
                      '${p?.city ?? ''}${p?.city != null && p?.country != null ? ', ' : ''}${p?.country ?? ''}',
                      style: TextStyle(
                        color: Colors.white.withAlpha(180),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),

            // Collection stats
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  _Stat(
                    label: 'Tiffins\nCollected',
                    value: '${vm.collectedCount}',
                  ),
                  const VerticalDivider(width: 1),
                  _Stat(label: 'Reviews\nPosted', value: '${vm.postCount}'),
                  const VerticalDivider(width: 1),
                  _Stat(
                    label: 'Artworks\nSubmitted',
                    value: '${vm.submissionCount}',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Menu items
            _MenuCard(
              children: [
                _MenuItem(
                  Icons.rate_review_rounded,
                  'My Reviews',
                  () => Navigator.pushNamed(ctx, AppRoutes.myReviews),
                ),
                _MenuItem(
                  Icons.brush_rounded,
                  'My Artwork Submissions',
                  () => Navigator.pushNamed(
                    ctx,
                    AppRoutes.myArtworkSubmissions,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            _MenuCard(
              children: [
                _MenuItem(
                  Icons.edit_rounded,
                  'Edit Profile',
                  () => Navigator.pushNamed(ctx, AppRoutes.editProfile),
                ),
                _MenuItem(
                  Icons.lock_outline_rounded,
                  'Change Password',
                  () => Navigator.pushNamed(ctx, AppRoutes.changePassword),
                ),
              ],
            ),

            const SizedBox(height: 8),

            _MenuCard(
              children: [
                _MenuItem(Icons.logout_rounded, 'Logout', () async {
                  try {
                    await auth.logout();
                    if (ctx.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        ctx,
                        AppRoutes.guestAccount,
                        (route) => route.settings.name == AppRoutes.treasureMap,
                      );
                    }
                  } catch (error) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text('Logout failed: $error'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                }),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textHint,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<Widget> children;
  const _MenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: children
            .asMap()
            .entries
            .map(
              (e) => Column(
                children: [
                  e.value,
                  if (e.key < children.length - 1)
                    const Divider(height: 1, indent: 56, endIndent: 16),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: AppColors.textHint,
      ),
      onTap: onTap,
    );
  }
}
