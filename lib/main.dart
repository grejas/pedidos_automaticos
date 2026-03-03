import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'core/constants/supabase_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );
  runApp(const FatherSonApp());
}

class FatherSonApp extends StatefulWidget {
  const FatherSonApp({super.key});

  @override
  State<FatherSonApp> createState() => _FatherSonAppState();
}

class _FatherSonAppState extends State<FatherSonApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Link inicial si la app estaba cerrada
    final uri = await _appLinks.getInitialLink();
    if (uri != null) {
      _handleDeepLink(uri);
    }

    // Links cuando la app esta abierta
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) async {
    if (uri.scheme == 'fatherson') {
      // Supabase procesa el token automaticamente
      final session = supabase.auth.currentSession;
      if (session != null) {
        _navigatorKey.currentState?.pushReplacementNamed(AppRouter.clientHome);
      } else {
        // Esperar un momento para que Supabase procese el token
        await Future.delayed(const Duration(milliseconds: 500));
        final newSession = supabase.auth.currentSession;
        if (newSession != null) {
          _navigatorKey.currentState?.pushReplacementNamed(AppRouter.clientHome);
        } else {
          _navigatorKey.currentState?.pushReplacementNamed(AppRouter.login);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Father & Son',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.splash,
    );
  }
}
