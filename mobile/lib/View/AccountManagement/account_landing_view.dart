import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../ViewModel/AccountManagement/auth_view_model.dart';
import '../../core/app_routes.dart';
import '../Widgets/map_home_button.dart';
import 'welcome/destination_marker.dart';
import 'welcome/journey_animation_coordinates.dart';
import 'welcome/journey_route_painter.dart';

/// Animated logged-out account landing page. Authentication and navigation
/// remain unchanged; this screen owns only the welcome presentation.
class AccountLandingView extends StatelessWidget {
  const AccountLandingView({super.key});

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
    child: MapBackScope(
      child: Scaffold(
        backgroundColor: const Color(0xFF008D8D),
        body: Consumer<AuthViewModel>(
          builder: (context, auth, _) {
            if (auth.isLoggedIn) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.treasureMap,
                ),
              );
              return const SizedBox.shrink();
            }
            return _WelcomePage(
              onLogin: () => Navigator.pushNamed(context, AppRoutes.login),
              onRegister: () =>
                  Navigator.pushNamed(context, AppRoutes.register),
            );
          },
        ),
      ),
    ),
  );
}

class _WelcomePage extends StatefulWidget {
  const _WelcomePage({required this.onLogin, required this.onRegister});

  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  State<_WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<_WelcomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _assets = [
    'asset/image/welcome_base_background.png',
    'asset/image/mangkuk_kembara_logo_white.png',
    'asset/image/penang_marker_photo.png',
    'asset/image/kelantan_marker_photo.png',
    'asset/image/melaka_marker_photo.png',
    'asset/image/sarawak_marker_photo.png',
  ];

  late final AnimationController _controller;
  late final Animation<double> _background;
  late final Animation<double> _logo;
  late final Animation<double> _route;
  late final Animation<double> _headline;
  late final Animation<double> _shine;
  bool _reducedMotionApplied = false;

  Animation<double> _interval(double begin, double end, Curve curve) =>
      CurvedAnimation(
        parent: _controller,
        curve: Interval(begin, end, curve: curve),
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );
    _background = _interval(0, .12, Curves.easeOutCubic);
    _logo = _interval(.04, .18, Curves.easeOutCubic);
    _route = _interval(.16, .76, Curves.easeInOutCubic);
    _headline = _interval(.70, .88, Curves.easeOutCubic);
    _shine = _interval(.72, .87, Curves.easeInOutCubic);
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final asset in _assets) {
      precacheImage(AssetImage(asset), context);
    }
    if (MediaQuery.disableAnimationsOf(context) && !_reducedMotionApplied) {
      _reducedMotionApplied = true;
      _controller.value = 1;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _controller.isAnimating) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed &&
        _controller.value < 1 &&
        !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  void _completeIntro() {
    if (_controller.value < 1) {
      _controller.animateTo(
        1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _completeIntro,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stageHeight = constraints.maxWidth *
              (designSize.height / designSize.width);
          return Stack(
            fit: StackFit.expand,
            children: [
              // This is a background-only water continuation. The approved
              // composition below keeps its original size and coordinates.
              const Positioned.fill(
                child: Image(
                  image: AssetImage('asset/image/welcome_base_background.png'),
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: stageHeight,
                  child: RepaintBoundary(
                    child: FittedBox(
                      fit: BoxFit.fill,
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: designSize.width,
                        height: designSize.height,
                        child: _WelcomeStage(
                          controller: _controller,
                          background: _background,
                          logo: _logo,
                          route: _route,
                          headline: _headline,
                          shine: _shine,
                          reducedMotion: reducedMotion,
                          onLogin: widget.onLogin,
                          onRegister: widget.onRegister,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WelcomeStage extends StatelessWidget {
  const _WelcomeStage({
    required this.controller,
    required this.background,
    required this.logo,
    required this.route,
    required this.headline,
    required this.shine,
    required this.reducedMotion,
    required this.onLogin,
    required this.onRegister,
  });

  final AnimationController controller;
  final Animation<double> background;
  final Animation<double> logo;
  final Animation<double> route;
  final Animation<double> headline;
  final Animation<double> shine;
  final bool reducedMotion;
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  Animation<double> _marker(double begin, double end) => CurvedAnimation(
    parent: controller,
    curve: Interval(begin, end, curve: Curves.easeOutBack),
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => Stack(
      clipBehavior: Clip.none,
      children: [
        Opacity(
          opacity: reducedMotion ? 1 : clampProgress(background.value),
          child: const Image(
            image: AssetImage('asset/image/welcome_base_background.png'),
            width: 898,
            height: 1751,
            fit: BoxFit.fill,
          ),
        ),
        CustomPaint(
          size: designSize,
          painter: JourneyRoutePainter(
            progress: AlwaysStoppedAnimation(
              reducedMotion ? 1 : clampProgress(route.value),
            ),
            repaint: controller,
          ),
        ),
        DestinationMarker(
          label: 'PENANG',
          imageAsset: 'asset/image/penang_marker_photo.png',
          center: penangPoint,
          arrival: _marker(.10, .20),
        ),
        DestinationMarker(
          label: 'KELANTAN',
          imageAsset: 'asset/image/kelantan_marker_photo.png',
          center: kelantanPoint,
          arrival: _marker(.31, .40),
        ),
        DestinationMarker(
          label: 'MELAKA',
          imageAsset: 'asset/image/melaka_marker_photo.png',
          center: melakaPoint,
          arrival: _marker(.50, .59),
        ),
        DestinationMarker(
          label: 'SARAWAK',
          imageAsset: 'asset/image/sarawak_marker_photo.png',
          center: sarawakPoint,
          arrival: _marker(.70, .79),
        ),
        if (!reducedMotion) _LargeTiffinShine(progress: shine),
        Positioned(
          left: 55,
          top: 64,
          width: 370,
          child: FadeTransition(
            opacity: logo,
            child: Image.asset('asset/image/mangkuk_kembara_logo_white.png'),
          ),
        ),
        Positioned(
          left: 55,
          top: 850,
          width: 390,
          child: FadeTransition(
            opacity: headline,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .09),
                end: Offset.zero,
              ).animate(headline),
              child: const _WelcomeCopy(),
            ),
          ),
        ),
        Positioned(
          left: 130,
          top: 1513,
          width: 638,
          height: 120,
          child: _WelcomeButton(
            label: 'Login',
            visible: _ButtonStyle.filled,
            animation: background,
            onPressed: onLogin,
          ),
        ),
        Positioned(
          left: 130,
          top: 1633,
          width: 638,
          height: 120,
          child: _WelcomeButton(
            label: 'Create Account',
            visible: _ButtonStyle.outlined,
            animation: background,
            onPressed: onRegister,
          ),
        ),
      ],
    ),
  );
}

class _LargeTiffinShine extends StatelessWidget {
  const _LargeTiffinShine({required this.progress});

  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final shineProgress = clampProgress(progress.value);
    return Positioned.fromRect(
      rect: const Rect.fromLTWH(445, 710, 360, 610),
      child: IgnorePointer(
        child: Opacity(
          opacity: .18 * (1 - (shineProgress - .5).abs() * 2),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-1 + 2 * shineProgress, -.2),
                radius: 1.08,
                colors: const [Color(0xFFFFE292), Color(0x00FFE292)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeCopy extends StatelessWidget {
  const _WelcomeCopy();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Taste Malaysia,\nOne Journey\nat a Time.',
        style: GoogleFonts.playfairDisplay(
          color: const Color(0xFFFFF8EC),
          fontSize: 60,
          height: .98,
          fontWeight: FontWeight.w500,
          shadows: const [
            Shadow(
              color: Color(0x9E075A5A),
              offset: Offset(1, 2),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      Container(width: 110, height: 4, color: const Color(0xFFE3B52C)),
      const SizedBox(height: 22),
      Text(
        'Follow the flavours, stories and\nheritage carried by every tiffin.',
        style: GoogleFonts.dmSans(
          color: const Color(0xFFFFF8EC),
          fontSize: 22,
          height: 1.35,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

enum _ButtonStyle { filled, outlined }

class _WelcomeButton extends StatelessWidget {
  const _WelcomeButton({
    required this.label,
    required this.visible,
    required this.animation,
    required this.onPressed,
  });

  final String label;
  final _ButtonStyle visible;
  final Animation<double> animation;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0, .025),
      end: Offset.zero,
    ).animate(animation),
    child: Opacity(
      opacity: .85 + .15 * clampProgress(animation.value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SizedBox(
          height: 96,
          child: visible == _ButtonStyle.filled
              ? FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF8EC),
                    foregroundColor: const Color(0xFF075A5A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: onPressed,
                  child: _buttonLabel(const Color(0xFF075A5A)),
                )
              : OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFF8EC),
                    side: const BorderSide(color: Color(0xFFE3B52C), width: 3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: onPressed,
                  child: _buttonLabel(const Color(0xFFFFF8EC)),
                ),
        ),
      ),
    ),
  );

  Widget _buttonLabel(Color color) => Text(
    label,
    style: GoogleFonts.dmSans(color: color, fontSize: 30, fontWeight: FontWeight.w700),
  );
}
