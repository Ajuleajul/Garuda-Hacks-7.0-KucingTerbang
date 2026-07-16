import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../theme/curamind_theme.dart';
import '../psychiatrist/ClinicianLoginPage.dart';
import 'ProfilePage.dart';
import '../../animated_cursor.dart';

enum AuthMode { login, register }

enum UserRole { patient, psychiatrist }

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  AuthMode _mode = AuthMode.login;
  UserRole _role = UserRole.patient;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  late final AnimationController _brandPulse;
  late final AnimationController _formFade;
  late final Animation<double> _brandScale;
  late final Animation<double> _formOpacity;

  @override
  void initState() {
    super.initState();
    _brandPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _brandScale = Tween<double>(begin: 1.0, end: 1.035).animate(
      CurvedAnimation(parent: _brandPulse, curve: Curves.easeInOut),
    );

    _formFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 1,
    );
    _formOpacity = CurvedAnimation(parent: _formFade, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _brandPulse.dispose();
    _formFade.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _switchMode(AuthMode next) async {
    if (next == _mode) return;
    await _formFade.reverse();
    setState(() => _mode = next);
    await _formFade.forward();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final auth = AuthService.instance;
      final AuthResult result;
      if (_mode == AuthMode.register) {
        result = await auth.register(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _nameController.text,
          role: 'PATIENT',
        );
      } else {
        result = await auth.login(
          email: _emailController.text,
          password: _passwordController.text,
          role: 'PATIENT',
        );
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 420),
          pageBuilder: (context, animation, secondaryAnimation) {
            return FadeTransition(
              opacity: animation,
              child: ProfilePage(
                name: result.user.fullName,
                role: 'Patient',
              ),
            );
          },
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: CuramindColors.danger,
          content: Text(
            e.message,
            style: GoogleFonts.outfit(color: CuramindColors.white),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: CuramindColors.danger,
          content: Text(
            'Cannot reach server. Is the API running?',
            style: GoogleFonts.outfit(color: CuramindColors.white),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openClinicianLogin() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 360),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: const ClinicianLoginPage(),
          );
        },
      ),
    );
  }

  void _onRoleChanged(UserRole role) {
    if (role == UserRole.psychiatrist) {
      _openClinicianLogin();
      return;
    }
    setState(() => _role = role);
  }

  @override
  Widget build(BuildContext context) {
    final isRegister = _mode == AuthMode.register;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _AuthAtmosphere(),
          SafeArea(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.only(bottom: bottomInset > 0 ? 8 : 0),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        ScaleTransition(
                          scale: _brandScale,
                          child: _BrandHeader(isRegister: isRegister),
                        ),
                        const SizedBox(height: 28),
                        _ModeToggle(
                          mode: _mode,
                          onChanged: _switchMode,
                        ),
                        const SizedBox(height: 22),
                        FadeTransition(
                          opacity: _formOpacity,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _RolePicker(
                                  role: _role,
                                  onChanged: _onRoleChanged,
                                ),
                                const SizedBox(height: 18),
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOutCubic,
                                  alignment: Alignment.topCenter,
                                  child: isRegister
                                      ? Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 14),
                                          child: TextFormField(
                                            controller: _nameController,
                                            textCapitalization:
                                                TextCapitalization.words,
                                            textInputAction:
                                                TextInputAction.next,
                                            decoration: const InputDecoration(
                                              labelText: 'Full name',
                                              hintText: 'Name as shown in app',
                                            ),
                                            validator: (v) {
                                              if (!isRegister) return null;
                                              if (v == null ||
                                                  v.trim().length < 2) {
                                                return 'Enter your full name';
                                              }
                                              return null;
                                            },
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autocorrect: false,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    hintText: 'name@email.com',
                                  ),
                                  validator: (v) {
                                    final value = v?.trim() ?? '';
                                    if (value.isEmpty) {
                                      return 'Email is required';
                                    }
                                    if (!value.contains('@') ||
                                        !value.contains('.')) {
                                      return 'Enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: isRegister
                                      ? TextInputAction.next
                                      : TextInputAction.done,
                                  onFieldSubmitted:
                                      isRegister ? null : (_) => _submit(),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: 'At least 6 characters',
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: CuramindColors.inkMuted,
                                      ),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOutCubic,
                                  alignment: Alignment.topCenter,
                                  child: isRegister
                                      ? Padding(
                                          padding:
                                              const EdgeInsets.only(top: 14),
                                          child: TextFormField(
                                            controller: _confirmController,
                                            obscureText: _obscureConfirm,
                                            textInputAction:
                                                TextInputAction.done,
                                            onFieldSubmitted: (_) => _submit(),
                                            decoration: InputDecoration(
                                              labelText: 'Confirm password',
                                              hintText: 'Re-enter password',
                                              suffixIcon: IconButton(
                                                onPressed: () => setState(
                                                  () => _obscureConfirm =
                                                      !_obscureConfirm,
                                                ),
                                                icon: Icon(
                                                  _obscureConfirm
                                                      ? Icons
                                                          .visibility_outlined
                                                      : Icons
                                                          .visibility_off_outlined,
                                                  color:
                                                      CuramindColors.inkMuted,
                                                ),
                                              ),
                                            ),
                                            validator: (v) {
                                              if (!isRegister) return null;
                                              if (v !=
                                                  _passwordController.text) {
                                                return 'Passwords do not match';
                                              }
                                              return null;
                                            },
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                                const SizedBox(height: 24),
                                CursorHoverRegion(
                                  child: FilledButton(
                                    onPressed: _loading ? null : _submit,
                                    child: _loading
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              color: CuramindColors.white,
                                            ),
                                          )
                                        : Text(
                                            isRegister
                                                ? 'Create account'
                                                : 'Sign in',
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                CursorHoverRegion(
                                  child: TextButton(
                                    onPressed: _loading
                                        ? null
                                        : () => _switchMode(
                                              isRegister
                                                  ? AuthMode.login
                                                  : AuthMode.register,
                                            ),
                                    child: Text(
                                      isRegister
                                          ? 'Already have an account? Sign in'
                                          : 'New here? Create an account',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Curamind is not a substitute for emergency services. '
                          'If you are in crisis, contact local professional help.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            height: 1.45,
                            color: CuramindColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthAtmosphere extends StatelessWidget {
  const _AuthAtmosphere();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE6EEF0),
            Color(0xFFE8F0EC),
            Color(0xFFDDE8EB),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: _Blob(
              size: 220,
              color: CuramindColors.sage.withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -50,
            child: _Blob(
              size: 260,
              color: CuramindColors.slate.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            top: 180,
            left: -30,
            child: _Blob(
              size: 120,
              color: CuramindColors.mistBlue.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.isRegister});

  final bool isRegister;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Curamind',
          textAlign: TextAlign.center,
          style: GoogleFonts.fraunces(
            fontSize: 44,
            height: 1.05,
            fontWeight: FontWeight.w600,
            color: CuramindColors.ink,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: Text(
            isRegister
                ? 'Create an account to start tracking your daily journey.'
                : 'A calm clinical companion for patients & psychiatrists.',
            key: ValueKey(isRegister),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 15,
              height: 1.45,
              color: CuramindColors.inkMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.mode,
    required this.onChanged,
  });

  final AuthMode mode;
  final ValueChanged<AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CuramindColors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CuramindColors.sageSoft),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleChip(
              label: 'Sign in',
              selected: mode == AuthMode.login,
              onTap: () => onChanged(AuthMode.login),
            ),
          ),
          Expanded(
            child: _ToggleChip(
              label: 'Register',
              selected: mode == AuthMode.register,
              onTap: () => onChanged(AuthMode.register),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? CuramindColors.sageDeep : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Material(
        color: Colors.transparent,
        child: CursorHoverRegion(
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? CuramindColors.white
                      : CuramindColors.inkMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RolePicker extends StatelessWidget {
  const _RolePicker({
    required this.role,
    required this.onChanged,
  });

  final UserRole role;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Continue as',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: CuramindColors.inkMuted,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _RoleCard(
                title: 'Patient',
                subtitle: 'Diary & adherence',
                icon: Icons.favorite_outline_rounded,
                selected: role == UserRole.patient,
                onTap: () => onChanged(UserRole.patient),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RoleCard(
                title: 'Psychiatrist',
                subtitle: 'Clinic monitoring',
                icon: Icons.medical_services_outlined,
                selected: role == UserRole.psychiatrist,
                onTap: () => onChanged(UserRole.psychiatrist),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected
            ? CuramindColors.sageSoft.withValues(alpha: 0.85)
            : CuramindColors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? CuramindColors.sage : CuramindColors.sageSoft,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: CursorHoverRegion(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: selected
                        ? CuramindColors.sageDeep
                        : CuramindColors.inkMuted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      color: CuramindColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: CuramindColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
