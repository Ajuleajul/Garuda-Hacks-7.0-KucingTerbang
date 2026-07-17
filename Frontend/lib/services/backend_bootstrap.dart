import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class BackendBootstrap {
  BackendBootstrap._();

  static Future<bool> ping({Duration timeout = const Duration(seconds: 2)}) async {
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/health'))
          .timeout(timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<void> ensureRunning() async {
    if (await ping()) return;
    if (kIsWeb) return;
    if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) return;

    final backendDir = await _resolveBackendDir();
    if (backendDir == null) return;

    try {
      await Process.start(
        Platform.isWindows ? 'npm.cmd' : 'npm',
        const ['run', 'dev'],
        workingDirectory: backendDir.path,
        mode: ProcessStartMode.detached,
        runInShell: true,
      );
    } catch (_) {
      return;
    }

    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (await ping()) return;
    }
  }

  static Future<Directory?> _resolveBackendDir() async {
    final candidates = <Directory>[
      Directory('${Directory.current.path}${Platform.pathSeparator}Backend'),
      Directory('${Directory.current.path}${Platform.pathSeparator}backend'),
      Directory(
        '${Directory.current.parent.path}${Platform.pathSeparator}Backend',
      ),
      Directory(
        '${Directory.current.parent.path}${Platform.pathSeparator}backend',
      ),
    ];
    for (final dir in candidates) {
      final pkg = File('${dir.path}${Platform.pathSeparator}package.json');
      if (await pkg.exists()) return dir;
    }
    return null;
  }
}
