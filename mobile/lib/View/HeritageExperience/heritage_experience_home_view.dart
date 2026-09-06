import 'dart:math' as math;
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
  static const Color cream = Color(0xFFF2F8ED);
  static const Color softBackground = Color(0xFFF5F7F3);
  static const Color searchField = Color(0xFFEEF3EC);
  static const Color border = Color(0xFFCCD6C8);
  static const Color darkGreen = Color(0xFF335C31);
  static const Color mediumGreen = Color(0xFF61885B);
  // Bright accent green — used anywhere the old yellow/gold accent was.
  static const Color accentGreen = Color(0xFF7CB342);
  static const Color accentGreenDark = Color(0xFF4C7A3D);
  static const Color selectedTab = Color(0xFFE6F0DE);
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
              selectedColor: _ExperiencePageColors.accentGreen,
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

  /// "Heritage Passport" style collection card. Frames the progress as a set
  /// of stamps being collected, which reads better for a tourist-facing,
  /// gamified feature than a plain percentage ring.
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

    final total = vm.totalCount;
    final collected = vm.collectedCount;
    final isComplete = total > 0 && collected >= total;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: _ExperiencePageColors.cream,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _ExperiencePageColors.border),
        boxShadow: [
          BoxShadow(
            color: _ExperiencePageColors.darkGreen.withAlpha(20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow strip
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
            child: Row(
              children: [
                Icon(
                  Icons.local_dining_rounded,
                  size: 14,
                  color: _ExperiencePageColors.accentGreenDark,
                ),
                const SizedBox(width: 6),
                Text(
                  'HERITAGE PASSPORT',
                  style: TextStyle(
                    color: _ExperiencePageColors.accentGreenDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const Spacer(),
                if (isComplete)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _ExperiencePageColors.darkGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Fully stamped',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _StampRing(collected: collected, total: total, size: 108),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Collection',
                        style: TextStyle(
                          color: _ExperiencePageColors.darkGreen,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Georgia',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isComplete
                            ? 'Every heritage tiffin stamped. You are a true collector.'
                            : 'Scan a tiffin QR to earn your next stamp.',
                        style: const TextStyle(
                          color: _ExperiencePageColors.mediumGreen,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            '$collected',
                            style: const TextStyle(
                              color: _ExperiencePageColors.darkGreen,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            ' / $total stamped',
                            style: const TextStyle(
                              color: _ExperiencePageColors.mediumGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
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
                    ? _ExperiencePageColors.accentGreen
                    : _ExperiencePageColors.mediumGreen,
              ),
              labelStyle: TextStyle(
                color: vm.selectedState == state
                    ? _ExperiencePageColors.accentGreen
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

/// Vector-drawn stacked tiffin carrier icon — dome lid + three tiers with
/// clip-tab rims, matching the reference artwork. Drawn purely in code so
/// there's no PNG asset path or pubspec declaration to get wrong; recolor
/// and resize freely via the constructor.
class _TiffinIcon extends StatelessWidget {
  final double size;
  final Color color;

  const _TiffinIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _TiffinIconPainter(color: color)),
    );
  }
}

class _TiffinIconPainter extends CustomPainter {
  final Color color;

  _TiffinIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    // Dome lid.
    final domeRect = Rect.fromLTRB(w * 0.30, h * 0.02, w * 0.70, h * 0.32);
    canvas.drawArc(domeRect, math.pi, math.pi, false, paint);

    // Three tiers, each with a pill-shaped rim (with a small clip tab)
    // above it.
    final top = h * 0.30;
    final bottom = h * 0.96;
    final unit = (bottom - top) / 3;

    var y = top;
    for (var i = 0; i < 3; i++) {
      final rimHeight = unit * 0.24;
      final rimRect = Rect.fromLTWH(w * 0.14, y, w * 0.72, rimHeight);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rimRect, Radius.circular(rimHeight / 2)),
        paint,
      );

      // Small clip-tab notch under the center of the rim.
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(w / 2, y + rimHeight),
          radius: rimHeight * 0.42,
        ),
        0,
        math.pi,
        false,
        paint,
      );

      y += rimHeight;
      final boxHeight = unit - rimHeight;
      final boxRect = Rect.fromLTWH(w * 0.18, y, w * 0.64, boxHeight);
      final isLast = i == 2;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          boxRect,
          topLeft: Radius.circular(w * 0.02),
          topRight: Radius.circular(w * 0.02),
          bottomLeft: Radius.circular(isLast ? w * 0.09 : w * 0.03),
          bottomRight: Radius.circular(isLast ? w * 0.09 : w * 0.03),
        ),
        paint,
      );
      y += boxHeight;
    }
  }

  @override
  bool shouldRepaint(covariant _TiffinIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// Segmented "stamp ring" — one arc segment per tiffin in the collection.
/// Reads as a set of stamps being filled in rather than an abstract
/// percentage, which fits the passport/collection framing much better.
class _StampRing extends StatelessWidget {
  final int collected;
  final int total;
  final double size;

  const _StampRing({
    required this.collected,
    required this.total,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: total > 0 ? collected / total : 0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _StampRingPainter(
              segments: total.clamp(1, 12),
              progress: progress,
              filledColor: _ExperiencePageColors.accentGreen,
              emptyColor: _ExperiencePageColors.border,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _TiffinIcon(
                    size: 30,
                    color: _ExperiencePageColors.darkGreen,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$collected/$total',
                    style: const TextStyle(
                      color: _ExperiencePageColors.darkGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StampRingPainter extends CustomPainter {
  final int segments;
  final double progress; // 0..1
  final Color filledColor;
  final Color emptyColor;

  _StampRingPainter({
    required this.segments,
    required this.progress,
    required this.filledColor,
    required this.emptyColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const gapAngle = 0.10; // radians between segments
    final sweepPerSegment = (2 * math.pi / segments) - gapAngle;
    final filledSegments = (progress * segments).round();

    for (var i = 0; i < segments; i++) {
      final startAngle =
          -math.pi / 2 + i * (sweepPerSegment + gapAngle) + gapAngle / 2;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..color = i < filledSegments ? filledColor : emptyColor.withAlpha(160);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepPerSegment,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StampRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.segments != segments;
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
            color: _ExperiencePageColors.accentGreen,
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
