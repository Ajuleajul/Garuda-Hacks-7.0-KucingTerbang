import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../animated_cursor.dart';
import '../../services/auth_service.dart';
import '../../theme/curamind_theme.dart';

/// Shown after sign-up when Supabase requires email confirmation.
class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({
    super.key,
    required this.email,
    this.isClinician = false,
  });

  final String email;
  final bool isClinician;

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _resending = false;
  bool _sentAgain = false;

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _sentAgain = false;
    });
    try {
      await AuthService.instance.resendVerificationEmail(widget.email);
      if (!mounted) return;
      setState(() => _sentAgain = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: CuramindColors.sageDeep,
          content: Text(
            'Verification email sent again. Check inbox and spam.',
            style: GoogleFonts.outfit(color: CuramindColors.white),
          ),
        ),
      );
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
      if (mounted) setState(() => _resending = false);
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
                            label: const Text('Back to sign in'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: CuramindColors.white.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: CuramindColors.mistBlue),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: CuramindColors.sageSoft,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.mark_email_unread_outlined,
                                color: CuramindColors.sageDeep,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Verify your email',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.fraunces(
                                fontSize: 26,
                                fontWeight: FontWeight.w600,
                                color: CuramindColors.ink,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'We sent a confirmation link to',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: CuramindColors.inkMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.email,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: CuramindColors.sageDeep,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Open the email, tap the link, then come back here and sign in. '
                              'Check spam if you do not see it within a minute.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                height: 1.45,
                                color: CuramindColors.inkMuted,
                              ),
                            ),
                            if (_sentAgain) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Email resent.',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: CuramindColors.sageDeep,
                                ),
                              ),
                            ],
                            const SizedBox(height: 22),
                            CursorHoverRegion(
                              child: FilledButton(
                                onPressed: _resending ? null : _resend,
                                child: _resending
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: CuramindColors.white,
                                        ),
                                      )
                                    : const Text('Resend verification email'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            CursorHoverRegion(
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('I’ve verified — sign in'),
                              ),
                            ),
                          ],
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
