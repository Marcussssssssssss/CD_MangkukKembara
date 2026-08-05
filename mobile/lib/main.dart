import 'dart:async';

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
  StreamSubscription<AuthState>? _recoverySubscription;

  @override
  void initState() {
    super.initState();
    _recoverySubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((state) {
          if (state.event == AuthChangeEvent.passwordRecovery) {
            _navigatorKey.currentState?.pushNamedAndRemoveUntil(
              AppRoutes.resetPassword,
              (route) => route.isFirst,
            );
          }
        });
  }

  @override
  void dispose() {
    _recoverySubscription?.cancel();
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
        title: 'MangkukKembara',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRoutes.treasureMap,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
