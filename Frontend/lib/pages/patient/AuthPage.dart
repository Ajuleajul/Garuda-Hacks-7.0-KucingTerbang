import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/curamind_theme.dart';

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
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _loading = false);

    final roleLabel =
        _role == UserRole.patient ? 'Pasien' : 'Psikiater';
    final action = _mode == AuthMode.login ? 'Masuk' : 'Daftar';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: CuramindColors.sageDeep,
        content: Text(
          '$action berhasil sebagai $roleLabel (demo, tanpa backend).',
          style: GoogleFonts.outfit(color: CuramindColors.white),
        ),
      ),
    );

    final displayName = _mode == AuthMode.register
        ? _nameController.text.trim()
        : _emailController.text.trim().split('@').first;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: _AuthSuccessPlaceholder(
              name: displayName,
              role: _role,
            ),
          );
        },
      ),
    );
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
                                  onChanged: (r) => setState(() => _role = r),
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
                                              labelText: 'Nama lengkap',
                                              hintText: 'Nama yang dipakai',
                                            ),
                                            validator: (v) {
                                              if (!isRegister) return null;
                                              if (v == null ||
                                                  v.trim().length < 2) {
                                                return 'Masukkan nama lengkap';
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
                                    hintText: 'nama@email.com',
                                  ),
                                  validator: (v) {
                                    final value = v?.trim() ?? '';
                                    if (value.isEmpty) {
                                      return 'Email wajib diisi';
                                    }
                                    if (!value.contains('@') ||
                                        !value.contains('.')) {
                                      return 'Format email tidak valid';
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
                                    hintText: 'Minimal 6 karakter',
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
                                      return 'Password minimal 6 karakter';
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
                                              labelText: 'Konfirmasi password',
                                              hintText: 'Ulangi password',
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
                                                return 'Password tidak cocok';
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
                                              ? 'Buat akun'
                                              : 'Masuk',
                                        ),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: _loading
                                      ? null
                                      : () => _switchMode(
                                            isRegister
                                                ? AuthMode.login
                                                : AuthMode.register,
                                          ),
                                  child: Text(
                                    isRegister
                                        ? 'Sudah punya akun? Masuk'
                                        : 'Belum punya akun? Daftar',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Curamind bukan pengganti layanan darurat. '
                          'Jika dalam krisis, hubungi bantuan profesional setempat.',
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
            Color(0xFFEAF3EE),
            Color(0xFFF3E9E4),
            Color(0xFFE4EDE8),
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
              color: CuramindColors.coral.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            top: 180,
            left: -30,
            child: _Blob(
              size: 120,
              color: CuramindColors.sageSoft.withValues(alpha: 0.55),
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
                ? 'Buat akun untuk mulai mendampingi perjalanan harianmu.'
                : 'Pendamping klinis yang tenang untuk pasien & psikiater.',
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
              label: 'Masuk',
              selected: mode == AuthMode.login,
              onTap: () => onChanged(AuthMode.login),
            ),
          ),
          Expanded(
            child: _ToggleChip(
              label: 'Daftar',
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
          'Masuk sebagai',
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
                title: 'Pasien',
                subtitle: 'Diary & kepatuhan',
                icon: Icons.favorite_outline_rounded,
                selected: role == UserRole.patient,
                onTap: () => onChanged(UserRole.patient),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RoleCard(
                title: 'Psikiater',
                subtitle: 'Monitoring klinik',
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
    );
  }
}

class _AuthSuccessPlaceholder extends StatelessWidget {
  const _AuthSuccessPlaceholder({
    required this.name,
    required this.role,
  });

  final String name;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final roleLabel =
        role == UserRole.patient ? 'Pasien' : 'Psikiater';

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _AuthAtmosphere(),
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
                            builder: (_) => const AuthPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Keluar'),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Curamind',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fraunces(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: CuramindColors.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Halo, $name',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: CuramindColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kamu masuk sebagai $roleLabel.\n'
                    'Shell beranda per-role menyusul.',
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
