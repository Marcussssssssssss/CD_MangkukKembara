import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../ViewModel/AccountManagement/auth_view_model.dart';

/// Persistent bottom navigation bar with 3 module items.
/// [selectedIndex]: -1 = on map (none selected), 0 = Experience, 1 = Community, 2 = Account
class AppBottomNav extends StatelessWidget {
  final int selectedIndex;

  const AppBottomNav({super.key, this.selectedIndex = -1});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.auto_awesome,
                label: 'Experience',
                selected: selectedIndex == 0,
                onTap: selectedIndex == 0
                    ? null
                    : () => _navigate(context, AppRoutes.heritageExperience, 0),
              ),
              _NavItem(
                icon: Icons.people_alt_rounded,
                label: 'Community',
                selected: selectedIndex == 1,
                onTap: selectedIndex == 1
                    ? null
                    : () => _navigate(context, AppRoutes.community, 1),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Account',
                selected: selectedIndex == 2,
                onTap: selectedIndex == 2
                    ? null
                    : () => _navigateAccount(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String route, int tabIndex) {
    final current = ModalRoute.of(context)?.settings.name;
    if (current == route) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      route,
      (candidate) => candidate.settings.name == AppRoutes.treasureMap,
      arguments: BottomTabTransition(tabIndex),
    );
  }

  void _navigateAccount(BuildContext context) {
    // The account view decides whether to show guest or profile based on auth state
    final current = ModalRoute.of(context)?.settings.name;
    if (current == AppRoutes.profile || current == AppRoutes.guestAccount) {
      return;
    }
    final auth = context.read<AuthViewModel>();
    _navigate(
      context,
      auth.isLoggedIn ? AppRoutes.profile : AppRoutes.guestAccount,
      2,
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.navSelected : AppColors.navUnselected;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.navSelected.withAlpha(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: selected
                  ? BoxDecoration(
                      color: AppColors.navSelected.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                    )
                  : null,
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
