import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

abstract final class HeritageCommunityStyle {
  static const Color background = Color(0xFFF9FBF7);
  static const Color forest = AppColors.primary;
  static const Color gold = AppColors.accent;
  static const Color cream = AppColors.accentContainer;
  static const Color sage = Color(0xFFEEF3EC);
  static const double pagePadding = 16;
  static const double cardRadius = 22;

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x14335C31), blurRadius: 16, offset: Offset(0, 6)),
  ];
}

AppBar heritageCommunityAppBar({
  required String title,
  List<Widget>? actions,
  Widget? leading,
}) {
  return AppBar(
    title: Text(
      title,
      style: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w900,
      ),
    ),
    leading: leading,
    actions: actions,
    backgroundColor: HeritageCommunityStyle.background,
    foregroundColor: AppColors.primary,
    surfaceTintColor: Colors.transparent,
    scrolledUnderElevation: 0,
    elevation: 0,
  );
}

class HeritagePageBanner extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final EdgeInsetsGeometry margin;

  const HeritagePageBanner({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
    this.margin = const EdgeInsets.fromLTRB(16, 10, 16, 18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF416F43), Color(0xFF203F2A)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29335C31),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -22,
            bottom: -30,
            child: Icon(icon, size: 120, color: const Color(0x12FFFFFF)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.accentLight,
                        fontSize: 10,
                        letterSpacing: 1.35,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xDFFFFFFF),
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
        ],
      ),
    );
  }
}

class HeritageSectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const HeritageSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(HeritageCommunityStyle.cardRadius),
        border: Border.all(color: AppColors.divider),
        boxShadow: HeritageCommunityStyle.cardShadow,
      ),
      child: child,
    );
  }
}

class HeritageSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;

  const HeritageSectionTitle({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: HeritageCommunityStyle.cream,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: AppColors.accentDark),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
