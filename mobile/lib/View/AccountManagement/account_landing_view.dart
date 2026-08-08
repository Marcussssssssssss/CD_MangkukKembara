import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../ViewModel/AccountManagement/auth_view_model.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../Widgets/auth_branding.dart';
import '../Widgets/map_home_button.dart';

/// Logged-out account landing page.
class AccountLandingView extends StatelessWidget {
  const AccountLandingView({super.key});

  @override
  Widget build(BuildContext context) {
    return MapBackScope(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Consumer<AuthViewModel>(
          builder: (ctx, auth, _) {
            if (auth.isLoggedIn) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => Navigator.pushReplacementNamed(
                  ctx,
                  AppRoutes.treasureMap,
                ),
              );
              return const SizedBox.shrink();
            }
            return LayoutBuilder(
              builder: (context, constraints) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: constraints.maxWidth - 48,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const AuthBranding(
                            subtitle: 'Malaysia Heritage Food Experience',
                          ),
                          const SizedBox(height: 24),
                          const _BenefitRow(
                            Icons.kitchen_rounded,
                            'Collect Heritage Tiffins',
                            'Scan QR codes at participating vendors to build your collection.',
                          ),
                          const _BenefitRow(
                            Icons.auto_stories_rounded,
                            'Access Exclusive Stories',
                            'Unlock rich heritage stories, videos, and artwork for each tiffin.',
                          ),
                          const _BenefitRow(
                            Icons.forum_rounded,
                            'Join the Community',
                            'Share reviews, photos, and experiences with heritage food lovers.',
                          ),
                          const _BenefitRow(
                            Icons.brush_rounded,
                            'Participate in Art Campaigns',
                            'Submit and vote for artwork to appear on future tiffin editions.',
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () =>
                                  Navigator.pushNamed(ctx, AppRoutes.login),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.pushNamed(ctx, AppRoutes.register),
                              child: const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _BenefitRow(this.icon, this.title, this.desc);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.4,
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
