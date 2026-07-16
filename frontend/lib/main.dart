import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pages/patient/AuthPage.dart';
import 'theme/curamind_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    );
  }
}
