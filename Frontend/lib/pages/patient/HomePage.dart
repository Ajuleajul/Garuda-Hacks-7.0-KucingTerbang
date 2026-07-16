import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/curamind_theme.dart';
import 'DistressCrisisSOSPage.dart';

/// Patient shell indices:
/// 0 Home · 1 Diary · 2 Meds · 3 Distress · 4 Dashboard · 5 Link · 6 Profile
class PatientHomePage extends StatelessWidget {
  const PatientHomePage({
    super.key,
    required this.displayName,
    required this.onNavigate,
  });

  final String displayName;
  final ValueChanged<int> onNavigate;

  static const diaryIndex = 1;
  static const medsIndex = 2;
  static const distressIndex = 3;
  static const dashboardIndex = 4;
  static const linkIndex = 5;
  static const profileIndex = 6;

  static const _diaryDoneToday = false;
  static const _medsDue = 3;
  static const _medsTaken = 1;
  static const _avgMood7d = 6.2;
  static const _adherence7d = 0.86;
  static const _clinicianLinked = true;
  static const _clinicianName = 'Dr. Maya Santoso';

  String get _firstName {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? 'there' : parts.first;
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _dateLabel {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final n = DateTime.now();
    return '${days[n.weekday - 1]}, ${months[n.month - 1]} ${n.day}';
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: CuramindColors.mist,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GreetingHeader(
                  greeting: _greeting,
                  name: _firstName,
                  dateLabel: _dateLabel,
                ),
                const SizedBox(height: 14),
                _SosEntryCard(
                  onOpen: () => DistressCrisisSOSPage.open(context),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _GlanceChip(
                        label: 'Diary',
                        value: _diaryDoneToday ? 'Done' : 'Pending',
                        onTap: () => onNavigate(diaryIndex),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _GlanceChip(
                        label: 'Meds',
                        value: '$_medsTaken/${_medsTaken + _medsDue}',
                        onTap: () => onNavigate(medsIndex),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _GlanceChip(
                        label: '7d mood',
                        value: _avgMood7d.toStringAsFixed(1),
                        onTap: () => onNavigate(dashboardIndex),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _GlanceChip(
                        label: 'Adhere',
                        value: '${(_adherence7d * 100).round()}%',
                        onTap: () => onNavigate(dashboardIndex),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _PrimaryCta(
                  title: _diaryDoneToday
                      ? 'Review today’s diary'
                      : 'Log today’s diary',
                  subtitle: 'Mood, triggers, urges, and skills — about 2 minutes.',
                  icon: Icons.edit_note_outlined,
                  onTap: () => onNavigate(diaryIndex),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _SecondaryCta(
                        title: 'Meds',
                        subtitle: _medsDue > 0 ? '$_medsDue due' : 'All logged',
                        icon: Icons.medication_outlined,
                        onTap: () => onNavigate(medsIndex),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SecondaryCta(
                        title: 'Distress kit',
                        subtitle: 'Breathe · ground · plan',
                        icon: Icons.self_improvement_outlined,
                        onTap: () => onNavigate(distressIndex),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Quick actions',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CuramindColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                _QuickGrid(
                  items: [
                    _QuickItem(
                      label: 'Dashboard',
                      hint: 'Mood × meds',
                      icon: Icons.show_chart_outlined,
                      onTap: () => onNavigate(dashboardIndex),
                    ),
                    _QuickItem(
                      label: 'Clinician',
                      hint: _clinicianLinked ? _clinicianName : 'Link code',
                      icon: Icons.link_outlined,
                      onTap: () => onNavigate(linkIndex),
                    ),
                    _QuickItem(
                      label: 'Breathing',
                      hint: 'Calm skills',
                      icon: Icons.air_outlined,
                      onTap: () => onNavigate(distressIndex),
                    ),
                    _QuickItem(
                      label: 'Profile',
                      hint: 'Account',
                      icon: Icons.person_outline_rounded,
                      onTap: () => onNavigate(profileIndex),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Material(
                  color: CuramindColors.sageSoft.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onNavigate(linkIndex),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(
                            _clinicianLinked
                                ? Icons.verified_outlined
                                : Icons.link_off_outlined,
                            color: CuramindColors.sageDeep,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _clinicianLinked
                                  ? 'Linked with $_clinicianName'
                                  : 'Not linked to a clinician yet',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: CuramindColors.ink,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: CuramindColors.inkMuted,
                          ),
                        ],
                      ),
                    ),
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

/// Large SOS entry — muted red, never auto-dials.
class _SosEntryCard extends StatelessWidget {
  const _SosEntryCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CuramindColors.danger.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: CuramindColors.danger.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: CuramindColors.danger.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: CuramindColors.danger.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'SOS',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: CuramindColors.danger,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crisis mode',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CuramindColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Opens a calm screen first. No automatic phone call.',
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
                Icons.arrow_forward_rounded,
                color: CuramindColors.danger.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({
    required this.greeting,
    required this.name,
    required this.dateLabel,
  });

  final String greeting;
  final String name;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CuramindColors.sageSoft.withValues(alpha: 0.85),
            CuramindColors.mistBlue.withValues(alpha: 0.9),
            CuramindColors.white.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CuramindColors.mistBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateLabel,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: CuramindColors.inkMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$greeting, $name',
            style: GoogleFonts.fraunces(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              height: 1.15,
              color: CuramindColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start with diary, meds, or a calm skill — SOS is here if you need it.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              height: 1.4,
              color: CuramindColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlanceChip extends StatelessWidget {
  const _GlanceChip({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CuramindColors.white.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CuramindColors.mistBlue),
          ),
          child: Column(
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CuramindColors.sageDeep,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: CuramindColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CuramindColors.sageDeep,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: CuramindColors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: CuramindColors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CuramindColors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: CuramindColors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: CuramindColors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryCta extends StatelessWidget {
  const _SecondaryCta({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CuramindColors.white.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CuramindColors.mistBlue),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: CuramindColors.sageDeep),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  color: CuramindColors.ink,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: CuramindColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickItem {
  const _QuickItem({
    required this.label,
    required this.hint,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String hint;
  final IconData icon;
  final VoidCallback onTap;
}

class _QuickGrid extends StatelessWidget {
  const _QuickGrid({required this.items});

  final List<_QuickItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.15,
      ),
      itemBuilder: (context, i) {
        final item = items[i];
        return Material(
          color: CuramindColors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: item.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: CuramindColors.mistBlue),
              ),
              child: Row(
                children: [
                  Icon(item.icon, color: CuramindColors.sageDeep, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: CuramindColors.ink,
                          ),
                        ),
                        Text(
                          item.hint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: CuramindColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
