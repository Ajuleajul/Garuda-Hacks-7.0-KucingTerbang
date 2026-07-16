import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../theme/curamind_theme.dart';
import '../patient/AuthGate.dart';

const _avatarChoices = <String, IconData>{
  'person': Icons.person_outline_rounded,
  'favorite': Icons.favorite_outline_rounded,
  'selfcare': Icons.spa_outlined,
  'book': Icons.menu_book_outlined,
  'star': Icons.star_outline_rounded,
  'sun': Icons.wb_sunny_outlined,
};

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

  String _avatarKey = 'person';
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _savingPassword = false;
  bool _savingProfile = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final user = await AuthService.instance.resolveCurrentUser();
    if (!mounted) return;
    setState(() {
      _nameController.text = user?.fullName ?? widget.name;
      _roleController.text = user?.role == 'PSYCHIATRIST' ? 'Psychiatrist' : widget.role;
      _avatarKey = user?.avatarKey ?? 'person';
    });
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
    try {
      await AuthService.instance.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
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
            'Password updated.',
            style: GoogleFonts.outfit(color: CuramindColors.white),
          ),
        ),
      );
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _savingPassword = false);
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
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _savingProfile = true);
    try {
      final user = await AuthService.instance.updateProfile(
        fullName: _nameController.text,
        avatarKey: _avatarKey,
      );
      if (!mounted) return;
      setState(() {
        _savingProfile = false;
        _nameController.text = user.fullName;
        _avatarKey = user.avatarKey;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: CuramindColors.sageDeep,
          content: Text(
            'Profile updated.',
            style: GoogleFonts.outfit(color: CuramindColors.white),
          ),
        ),
      );
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _savingProfile = false);
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
    }
  }

  Future<void> _pickAvatar() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: CuramindColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _avatarChoices.entries.map((entry) {
              final selected = entry.key == _avatarKey;
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => Navigator.of(ctx).pop(entry.key),
                child: Container(
                  width: 88,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? CuramindColors.sageSoft
                        : CuramindColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected
                          ? CuramindColors.sage
                          : CuramindColors.mistBlue,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        entry.value,
                        color: CuramindColors.ocean,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.key,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: CuramindColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() => _avatarKey = picked);
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

    final body = Stack(
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
                        avatarKey: _avatarKey,
                        onPickAvatar: _pickAvatar,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _savingProfile ? null : _saveProfile,
                        child: _savingProfile
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: CuramindColors.white,
                                ),
                              )
                            : const Text('Save profile'),
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
    );

    if (widget.embedded) {
      return ColoredBox(color: CuramindColors.mist, child: body);
    }

    return Scaffold(
      backgroundColor: CuramindColors.mist,
      body: body,
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.nameController,
    required this.roleController,
    required this.avatarKey,
    required this.onPickAvatar,
  });

  final TextEditingController nameController;
  final TextEditingController roleController;
  final String avatarKey;
  final VoidCallback onPickAvatar;

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
          child: Stack(
            children: [
              Center(
                child: Icon(
                  _avatarChoices[avatarKey] ?? Icons.person_outline_rounded,
                  size: 36,
                  color: CuramindColors.ocean,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: CuramindColors.ocean,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onPickAvatar,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.photo_camera_outlined,
                        size: 18,
                        color: CuramindColors.white,
                      ),
                    ),
                  ),
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
