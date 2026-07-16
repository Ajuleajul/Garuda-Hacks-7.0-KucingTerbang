import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });

  final String id;
  final String email;
  final String fullName;
  final String role;

  factory AuthUser.fromUser(User user) {
    final meta = user.userMetadata ?? {};
    return AuthUser(
      id: user.id,
      email: user.email ?? '',
      fullName: (meta['full_name'] as String?)?.trim().isNotEmpty == true
          ? meta['full_name'] as String
          : 'Unknown',
      role: (meta['role'] as String?) ?? 'PATIENT',
    );
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final meta = json['user_metadata'];
    final metaMap = meta is Map ? Map<String, dynamic>.from(meta) : null;
    return AuthUser(
      id: json['id'] as String? ?? json['sub'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: metaMap?['full_name'] as String? ??
          json['full_name'] as String? ??
          'Unknown',
      role: metaMap?['role'] as String? ?? json['role'] as String? ?? 'PATIENT',
    );
  }

  bool get isPatient => role == 'PATIENT';
  bool get isPsychiatrist => role == 'PSYCHIATRIST';
}

class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final AuthUser user;
}

sealed class SignUpOutcome {
  const SignUpOutcome();
}

class SignUpSignedIn extends SignUpOutcome {
  const SignUpSignedIn(this.result);
  final AuthResult result;
}

class SignUpNeedsVerification extends SignUpOutcome {
  const SignUpNeedsVerification({required this.email});
  final String email;
}

/// App-level auth error (separate from Supabase [AuthException]).
class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  GoTrueClient get _auth => Supabase.instance.client.auth;

  /// Same key supabase_flutter uses for SharedPreferences session storage.
  static String persistSessionKeyForUrl(String supabaseUrl) {
    final host = Uri.parse(supabaseUrl).host;
    final projectRef = host.split('.').first;
    return 'sb-$projectRef-auth-token';
  }

  String get persistSessionKey {
    final url = dotenv.env['SUPABASE_URL']?.trim() ?? '';
    if (url.isEmpty) return 'sb-auth-token';
    return persistSessionKeyForUrl(url);
  }

  /// Must match Supabase → Authentication → URL Configuration → Redirect URLs.
  String get authRedirectUrl {
    final fromEnv = dotenv.env['SUPABASE_AUTH_REDIRECT']?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    return 'curamind://auth-callback';
  }

  /// Write session to SharedPreferences so cold start can restore it.
  /// (Backup — supabase_flutter also persists via its auth listener.)
  Future<void> persistSession(Session session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(persistSessionKey, jsonEncode(session.toJson()));
  }

  /// Re-apply any stored session after [Supabase.initialize] (awaited).
  Future<Session?> restorePersistedSession() async {
    final existing = _auth.currentSession;
    if (existing != null) return existing;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(persistSessionKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      await _auth.recoverSession(raw);
      return _auth.currentSession;
    } catch (_) {
      // Stale/invalid token — clear so we don't loop on a bad session.
      await prefs.remove(persistSessionKey);
      return null;
    }
  }

  Future<SignUpOutcome> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      final trimmedEmail = email.trim();
      final res = await _auth.signUp(
        email: trimmedEmail,
        password: password,
        data: {
          'full_name': fullName.trim(),
          'role': role,
        },
        emailRedirectTo: authRedirectUrl,
      );

      final user = res.user;
      if (user == null) {
        throw AuthFailure('Could not create account. Please try again.');
      }

      if (res.session == null) {
        return SignUpNeedsVerification(email: trimmedEmail);
      }

      await persistSession(res.session!);

      return SignUpSignedIn(
        AuthResult(
          token: res.session!.accessToken,
          user: AuthUser.fromUser(user),
        ),
      );
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw AuthFailure(_friendlyError(e));
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
    String? role,
  }) async {
    try {
      final res = await _auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final session = res.session;
      final user = res.user;

      if (session == null || user == null) {
        throw AuthFailure('Sign in failed. Check your email and password.');
      }

      final authUser = AuthUser.fromUser(user);
      if (role != null &&
          authUser.role.isNotEmpty &&
          authUser.role != role) {
        await _auth.signOut();
        throw AuthFailure(
          role == 'PSYCHIATRIST'
              ? 'This account is not registered as a clinician.'
              : 'This account is not registered as a patient.',
        );
      }

      await persistSession(session);

      return AuthResult(
        token: session.accessToken,
        user: authUser,
      );
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw AuthFailure(_friendlyError(e));
    }
  }

  Future<void> resendVerificationEmail(String email) async {
    try {
      await _auth.resend(
        type: OtpType.signup,
        email: email.trim(),
        emailRedirectTo: authRedirectUrl,
      );
    } catch (e) {
      throw AuthFailure(_friendlyError(e));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: authRedirectUrl,
      );
    } catch (e) {
      throw AuthFailure(_friendlyError(e));
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      if (newPassword.length < 6) {
        throw AuthFailure('Password must be at least 6 characters.');
      }
      if (_auth.currentSession == null) {
        throw AuthFailure(
          'Reset session expired. Request a new password-reset email.',
        );
      }
      await _auth.updateUser(UserAttributes(password: newPassword));
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw AuthFailure(_friendlyError(e));
    }
  }

  Future<String?> getToken() async => _auth.currentSession?.accessToken;

  Future<AuthUser?> getSavedUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return AuthUser.fromUser(user);
  }

  AuthUser? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return AuthUser.fromUser(user);
  }

  Session? get currentSession => _auth.currentSession;

  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(persistSessionKey);
    await _auth.signOut();
  }

  String _friendlyError(Object e) {
    if (e is AuthException) return e.message;

    final raw = e.toString();
    final lower = raw.toLowerCase();

    if (lower.contains('email not confirmed') ||
        lower.contains('email_not_confirmed')) {
      return 'Email not verified yet. Open the link in your inbox, or resend verification.';
    }
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid_credentials')) {
      return 'Incorrect email or password.';
    }
    if (lower.contains('user already registered') ||
        lower.contains('already been registered')) {
      return 'An account with this email already exists. Sign in or reset your password.';
    }
    if (lower.contains('rate limit') || lower.contains('over_email_send_rate')) {
      return 'Too many emails sent. Please wait a minute and try again.';
    }
    if (lower.contains('network') || lower.contains('socket')) {
      return 'Network error. Check your connection and try again.';
    }

    final messageMatch = RegExp(r'message:\s*([^,\)]+)').firstMatch(raw);
    if (messageMatch != null) return messageMatch.group(1)!.trim();

    return raw.replaceFirst('Exception: ', '');
  }
}
