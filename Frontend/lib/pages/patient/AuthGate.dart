import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../services/auth_service.dart';
import '../../shells/clinician_shell.dart';
import '../../shells/patient_shell.dart';
import '../../theme/curamind_theme.dart';
import '../auth/ResetPasswordPage.dart';
import 'AuthPage.dart';

/// Restores the last Supabase session on cold start so users stay signed in.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _sub;
  bool _booting = true;
  bool _passwordRecovery = false;
  AuthUser? _user;

  @override
  void initState() {
    super.initState();
    _restoreSession();
    _sub = AuthService.instance.onAuthStateChange.listen(_onAuthState);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _restoreSession() {
    final session = Supabase.instance.client.auth.currentSession;
    final user = Supabase.instance.client.auth.currentUser;
    setState(() {
      _booting = false;
      _passwordRecovery = false;
      _user = (session != null && user != null)
          ? AuthUser.fromUser(user)
          : null;
    });
  }

  void _onAuthState(AuthState data) {
    switch (data.event) {
      case AuthChangeEvent.passwordRecovery:
        if (!mounted) return;
        setState(() {
          _booting = false;
          _passwordRecovery = true;
          _user = data.session?.user != null
              ? AuthUser.fromUser(data.session!.user)
              : _user;
        });
      case AuthChangeEvent.signedOut:
        if (!mounted) return;
        setState(() {
          _booting = false;
          _passwordRecovery = false;
          _user = null;
        });
      case AuthChangeEvent.initialSession:
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.tokenRefreshed:
      case AuthChangeEvent.userUpdated:
        if (!mounted) return;
        final session = data.session;
        final user = session?.user ?? Supabase.instance.client.auth.currentUser;
        setState(() {
          _booting = false;
          if (!_passwordRecovery) {
            _user = (session != null && user != null)
                ? AuthUser.fromUser(user)
                : null;
          }
        });
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_booting) {
      return const _BootSplash();
    }

    if (_passwordRecovery) {
      return const ResetPasswordPage();
    }

    final user = _user;
    if (user == null) {
      return const AuthPage();
    }

    final name = user.fullName.trim().isEmpty ? null : user.fullName.trim();
    if (user.isPsychiatrist) {
      return ClinicianShell(displayName: name ?? 'Clinician');
    }
    return PatientShell(displayName: name ?? 'Patient');
  }
}

class _BootSplash extends StatelessWidget {
  const _BootSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CuramindColors.mist,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Curamind',
              style: GoogleFonts.fraunces(
                fontSize: 34,
                fontWeight: FontWeight.w600,
                color: CuramindColors.ink,
              ),
            ),
            const SizedBox(height: 18),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: CuramindColors.sageDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
