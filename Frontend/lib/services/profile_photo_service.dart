import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

class ProfilePhotoService {
  ProfilePhotoService._();
  static final ProfilePhotoService instance = ProfilePhotoService._();

  final _picker = ImagePicker();

  String _prefsKey(String uid) => 'profile_photo_b64_$uid';

  Future<String?> loadBase64([String? userId]) async {
    final uid = userId ?? Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final local = prefs.getString(_prefsKey(uid));
    if (local != null && local.isNotEmpty) return local;

    final meta = Supabase.instance.client.auth.currentUser?.userMetadata ?? {};
    final b64 = (meta['avatar_b64'] as String?)?.trim();
    if (b64 != null && b64.isNotEmpty) {
      await prefs.setString(_prefsKey(uid), b64);
      return b64;
    }
    return null;
  }

  Future<Uint8List?> loadBytes([String? userId]) async {
    final b64 = await loadBase64(userId);
    if (b64 == null || b64.isEmpty) return null;
    try {
      return Uint8List.fromList(base64Decode(b64));
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> pickAndSave() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) throw AuthFailure('Sign in required.');

    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 256,
      maxHeight: 256,
      imageQuality: 55,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) throw AuthFailure('Could not read that photo.');

    final b64 = base64Encode(bytes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey(uid), b64);

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final meta = Map<String, dynamic>.from(user.userMetadata ?? {});
      meta['avatar_key'] = 'photo';
      meta['avatar_b64'] = b64;
      meta.remove('avatar_url');
      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(data: meta),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Avatar metadata update skipped: $e');
        }
      }
    }

    AuthService.instance.notifyProfileChanged();
    return bytes;
  }

  Future<void> clearLocal(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey(uid));
  }
}
