import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../animated_cursor.dart';
import '../../services/auth_service.dart';
import '../../theme/curamind_theme.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({
    super.key,
    this.initialEmail = '',
  });

  final String initialEmail;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _loading = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await AuthService.instance.sendPasswordResetEmail(_emailController.text);
      if (!mounted) return;
      setState(() => _sent = true);
    } on AuthFailure catch (e) {
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
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE6EEF0), Color(0xFFE8F0EC), Color(0xFFDDE8EB)],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: CursorHoverRegion(
                          child: TextButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text('Back'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Reset password',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fraunces(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: CuramindColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _sent
                            ? 'If an account exists for that email, a reset link is on the way.'
                            : 'Enter your account email. We’ll send a secure reset link.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          height: 1.45,
                          color: CuramindColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: CuramindColors.white.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: CuramindColors.mistBlue),
                        ),
                        child: _sent
                            ? Column(
                                children: [
                                  const Icon(
                                    Icons.mark_email_read_outlined,
                                    size: 40,
                                    color: CuramindColors.sageDeep,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Check ${_emailController.text.trim()}',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                      color: CuramindColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Open the link in the email to choose a new password. '
                                    'The link opens Curamind and takes you to the reset screen. '
                                    'Check spam if needed.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      height: 1.45,
                                      color: CuramindColors.inkMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  CursorHoverRegion(
                                    child: FilledButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Back to sign in'),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  CursorHoverRegion(
                                    child: TextButton(
                                      onPressed: _loading
                                          ? null
                                          : () {
                                              setState(() => _sent = false);
                                              _submit();
                                            },
                                      child: const Text('Resend reset email'),
                                    ),
                                  ),
                                ],
                              )
                            : Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      autocorrect: false,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _submit(),
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
                                    const SizedBox(height: 20),
                                    CursorHoverRegion(
                                      child: FilledButton(
                                        onPressed: _loading ? null : _submit,
                                        child: _loading
                                            ? const SizedBox(
                                                height: 22,
                                                width: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.4,
                                                  color: CuramindColors.white,
                                                ),
                                              )
                                            : const Text('Send reset link'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
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
