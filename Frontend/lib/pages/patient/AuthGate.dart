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
    unawaited(_hydrate());
    _sub = AuthService.instance.onAuthStateChange.listen(_onAuthState);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _hydrate() async {
    final session = AuthService.instance.currentSession;
    if (session == null) {
      if (!mounted) return;
      setState(() {
        _ready = true;
        _passwordRecovery = false;
        _user = null;
      });
      return;
    }
    final user = await AuthService.instance.resolveCurrentUser();
    if (!mounted) return;
    setState(() {
      _ready = true;
      _passwordRecovery = false;
      _user = user;
    });
  }

  Future<void> _applySession(Session? session) async {
    if (session == null) {
      if (!mounted) return;
      setState(() {
        _ready = true;
        if (!_passwordRecovery) _user = null;
      });
      return;
    }
    final user = await AuthService.instance.resolveUser(session.user);
    if (!mounted) return;
    setState(() {
      _ready = true;
      _user = user;
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
        if (_passwordRecovery) {
          setState(() => _ready = true);
          return;
        }
        final session =
            data.session ?? AuthService.instance.currentSession;
        unawaited(_applySession(session));
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
