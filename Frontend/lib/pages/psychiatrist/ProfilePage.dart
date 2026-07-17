import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../services/profile_photo_service.dart';
import '../../theme/curamind_theme.dart';
import '../../widgets/notification_settings_card.dart';
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

  Uint8List? _photoBytes;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _savingPassword = false;
  bool _savingProfile = false;
  bool _pickingPhoto = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final user = await AuthService.instance.resolveCurrentUser();
    final bytes = await ProfilePhotoService.instance.loadBytes();
    if (!mounted) return;
    setState(() {
      _nameController.text = user?.fullName ?? widget.name;
      _roleController.text =
          user?.role == 'PSYCHIATRIST' ? 'Psychiatrist' : widget.role;
      _photoBytes = bytes;
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
          content: Text('Password updated.', style: GoogleFonts.outfit(color: CuramindColors.white)),
        ),
      );
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _savingPassword = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: CuramindColors.danger,
          content: Text(e.message, style: GoogleFonts.outfit(color: CuramindColors.white)),
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _savingProfile = true);
    try {
      final user = await AuthService.instance.updateProfile(
        fullName: _nameController.text,
        avatarKey: 'photo',
      );
      if (!mounted) return;
      setState(() {
        _savingProfile = false;
        _nameController.text = user.fullName;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: CuramindColors.sageDeep,
          content: Text('Profile updated.', style: GoogleFonts.outfit(color: CuramindColors.white)),
        ),
      );
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _savingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: CuramindColors.danger,
          content: Text(e.message, style: GoogleFonts.outfit(color: CuramindColors.white)),
        ),
      );
    }
  }

  Future<void> _pickPhoto() async {
    setState(() => _pickingPhoto = true);
    try {
      final bytes = await ProfilePhotoService.instance.pickAndSave();
      if (!mounted) return;
      if (bytes != null) {
        setState(() => _photoBytes = bytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: CuramindColors.sageDeep,
            content: Text('Profile photo updated.', style: GoogleFonts.outfit(color: CuramindColors.white)),
          ),
        );
      }
    } on AuthFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: CuramindColors.danger,
          content: Text(e.message, style: GoogleFonts.outfit(color: CuramindColors.white)),
        ),
      );
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
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
          return FadeTransition(opacity: animation, child: const AuthGate());
        },
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final body = AnimatedPadding(
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
                  Text('Profile', textAlign: TextAlign.center, style: GoogleFonts.fraunces(fontSize: 32, fontWeight: FontWeight.w600, color: CuramindColors.ink)),
                  const SizedBox(height: 28),
                ],
                _ProfileHeader(
                  nameController: _nameController,
                  roleController: _roleController,
                  photoBytes: _photoBytes,
                  pickingPhoto: _pickingPhoto,
                  onPickPhoto: _pickPhoto,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _savingProfile ? null : _saveProfile,
                  child: _savingProfile
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: CuramindColors.white))
                      : const Text('Save profile'),
                ),
                const SizedBox(height: 28),
                const NotificationSettingsCard(),
                const SizedBox(height: 36),
                Text('Change Password', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: CuramindColors.ink)),
                const SizedBox(height: 18),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PasswordField(label: 'Current Password', controller: _currentPasswordController, obscure: _obscureCurrent, onToggleObscure: () => setState(() => _obscureCurrent = !_obscureCurrent), textInputAction: TextInputAction.next, validator: (v) { if (v == null || v.isEmpty) return 'Current password is required'; if (v.length < 6) return 'Password must be at least 6 characters'; return null; }),
                      const SizedBox(height: 14),
                      _PasswordField(label: 'New Password', controller: _newPasswordController, obscure: _obscureNew, onToggleObscure: () => setState(() => _obscureNew = !_obscureNew), textInputAction: TextInputAction.next, validator: (v) { if (v == null || v.isEmpty) return 'New password is required'; if (v.length < 6) return 'Password must be at least 6 characters'; return null; }),
                      const SizedBox(height: 14),
                      _PasswordField(label: 'Confirm New Password', controller: _confirmPasswordController, obscure: _obscureConfirm, onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm), textInputAction: TextInputAction.done, onFieldSubmitted: (_) => _updatePassword(), validator: (v) { if (v != _newPasswordController.text) return 'Passwords do not match'; return null; }),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: _savingPassword ? null : _updatePassword,
                        child: _savingPassword
                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: CuramindColors.white))
                            : const Text('Update password'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                OutlinedButton(onPressed: _logOut, child: const Text('Sign out')),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.embedded) return ColoredBox(color: CuramindColors.mist, child: body);
    return Scaffold(backgroundColor: CuramindColors.mist, body: body);
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.nameController, required this.roleController, required this.photoBytes, required this.pickingPhoto, required this.onPickPhoto});
  final TextEditingController nameController;
  final TextEditingController roleController;
  final Uint8List? photoBytes;
  final bool pickingPhoto;
  final VoidCallback onPickPhoto;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CuramindColors.mistBlue,
                  border: Border.all(color: CuramindColors.slate, width: 1.4),
                  image: photoBytes != null ? DecorationImage(image: MemoryImage(photoBytes!), fit: BoxFit.cover) : null,
                ),
                child: photoBytes == null ? const Icon(Icons.person_outline_rounded, size: 36, color: CuramindColors.ocean) : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: CuramindColors.ocean,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: pickingPhoto ? null : onPickPhoto,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: pickingPhoto
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: CuramindColors.white))
                          : const Icon(Icons.upload_rounded, size: 18, color: CuramindColors.white),
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
              TextField(controller: nameController, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 10),
              TextField(controller: roleController, readOnly: true, decoration: const InputDecoration(labelText: 'Role')),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: pickingPhoto ? null : onPickPhoto,
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Upload photo'),
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
  const _PasswordField({required this.label, required this.controller, required this.obscure, required this.onToggleObscure, required this.validator, this.textInputAction, this.onFieldSubmitted});
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
          icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: CuramindColors.inkMuted),
        ),
      ),
    );
  }
}
