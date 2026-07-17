import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/patient/AuthGate.dart';
import 'services/auth_service.dart';
import 'services/backend_bootstrap.dart';
import 'services/reminder_service.dart';
import 'theme/curamind_theme.dart';
import 'animated_cursor.dart';

final GlobalKey<NavigatorState> curamindNavigatorKey =
    GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  if (!kIsWeb) {
    await BackendBootstrap.ensureRunning();
  } else {
    unawaited(BackendBootstrap.ensureRunning());
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL']?.trim() ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'Missing SUPABASE_URL or SUPABASE_ANON_KEY in Frontend/.env',
    );
  }

  await SharedPreferences.getInstance();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      localStorage: SharedPreferencesLocalStorage(
        persistSessionKey: AuthService.persistSessionKeyForUrl(supabaseUrl),
      ),
    ),
  );

  await AuthService.instance.restorePersistedSession();
  await ReminderService.instance.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const CuramindApp());
}

class CuramindApp extends StatelessWidget {
  const CuramindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Curamind',
      debugShowCheckedModeBanner: false,
      navigatorKey: curamindNavigatorKey,
      theme: buildCuramindTheme(),
      home: const AuthGate(),
      builder: (context, child) {
        return AnimatedCustomCursor(child: child!);
      },
    );
  }
}
