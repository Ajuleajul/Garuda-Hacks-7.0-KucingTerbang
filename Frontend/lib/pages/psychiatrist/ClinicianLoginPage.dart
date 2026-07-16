import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/curamind_theme.dart';
import '../patient/AuthPage.dart';

enum ClinicianAuthMode { login, register }

class ClinicianLoginPage extends StatefulWidget {
  const ClinicianLoginPage({super.key});

  @override
  State<ClinicianLoginPage> createState() => _ClinicianLoginPageState();
}

class _ClinicianLoginPageState extends State<ClinicianLoginPage>
    with SingleTickerProviderStateMixin {
  ClinicianAuthMode _mode = ClinicianAuthMode.login;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  late final AnimationController _formFade;
  late final Animation<double> _formOpacity;

  @override
  void initState() {
    super.initState();
    _formFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 1,
    );
    _formOpacity = CurvedAnimation(parent: _formFade, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _formFade.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _switchMode(ClinicianAuthMode next) async {
    if (next == _mode) return;
    await _formFade.reverse();
    setState(() => _mode = next);
    await _formFade.forward();
  }

  void _goToPatientAuth() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 360),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: const AuthPage(),
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _loading = false);

    final action =
        _mode == ClinicianAuthMode.login ? 'Signed in' : 'Registered';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: CuramindColors.sageDeep,
        content: Text(
          '$action successfully as Psychiatrist (demo, no backend).',
          style: GoogleFonts.outfit(color: CuramindColors.white),
        ),
      ),
    );

    final displayName = _mode == ClinicianAuthMode.register
        ? _nameController.text.trim()
        : _emailController.text.trim().split('@').first;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: _ClinicianSuccessPlaceholder(name: displayName),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRegister = _mode == ClinicianAuthMode.register;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _ClinicianAtmosphere(),
          SafeArea(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.only(bottom: bottomInset > 0 ? 8 : 0),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _loading ? null : _goToPatientAuth,
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text('Back to patient'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Curamind',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fraunces(
                            fontSize: 40,
                            height: 1.05,
                            fontWeight: FontWeight.w600,
                            color: CuramindColors.ink,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'CLINIC',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.4,
                            color: CuramindColors.coral,
                          ),
                        ),
                        const SizedBox(height: 10),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          child: Text(
                            isRegister
                                ? 'Create a psychiatrist account to monitor linked patients.'
                                : 'Sign in for monitoring, prescriptions, and clinical reports.',
                            key: ValueKey(isRegister),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              height: 1.45,
                              color: CuramindColors.inkMuted,
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color:
                                CuramindColors.white.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: CuramindColors.sageSoft),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _ModeChip(
                                  label: 'Sign in',
                                  selected:
                                      _mode == ClinicianAuthMode.login,
                                  onTap: () =>
                                      _switchMode(ClinicianAuthMode.login),
                                ),
                              ),
                              Expanded(
                                child: _ModeChip(
                                  label: 'Register',
                                  selected:
                                      _mode == ClinicianAuthMode.register,
                                  onTap: () => _switchMode(
                                    ClinicianAuthMode.register,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        FadeTransition(
                          opacity: _formOpacity,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AnimatedSize(
                                  duration:
                                      const Duration(milliseconds: 280),
                                  curve: Curves.easeOutCubic,
                                  alignment: Alignment.topCenter,
                                  child: isRegister
                                      ? Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 14,
                                          ),
                                          child: TextFormField(
                                            controller: _nameController,
                                            textCapitalization:
                                                TextCapitalization.words,
                                            textInputAction:
                                                TextInputAction.next,
                                            decoration:
                                                const InputDecoration(
                                              labelText: 'Full name',
                                              hintText:
                                                  'Dr. / practice name',
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
                                    labelText: 'Clinic email',
                                    hintText: 'name@clinic.com',
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
                                  duration:
                                      const Duration(milliseconds: 280),
                                  curve: Curves.easeOutCubic,
                                  alignment: Alignment.topCenter,
                                  child: isRegister
                                      ? Padding(
                                          padding: const EdgeInsets.only(
                                            top: 14,
                                          ),
                                          child: TextFormField(
                                            controller: _confirmController,
                                            obscureText: _obscureConfirm,
                                            textInputAction:
                                                TextInputAction.done,
                                            onFieldSubmitted: (_) =>
                                                _submit(),
                                            decoration: InputDecoration(
                                              labelText:
                                                  'Confirm password',
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
                                                  color: CuramindColors
                                                      .inkMuted,
                                                ),
                                              ),
                                            ),
                                            validator: (v) {
                                              if (!isRegister) return null;
                                              if (v !=
                                                  _passwordController
                                                      .text) {
                                                return 'Passwords do not match';
                                              }
                                              return null;
                                            },
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                                const SizedBox(height: 24),
                                FilledButton(
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
                                              ? 'Create psychiatrist account'
                                              : 'Sign in to clinic',
                                        ),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: _loading
                                      ? null
                                      : () => _switchMode(
                                            isRegister
                                                ? ClinicianAuthMode.login
                                                : ClinicianAuthMode
                                                    .register,
                                          ),
                                  child: Text(
                                    isRegister
                                        ? 'Already have a clinic account? Sign in'
                                        : 'New here? Register as a psychiatrist',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Clinical access is for licensed professionals only. '
                          'Protect patient confidentiality at all times.',
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

class _ModeChip extends StatelessWidget {
  const _ModeChip({
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
    );
  }
}

class _ClinicianAtmosphere extends StatelessWidget {
  const _ClinicianAtmosphere();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFFEAF3EE),
            Color(0xFFF0E8E4),
            Color(0xFFE2EBE6),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CuramindColors.coral.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -40,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CuramindColors.sage.withValues(alpha: 0.14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicianSuccessPlaceholder extends StatelessWidget {
  const _ClinicianSuccessPlaceholder({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _ClinicianAtmosphere(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => const ClinicianLoginPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Sign out'),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Curamind Clinic',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fraunces(
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                      color: CuramindColors.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Hello, $name',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: CuramindColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You are signed in as a Psychiatrist.\n'
                    'Monitoring dashboard coming next.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      height: 1.45,
                      color: CuramindColors.inkMuted,
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
