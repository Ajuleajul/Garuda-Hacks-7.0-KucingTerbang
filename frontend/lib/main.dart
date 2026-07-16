import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/patient/AuthPage.dart';
import 'theme/curamind_theme.dart';
import 'animated_cursor.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

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
      theme: buildCuramindTheme(),
      home: const AuthPage(),
      builder: (context, child) {
        return AnimatedCustomCursor(child: child!);
      },
    );
  }
}
