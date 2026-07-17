import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const base = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000',
);

DateTime? parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

Map<String, dynamic> parseGroup(Map<String, dynamic> json) {
  final id = json['id']?.toString() ?? '';
  final code = (json['code']?.toString() ?? '').toUpperCase();
  final psychId = json['psychiatrist_id']?.toString() ?? '';
  if (id.isEmpty || code.isEmpty || psychId.isEmpty) {
    throw StateError('Bad group json: $json');
  }
  parseDate(json['expires_at']);
  parseDate(json['created_at']);
  return json;
}

Future<void> main() async {
  print('Client E2E → $base');

  final health = await http.get(Uri.parse('$base/health'));
  if (health.statusCode != 200) {
    stderr.writeln('health failed ${health.statusCode}');
    exit(1);
  }
  print('✓ health');

  final psychId = 'dart-psych-${DateTime.now().millisecondsSinceEpoch}';
  final patientId = 'dart-patient-${DateTime.now().millisecondsSinceEpoch}';

  final createRes = await http
      .post(
        Uri.parse('$base/api/link/groups'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'psychiatrist_id': psychId,
          'psychiatrist_name': 'Dr Dart',
          'psychiatrist_email': 'dart@test',
          'name': 'Dart cohort',
          'expires_in_minutes': 60,
        }),
      )
      .timeout(const Duration(seconds: 8));

  if (createRes.statusCode != 201 && createRes.statusCode != 200) {
    stderr.writeln('create failed ${createRes.statusCode} ${createRes.body}');
    exit(1);
  }
  final createBody = jsonDecode(createRes.body) as Map<String, dynamic>;
  final group =
      parseGroup(Map<String, dynamic>.from(createBody['group'] as Map));
  final code = group['code'] as String;
  final groupId = group['id'] as String;
  print('✓ create $code');

  final joinRes = await http.post(
    Uri.parse('$base/api/link/join'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'patient_id': patientId,
      'patient_name': 'Dart Pat',
      'code': code,
    }),
  );
  if (joinRes.statusCode != 200) {
    stderr.writeln('join failed ${joinRes.statusCode} ${joinRes.body}');
    exit(1);
  }
  print('✓ join');

  final patch = await http.patch(
    Uri.parse('$base/api/link/groups/$groupId'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'is_active': false}),
  );
  if (patch.statusCode != 200) {
    stderr.writeln('deactivate failed ${patch.statusCode} ${patch.body}');
    exit(1);
  }
  final patched = jsonDecode(patch.body) as Map<String, dynamic>;
  parseGroup(Map<String, dynamic>.from(patched['group'] as Map));
  print('✓ deactivate');

  print('\nCLIENT E2E PASSED (same path as Flutter http client)');
}
