import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/auth/ResetPasswordPage.dart';
import 'pages/patient/AuthPage.dart';
import 'theme/curamind_theme.dart';
import 'animated_cursor.dart';

final GlobalKey<NavigatorState> curamindNavigatorKey =
    GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL']?.trim() ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'Missing SUPABASE_URL or SUPABASE_ANON_KEY in Frontend/.env',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const CuramindApp());
}

class CuramindApp extends StatefulWidget {
  const CuramindApp({super.key});

  @override
  State<CuramindApp> createState() => _CuramindAppState();
}

class _CuramindAppState extends State<CuramindApp> {
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        final nav = curamindNavigatorKey.currentState;
        if (nav == null) return;
        nav.pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => const ResetPasswordPage(),
          ),
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Curamind',
      debugShowCheckedModeBanner: false,
      navigatorKey: curamindNavigatorKey,
      theme: buildCuramindTheme(),
      home: const AuthPage(),
      builder: (context, child) {
        return AnimatedCustomCursor(child: child!);
      },
    );
  }
}
