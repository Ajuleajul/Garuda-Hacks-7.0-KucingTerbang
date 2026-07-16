import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Backend base URL for all Flutter targets (web, mobile, desktop).
///
/// Resolution order:
/// 1. `--dart-define=API_BASE_URL=...` (CI / release builds)
/// 2. `API_BASE_URL` in `.env` (runtime — use this for physical devices)
/// 3. Platform defaults:
///    - Android emulator → `http://10.0.2.2:3000`
///    - iOS Simulator / desktop / web → `http://localhost:3000`
///
/// Physical phone/tablet: set in `Frontend/.env`, e.g.
/// `API_BASE_URL=http://192.168.1.20:3000` (your PC LAN IP).
class ApiConfig {
  static String get baseUrl {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.trim().isNotEmpty) {
      return _normalize(fromDefine);
    }

    try {
      final fromDotenv = dotenv.env['API_BASE_URL']?.trim();
      if (fromDotenv != null && fromDotenv.isNotEmpty) {
        return _normalize(fromDotenv);
      }
    } catch (_) {
      // dotenv not loaded yet — fall through to defaults
    }

    return _normalize(_platformDefault);
  }

  static String get _platformDefault {
    if (kIsWeb) return 'http://localhost:3000';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Emulator reaches host machine via 10.0.2.2.
        // Physical Android: override with API_BASE_URL in .env.
        return 'http://10.0.2.2:3000';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://localhost:3000';
    }
  }

  static String _normalize(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }
}
