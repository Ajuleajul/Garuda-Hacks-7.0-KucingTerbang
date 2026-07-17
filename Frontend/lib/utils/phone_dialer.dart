import 'package:url_launcher/url_launcher.dart';

String digitsForDialer(String raw) {
  final trimmed = raw.trim();
  final buf = StringBuffer();
  for (var i = 0; i < trimmed.length; i++) {
    final c = trimmed[i];
    if (c == '+' && buf.isEmpty) {
      buf.write(c);
    } else if (c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57) {
      buf.write(c);
    }
  }
  return buf.toString();
}

Future<bool> openDialerPrefill(String rawNumber) async {
  final digits = digitsForDialer(rawNumber);
  if (digits.isEmpty) return false;
  final uri = Uri.parse('tel:$digits');
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
