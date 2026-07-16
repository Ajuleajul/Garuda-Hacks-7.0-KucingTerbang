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

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? json['sub'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['user_metadata']?['full_name'] as String? ?? json['full_name'] as String? ?? 'Unknown',
      role: json['user_metadata']?['role'] as String? ?? json['role'] as String? ?? 'PATIENT',
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

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _supabase = Supabase.instance.client;

  Future<AuthResult> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      final res = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'role': role,
        },
      );
      
      final session = res.session;
      final user = res.user;
      
      if (session == null || user == null) {
        throw AuthException('Registration Successfull, please confirm your email.');
      }
      
      return AuthResult(
        token: session.accessToken,
        user: AuthUser.fromJson(user.toJson()),
      );
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
    String? role,
  }) async {
    try {
      final res = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      
      final session = res.session;
      final user = res.user;
      
      if (session == null || user == null) {
        throw AuthException('Login failed. Please check your credentials.');
      }
      
      return AuthResult(
        token: session.accessToken,
        user: AuthUser.fromJson(user.toJson()),
      );
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  Future<String?> getToken() async {
    return _supabase.auth.currentSession?.accessToken;
  }

  Future<AuthUser?> getSavedUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return AuthUser.fromJson(user.toJson());
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}
