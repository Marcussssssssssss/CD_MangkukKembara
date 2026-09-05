import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_routes.dart';
import 'core/app_theme.dart';
import 'core/backend_config.dart';
import 'ViewModel/AccountManagement/auth_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Supabase.initialize(
    url: BackendConfig.supabaseUrl,
    publishableKey: BackendConfig.supabaseAnonKey,
  );
  runApp(const MangkukKembaraApp());
}

/// Root application widget for MangkukKembara.
class MangkukKembaraApp extends StatefulWidget {
  const MangkukKembaraApp({super.key});

  @override
  State<MangkukKembaraApp> createState() => _MangkukKembaraAppState();
}

class _MangkukKembaraAppState extends State<MangkukKembaraApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<AuthState>? _authSubscription;
  late bool _hadAuthenticatedSession;
  String? _lastKnownEmail;

  @override
  void initState() {
    super.initState();
    // A password check re-authenticates an already signed-in user and emits
    // SIGNED_IN. Keep that event on the current page instead of treating it
    // as a fresh login and forcing navigation to the Treasure Map.
    final initialUser = Supabase.instance.client.auth.currentSession?.user;
    _hadAuthenticatedSession = initialUser != null;
    _lastKnownEmail = initialUser?.email;
    if (_hasPendingEmail(initialUser)) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _showPendingEmailNotice(initialUser!),
      );
    }
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      state,
    ) {
      if (state.event == AuthChangeEvent.passwordRecovery) {
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.resetPassword,
          (route) => route.isFirst,
        );
      } else if (state.event == AuthChangeEvent.signedIn) {
        final user = state.session?.user;
        if (_hadAuthenticatedSession) {
          if (_hasPendingEmail(user)) {
            _showPendingEmailNotice(user!);
          } else if (user?.email != null &&
              _lastKnownEmail != null &&
              user!.email != _lastKnownEmail) {
            _showMessage(
              'Email address changed successfully to ${user.email}.',
            );
          }
          _lastKnownEmail = user?.email ?? _lastKnownEmail;
          return;
        }
        _hadAuthenticatedSession = true;
        _lastKnownEmail = user?.email;
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.treasureMap,
          (route) => false,
        );
      } else if (state.event == AuthChangeEvent.signedOut) {
        _hadAuthenticatedSession = false;
        _lastKnownEmail = null;
      }
    });
  }

  bool _hasPendingEmail(User? user) =>
      user?.newEmail != null && user!.newEmail!.trim().isNotEmpty;

  void _showPendingEmailNotice(User user) {
    final oldEmail = user.email ?? 'your old email address';
    final newEmail = user.newEmail!;
    _showMessage(
      'Email change is not complete yet. If you confirmed $newEmail, now open $oldEmail and approve the email change there too.',
      duration: const Duration(seconds: 20),
    );
  }

  void _showMessage(
    String message, {
    Duration duration = const Duration(seconds: 6),
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messenger = _messengerKey.currentState;
      if (messenger == null) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            duration: duration,
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Global auth state — shared across all modules
        ChangeNotifierProvider<AuthViewModel>(create: (_) => AuthViewModel()),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        scaffoldMessengerKey: _messengerKey,
        title: 'MangkukKembara',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: (context, child) => MobileWebFrame(
          enabled: kIsWeb,
          child: child ?? const SizedBox.shrink(),
        ),
        initialRoute: AppRoutes.accountLanding,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}

/// Keeps the web build at a familiar phone width on larger browser windows.
///
/// The frame is applied above the Navigator, so routes, dialogs, snack bars,
/// and bottom sheets all receive the same mobile-sized [MediaQuery]. Native
/// Android and iOS builds are returned unchanged.
class MobileWebFrame extends StatelessWidget {
  const MobileWebFrame({
    required this.enabled,
    required this.child,
    this.maxWidth = 430,
    super.key,
  });

  final bool enabled;
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final mediaQuery = MediaQuery.of(context);

    return ColoredBox(
      color: const Color(0xFFE8E3D8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final frameWidth = constraints.maxWidth.clamp(0, maxWidth).toDouble();
          final frameSize = Size(frameWidth, constraints.maxHeight);

          return Center(
            child: Container(
              width: frameWidth,
              height: constraints.maxHeight,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: constraints.maxWidth > maxWidth
                    ? const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: MediaQuery(
                data: mediaQuery.copyWith(size: frameSize),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}
