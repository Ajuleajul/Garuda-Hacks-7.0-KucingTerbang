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
    required this.avatarKey,
  });

  final String id;
  final String email;
  final String fullName;
  final String role;
  final String avatarKey;

  static String normalizeRole(String? raw) {
    final r = (raw ?? '').trim().toUpperCase();
    if (r == 'PSYCHIATRIST' ||
        r == 'PSIKIATER' ||
        r == 'CLINICIAN' ||
        r == 'DOCTOR') {
      return 'PSYCHIATRIST';
    }
    if (r == 'PATIENT' || r == 'PASIEN') return 'PATIENT';
    return r.isEmpty ? '' : r;
  }

  factory AuthUser.fromUser(User user, {String? fallbackRole}) {
    final meta = user.userMetadata ?? {};
    final appMeta = user.appMetadata;
    final raw = meta['role'] as String? ??
        appMeta['role'] as String? ??
        fallbackRole;
    final normalized = normalizeRole(raw);
    return AuthUser(
      id: user.id,
      email: user.email ?? '',
      fullName: (meta['full_name'] as String?)?.trim().isNotEmpty == true
          ? meta['full_name'] as String
          : 'Unknown',
      role: normalized.isEmpty ? 'PATIENT' : normalized,
      avatarKey: (meta['avatar_key'] as String?)?.trim() ?? 'person',
    );
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final meta = json['user_metadata'];
    final metaMap = meta is Map ? Map<String, dynamic>.from(meta) : null;
    final normalized = normalizeRole(
      metaMap?['role'] as String? ?? json['role'] as String?,
    );
    return AuthUser(
      id: json['id'] as String? ?? json['sub'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: metaMap?['full_name'] as String? ??
          json['full_name'] as String? ??
          'Unknown',
      role: normalized.isEmpty ? 'PATIENT' : normalized,
      avatarKey: metaMap?['avatar_key'] as String? ?? 'person',
    );
  }

  bool get isPatient => role == 'PATIENT';
  bool get isPsychiatrist => role == 'PSYCHIATRIST';

  AuthUser copyWith({String? role, String? fullName, String? avatarKey}) {
    return AuthUser(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      avatarKey: avatarKey ?? this.avatarKey,
    );
  }
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

  Future<void> saveLocalRole(String userId, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('curamind_role_$userId', normalizeStoredRole(role));
  }

  Future<String?> loadLocalRole(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return AuthUser.normalizeRole(prefs.getString('curamind_role_$userId'));
  }

  static String normalizeStoredRole(String role) {
    final n = AuthUser.normalizeRole(role);
    return n.isEmpty ? 'PATIENT' : n;
  }

  /// Resolves role from metadata, then local backup (for cold start).
  Future<AuthUser> resolveUser(User user) async {
    final metaRole = AuthUser.normalizeRole(
      user.userMetadata?['role'] as String? ??
          user.appMetadata['role'] as String?,
    );
    if (metaRole == 'PSYCHIATRIST' || metaRole == 'PATIENT') {
      return AuthUser.fromUser(user, fallbackRole: metaRole);
    }
    final local = await loadLocalRole(user.id);
    if (local != null && local.isNotEmpty) {
      return AuthUser.fromUser(user, fallbackRole: local);
    }
    return AuthUser.fromUser(user);
  }

  Future<User> _stampRoleMetadata({
    required User user,
    required String role,
    required String fullName,
  }) async {
    final normalized = normalizeStoredRole(role);
    final meta = Map<String, dynamic>.from(user.userMetadata ?? {});
    final current = AuthUser.normalizeRole(meta['role'] as String?);
    if (current == normalized &&
        (meta['full_name'] as String?)?.trim().isNotEmpty == true) {
      await saveLocalRole(user.id, normalized);
      return user;
    }
    meta['role'] = normalized;
    meta['full_name'] = fullName.trim().isNotEmpty
        ? fullName.trim()
        : (meta['full_name'] as String? ?? 'User');
    final updated = await _auth.updateUser(UserAttributes(data: meta));
    final next = updated.user ?? _auth.currentUser ?? user;
    await saveLocalRole(next.id, normalized);
    return next;
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
        await saveLocalRole(user.id, role);
        return SignUpNeedsVerification(email: trimmedEmail);
      }

      final stamped = await _stampRoleMetadata(
        user: user,
        role: role,
        fullName: fullName,
      );
      await persistSession(res.session!);

      return SignUpSignedIn(
        AuthResult(
          token: res.session!.accessToken,
          user: await resolveUser(stamped),
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

      var authUser = await resolveUser(user);

      if (role == 'PSYCHIATRIST' && !authUser.isPsychiatrist) {
        final raw = AuthUser.normalizeRole(
          user.userMetadata?['role'] as String?,
        );
        final local = await loadLocalRole(user.id);
        if (raw.isEmpty || local == 'PSYCHIATRIST') {
          final stamped = await _stampRoleMetadata(
            user: user,
            role: 'PSYCHIATRIST',
            fullName: authUser.fullName == 'Unknown'
                ? (user.email ?? 'Clinician')
                : authUser.fullName,
          );
          authUser = await resolveUser(stamped);
        }
      }

      if (role != null && authUser.role != role) {
        await _auth.signOut();
        throw AuthFailure(
          role == 'PSYCHIATRIST'
              ? 'This account is not registered as a clinician.'
              : 'This account is not registered as a patient.',
        );
      }

      await saveLocalRole(authUser.id, authUser.role);
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

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email?.trim() ?? '';
    if (email.isEmpty) {
      throw AuthFailure('No signed-in user found.');
    }
    if (currentPassword.length < 6) {
      throw AuthFailure('Current password is required.');
    }
    if (newPassword.length < 6) {
      throw AuthFailure('New password must be at least 6 characters.');
    }
    if (currentPassword == newPassword) {
      throw AuthFailure('New password must be different.');
    }
    try {
      await _auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
      await _auth.updateUser(UserAttributes(password: newPassword));
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw AuthFailure(_friendlyError(e));
    }
  }

  Future<AuthUser> updateProfile({
    required String fullName,
    required String avatarKey,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw AuthFailure('No signed-in user found.');
    final nextName = fullName.trim();
    if (nextName.isEmpty) {
      throw AuthFailure('Name cannot be empty.');
    }
    final meta = Map<String, dynamic>.from(user.userMetadata ?? {});
    meta['full_name'] = nextName;
    meta['avatar_key'] = avatarKey.trim().isEmpty ? 'person' : avatarKey.trim();
    try {
      final updated = await _auth.updateUser(UserAttributes(data: meta));
      final nextUser = updated.user ?? _auth.currentUser ?? user;
      return resolveUser(nextUser);
    } catch (e) {
      throw AuthFailure(_friendlyError(e));
    }
  }

  Future<String?> getToken() async => _auth.currentSession?.accessToken;

  Future<AuthUser?> getSavedUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return resolveUser(user);
  }

  AuthUser? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return AuthUser.fromUser(user);
  }

  Future<AuthUser?> resolveCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return resolveUser(user);
  }

  Session? get currentSession => _auth.currentSession;

  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  Future<void> logout() async {
    final user = _auth.currentUser;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(persistSessionKey);
    // Keep curamind_role_* so role survives re-login if metadata is flaky.
    await _auth.signOut();
    if (user != null) {
      // no-op placeholder — role backup retained on purpose
    }
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
