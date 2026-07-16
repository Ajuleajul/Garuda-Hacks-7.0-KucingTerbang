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
  bool _passwordRecovery = false;
  AuthUser? _user;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _applyFromClient();
    _sub = AuthService.instance.onAuthStateChange.listen(_onAuthState);

    // Catch late recoverSession() completion from supabase_flutter.
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final session = AuthService.instance.currentSession;
      if (session != null && _user == null) {
        _applySession(session);
      } else if (!_ready) {
        setState(() => _ready = true);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _applyFromClient() {
    final session = AuthService.instance.currentSession;
    final user = AuthService.instance.currentUser;
    setState(() {
      _ready = true;
      _passwordRecovery = false;
      _user = session != null ? user : null;
    });
  }

  void _applySession(Session? session) {
    setState(() {
      _ready = true;
      if (session == null) {
        if (!_passwordRecovery) _user = null;
      } else {
        _user = AuthUser.fromUser(session.user);
      }
    });
  }

  void _onAuthState(AuthState data) {
    if (!mounted) return;

    switch (data.event) {
      case AuthChangeEvent.passwordRecovery:
        setState(() {
          _ready = true;
          _passwordRecovery = true;
        });
      case AuthChangeEvent.signedOut:
        setState(() {
          _ready = true;
          _passwordRecovery = false;
          _user = null;
        });
      case AuthChangeEvent.initialSession:
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.tokenRefreshed:
      case AuthChangeEvent.userUpdated:
        if (_passwordRecovery &&
            data.event != AuthChangeEvent.signedIn) {
          setState(() => _ready = true);
          return;
        }
        final session =
            data.session ?? AuthService.instance.currentSession;
        if (_passwordRecovery && data.event == AuthChangeEvent.signedIn) {
          // Stay on reset screen until password flow finishes / signs out.
          setState(() => _ready = true);
          return;
        }
        _applySession(session);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
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
