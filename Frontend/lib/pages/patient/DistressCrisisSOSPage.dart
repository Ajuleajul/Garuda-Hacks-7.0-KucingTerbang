import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/curamind_theme.dart';

/// Extreme crisis mode — low contrast, no auto-dial.
/// Open via [DistressCrisisSOSPage.open] so Home SOS never jumps to the phone.
class DistressCrisisSOSPage extends StatefulWidget {
  const DistressCrisisSOSPage({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const DistressCrisisSOSPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<DistressCrisisSOSPage> createState() => _DistressCrisisSOSPageState();
}

class _DistressCrisisSOSPageState extends State<DistressCrisisSOSPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  bool _showBreath = false;
  bool _showGround = false;
  bool _showSafePerson = false;
  int _groundTick = 0;

  // Soft demo contacts — replace with Safety Plan data later
  static const _safeName = 'Maya (trusted person)';
  static const _safePhone = '+62 812 0000 0000';
  static const _crisisLine = 'Local crisis line';
  static const _crisisPhone = '119 (or your local number)';
  static const _emergencyLabel = 'Emergency services';
  static const _emergencyNumber = '112';

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.92, end: 1.04).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _copy(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: CuramindColors.ocean.withValues(alpha: 0.92),
        content: Text(
          '$label copied. Paste it in Phone when you are ready.',
          style: GoogleFonts.outfit(color: CuramindColors.white),
        ),
      ),
    );
  }

  Future<void> _confirmEmergency() async {
    final go = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFFE8EEF0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Emergency help',
                style: GoogleFonts.fraunces(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: CuramindColors.ink.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Nothing will dial by itself. If you continue, we only show '
                'the number so you can call when you choose.',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  height: 1.45,
                  color: CuramindColors.inkMuted,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: CuramindColors.ocean,
                  foregroundColor: CuramindColors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Show emergency number'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Stay here instead'),
              ),
            ],
          ),
        );
      },
    );

    if (go != true || !mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF2F6F7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            _emergencyLabel,
            style: GoogleFonts.fraunces(
              fontWeight: FontWeight.w600,
              color: CuramindColors.ink.withValues(alpha: 0.88),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Number',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: CuramindColors.inkMuted,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                _emergencyNumber,
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: CuramindColors.ocean,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Open your Phone app and dial when you feel ready. '
                'Curamind will not place the call for you.',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  height: 1.4,
                  color: CuramindColors.inkMuted,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _copy('Emergency number', _emergencyNumber);
              },
              child: const Text('Copy number'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _leave() {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    // Soft, low-contrast palette — avoid bright red / high arousal
    const bg = Color(0xFFE4EBED);
    final inkSoft = CuramindColors.ink.withValues(alpha: 0.72);
    final muted = CuramindColors.inkMuted.withValues(alpha: 0.9);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _leave,
                      style: TextButton.styleFrom(
                        foregroundColor: muted,
                      ),
                      child: const Text('I’m okay for now'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crisis mode',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fraunces(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: inkSoft,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'You are safe enough to pause.\n'
                    'Nothing here will call anyone automatically.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      height: 1.5,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ScaleTransition(
                    scale: _scale,
                    child: Container(
                      height: 140,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: CuramindColors.sageSoft.withValues(alpha: 0.55),
                        border: Border.all(
                          color: CuramindColors.sage.withValues(alpha: 0.28),
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        'Breathe\nslowly',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: CuramindColors.sageDeep.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SoftAction(
                    title: 'Breathe with me',
                    subtitle: 'A quiet 4-second rhythm. No countdown pressure.',
                    expanded: _showBreath,
                    onTap: () => setState(() {
                      _showBreath = !_showBreath;
                      if (_showBreath) _showGround = false;
                    }),
                    child: Text(
                      'Inhale as the circle grows.\n'
                      'Exhale as it softens.\n'
                      'You can stop anytime.',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        height: 1.5,
                        color: muted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SoftAction(
                    title: 'Ground for a minute',
                    subtitle: 'Name what is here, one sense at a time.',
                    expanded: _showGround,
                    onTap: () => setState(() {
                      _showGround = !_showGround;
                      if (_showGround) {
                        _showBreath = false;
                        _groundTick = 0;
                      }
                    }),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...List.generate(_groundPrompts.length, (i) {
                          final on = _groundTick >= i;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              _groundPrompts[i],
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                height: 1.4,
                                color: on
                                    ? inkSoft
                                    : muted.withValues(alpha: 0.55),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 4),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              if (_groundTick < _groundPrompts.length) {
                                _groundTick++;
                              }
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: CuramindColors.ocean,
                            side: BorderSide(
                              color: CuramindColors.slate.withValues(alpha: 0.45),
                            ),
                            minimumSize: const Size.fromHeight(46),
                          ),
                          child: Text(
                            _groundTick >= _groundPrompts.length
                                ? 'Done — well noticed'
                                : 'Next sense',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SoftAction(
                    title: 'Reach a safe person',
                    subtitle: 'Shows a contact. You choose if and when to call.',
                    expanded: _showSafePerson,
                    onTap: () => setState(() => _showSafePerson = !_showSafePerson),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _safeName,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: inkSoft,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          _safePhone,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            color: CuramindColors.ocean,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => _copy('Safe person number', _safePhone),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: CuramindColors.ocean,
                            side: BorderSide(
                              color: CuramindColors.slate.withValues(alpha: 0.45),
                            ),
                            minimumSize: const Size.fromHeight(46),
                          ),
                          child: const Text('Copy number'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_crisisLine · $_crisisPhone',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            height: 1.4,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Only if you need it',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      letterSpacing: 0.3,
                      color: muted.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _confirmEmergency,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CuramindColors.danger,
                      side: BorderSide(
                        color: CuramindColors.danger.withValues(alpha: 0.45),
                      ),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('I need emergency services'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Curamind is a companion, not emergency care.\n'
                    'You are allowed to take this one step at a time.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      height: 1.45,
                      color: muted.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _leave,
                    style: TextButton.styleFrom(
                      foregroundColor: CuramindColors.sageDeep,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Leave crisis mode'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const _groundPrompts = [
    '5 — Look around. Name five things you can see.',
    '4 — Feel four points of contact (feet, seat, hands…).',
    '3 — Notice three sounds, near or far.',
    '2 — Find two scents, or recall a calm smell.',
    '1 — Notice one taste, or take a slow sip of water.',
  ];
}

class _SoftAction extends StatelessWidget {
  const _SoftAction({
    required this.title,
    required this.subtitle,
    required this.expanded,
    required this.onTap,
    required this.child,
  });

  final String title;
  final String subtitle;
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CuramindColors.white.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: CuramindColors.mistBlue.withValues(alpha: 0.9),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: CuramindColors.ink.withValues(alpha: 0.78),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            height: 1.35,
                            color: CuramindColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: CuramindColors.inkMuted,
                  ),
                ],
              ),
              if (expanded) ...[
                const SizedBox(height: 12),
                child,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
