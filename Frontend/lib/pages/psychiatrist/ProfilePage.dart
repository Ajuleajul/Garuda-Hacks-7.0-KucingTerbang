import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../theme/curamind_theme.dart';
import '../patient/AuthGate.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.name = 'Dr. Ada Lim',
    this.role = 'Psychiatrist',
    this.embedded = false,
    this.onSignedOut,
  });

  final String name;
  final String role;
  final bool embedded;
  final VoidCallback? onSignedOut;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _savingPassword = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.name;
    _roleController.text = widget.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _savingPassword = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _savingPassword = false);

    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: CuramindColors.sageDeep,
        content: Text(
          'Password updated (demo, no backend).',
          style: GoogleFonts.outfit(color: CuramindColors.white),
        ),
      ),
    );
  }

  Future<void> _logOut() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    if (widget.onSignedOut != null) {
      widget.onSignedOut!();
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 360),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: const AuthGate(),
          );
        },
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: CuramindColors.mist,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _ProfileAtmosphere(),
          SafeArea(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.only(bottom: bottomInset > 0 ? 8 : 0),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!widget.embedded) ...[
                          Text(
                            'Profile',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.fraunces(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: CuramindColors.ink,
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],
                        _ProfileHeader(
                          nameController: _nameController,
                          roleController: _roleController,
                        ),
                        const SizedBox(height: 36),
                        Text(
                          'Change Password',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: CuramindColors.ink,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _PasswordField(
                                label: 'Current Password',
                                controller: _currentPasswordController,
                                obscure: _obscureCurrent,
                                onToggleObscure: () => setState(
                                  () => _obscureCurrent = !_obscureCurrent,
                                ),
                                textInputAction: TextInputAction.next,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Current password is required';
                                  }
                                  if (v.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              _PasswordField(
                                label: 'New Password',
                                controller: _newPasswordController,
                                obscure: _obscureNew,
                                onToggleObscure: () => setState(
                                  () => _obscureNew = !_obscureNew,
                                ),
                                textInputAction: TextInputAction.next,
                                validator: (v) {
                                  if (v == null || v.length < 6) {
                                    return 'New password must be at least 6 characters';
                                  }
                                  if (v == _currentPasswordController.text) {
                                    return 'New password must be different';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              _PasswordField(
                                label: 'Re-confirm Password',
                                controller: _confirmPasswordController,
                                obscure: _obscureConfirm,
                                onToggleObscure: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _updatePassword(),
                                validator: (v) {
                                  if (v != _newPasswordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              FilledButton(
                                onPressed:
                                    _savingPassword ? null : _updatePassword,
                                child: _savingPassword
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: CuramindColors.white,
                                        ),
                                      )
                                    : const Text('Update password'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 200),
                            child: OutlinedButton(
                              onPressed: _logOut,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: CuramindColors.ocean,
                                side: const BorderSide(
                                  color: CuramindColors.slate,
                                  width: 1.4,
                                ),
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                textStyle: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('Log out'),
                            ),
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.nameController,
    required this.roleController,
  });

  final TextEditingController nameController;
  final TextEditingController roleController;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: CuramindColors.mistBlue,
            border: Border.all(color: CuramindColors.slate, width: 1.4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 32,
                color: CuramindColors.ocean,
              ),
              const SizedBox(height: 4),
              Text(
                'Photo',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: CuramindColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: roleController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Role',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
    required this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final String? Function(String?) validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          onPressed: onToggleObscure,
          icon: Icon(
            obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: CuramindColors.inkMuted,
          ),
        ),
      ),
    );
  }
}

class _ProfileAtmosphere extends StatelessWidget {
  const _ProfileAtmosphere();

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
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CuramindColors.sage.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -70,
            left: -50,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CuramindColors.slate.withValues(alpha: 0.10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
