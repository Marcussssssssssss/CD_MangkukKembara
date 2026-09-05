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

/// Account-page palette matching the refreshed green visual system.
abstract final class _ProfilePageColors {
  static const Color background = Color(0xFFFFFFFF);
  static const Color softBackground = Color(0xFFF5F7F3);
  static const Color border = Color(0xFFCCD6C8);
  static const Color darkGreen = Color(0xFF335C31);
  static const Color mediumGreen = Color(0xFF61885B);
  static const Color yellow = Color(0xFFF9B10E);
  static const Color selectedTab = Color(0xFFFEF5E4);
  static const Color text = Color(0xFF283427);
}

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
        Navigator.pushReplacementNamed(context, AppRoutes.accountLanding);
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
                  Navigator.pushReplacementNamed(ctx, AppRoutes.accountLanding),
            );
            return const Scaffold(body: LoadingSpinner());
          }
          return MapBackScope(
            child: Scaffold(
              backgroundColor: _ProfilePageColors.background,
              appBar: AppBar(
                backgroundColor: _ProfilePageColors.background,
                foregroundColor: _ProfilePageColors.darkGreen,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                title: const Text(
                  'My Account',
                  style: TextStyle(
                    color: _ProfilePageColors.darkGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                leading: const MapHomeButton(color: _ProfilePageColors.darkGreen),
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
              bottomNavigationBar: const AppBottomNav(
                selectedIndex: 2,
                backgroundColor: _ProfilePageColors.background,
                selectedColor: _ProfilePageColors.yellow,
                unselectedColor: _ProfilePageColors.mediumGreen,
                selectedBackgroundColor: _ProfilePageColors.selectedTab,
              ),
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
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: _ProfilePageColors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _ProfilePageColors.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 14),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: .75,
                        child: Image.asset(
                          'asset/image/profile_background_green.png',
                          fit: BoxFit.cover,
                          alignment: Alignment.topRight,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: _ProfilePageColors.yellow,
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
                                      color: _ProfilePageColors.darkGreen,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 32,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p?.displayName ?? auth.displayName,
                                  style: const TextStyle(
                                    color: _ProfilePageColors.darkGreen,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  auth.currentUser?.email ?? '',
                                  style: const TextStyle(
                                    color: _ProfilePageColors.text,
                                    fontSize: 14,
                                  ),
                                ),
                                if (p?.city != null || p?.country != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    '${p?.city ?? ''}${p?.city != null && p?.country != null ? ', ' : ''}${p?.country ?? ''}',
                                    style: const TextStyle(
                                      color: _ProfilePageColors.mediumGreen,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Divider(color: _ProfilePageColors.border),
                      ),
                      Row(
                        children: [
                          _Stat(label: 'Tiffins\nCollected', value: '${vm.collectedCount}'),
                          const _StatDivider(),
                          _Stat(label: 'Reviews\nPosted', value: '${vm.postCount}'),
                          const _StatDivider(),
                          _Stat(
                            label: 'Artworks\nSubmitted',
                            value: '${vm.submissionCount}',
                          ),
                        ],
                      ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _MenuCard(
              children: [
                _MenuItem(Icons.rate_review_rounded, 'My Reviews', () => Navigator.pushNamed(ctx, AppRoutes.myReviews)),
                _MenuItem(Icons.brush_rounded, 'My Artwork Submissions', () => Navigator.pushNamed(ctx, AppRoutes.myArtworkSubmissions)),
                _MenuItem(Icons.edit_rounded, 'Edit Profile', () async {
                  await Navigator.pushNamed(ctx, AppRoutes.editProfile);
                  if (ctx.mounted && auth.currentUser != null) {
                    await _profileVm.loadProfile(
                      auth.currentUser!.id,
                      showLoading: false,
                    );
                  }
                }),
                _MenuItem(Icons.lock_outline_rounded, 'Change Password', () => Navigator.pushNamed(ctx, AppRoutes.changePassword)),
                _MenuItem(Icons.logout_rounded, 'Logout', () async {
                  try {
                    await auth.logout();
                    if (ctx.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        ctx,
                        AppRoutes.accountLanding,
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
              color: _ProfilePageColors.darkGreen,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _ProfilePageColors.text,
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _ProfilePageColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ProfilePageColors.border),
      ),
      child: Column(
        children: children
            .asMap()
            .entries
            .map(
              (e) => Column(
                children: [
                  e.value,
                  if (e.key < children.length - 1)
                    const Divider(
                      height: 1,
                      indent: 68,
                      endIndent: 16,
                      color: _ProfilePageColors.border,
                    ),
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
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _ProfilePageColors.softBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: _ProfilePageColors.darkGreen),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: _ProfilePageColors.text,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: _ProfilePageColors.mediumGreen,
      ),
      onTap: onTap,
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 62,
    child: VerticalDivider(color: _ProfilePageColors.border),
  );
}
