import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/curamind_theme.dart';

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

  // Demo snapshot — swap for live API later
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

  String get _tip {
    final tips = [
      'A 60-second body scan can lower arousal before you log mood.',
      'If urges rise, open Distress Kit before deciding anything else.',
      'Missed a dose? Log it honestly — trends matter more than perfect days.',
      'One short diary entry beats skipping the day entirely.',
    ];
    return tips[DateTime.now().day % tips.length];
  }

  @override
  Widget build(BuildContext context) {
    final attention = <_AttentionItem>[
      if (!_diaryDoneToday)
        _AttentionItem(
          title: 'Diary not logged yet',
          subtitle: 'Capture mood, urges, and skills for today.',
          icon: Icons.edit_note_outlined,
          actionLabel: 'Open diary',
          onTap: () => onNavigate(diaryIndex),
        ),
      if (_medsDue > 0)
        _AttentionItem(
          title: '$_medsDue dose${_medsDue == 1 ? '' : 's'} still due',
          subtitle: '$_medsTaken taken so far today.',
          icon: Icons.medication_outlined,
          actionLabel: 'Log meds',
          onTap: () => onNavigate(medsIndex),
        ),
      if (!_clinicianLinked)
        _AttentionItem(
          title: 'No clinician linked',
          subtitle: 'Connect with an invite code to share monitoring.',
          icon: Icons.link_outlined,
          actionLabel: 'Link now',
          onTap: () => onNavigate(linkIndex),
        ),
    ];

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
                const SizedBox(height: 16),
                _TodayGlance(
                  diaryDone: _diaryDoneToday,
                  medsTaken: _medsTaken,
                  medsDue: _medsDue + _medsTaken,
                  avgMood: _avgMood7d,
                  adherence: _adherence7d,
                  onDiary: () => onNavigate(diaryIndex),
                  onMeds: () => onNavigate(medsIndex),
                  onDashboard: () => onNavigate(dashboardIndex),
                ),
                const SizedBox(height: 16),
                _PrimaryCta(
                  title: _diaryDoneToday ? 'Review today’s diary' : 'Log today’s diary',
                  subtitle: _diaryDoneToday
                      ? 'Update mood, urges, or coping notes anytime.'
                      : 'Mood, triggers, urges, and DBT skills — about 2 minutes.',
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
                        subtitle: 'Breathe · ground · SOS',
                        icon: Icons.self_improvement_outlined,
                        emphasize: true,
                        onTap: () => onNavigate(distressIndex),
                      ),
                    ),
                  ],
                ),
                if (attention.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Needs attention',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: CuramindColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...attention.map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _AttentionCard(item: a),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
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
                      label: 'Breathing',
                      hint: 'Calm down',
                      icon: Icons.air_outlined,
                      onTap: () => onNavigate(distressIndex),
                    ),
                    _QuickItem(
                      label: 'Clinician',
                      hint: _clinicianLinked ? _clinicianName : 'Link code',
                      icon: Icons.link_outlined,
                      onTap: () => onNavigate(linkIndex),
                    ),
                    _QuickItem(
                      label: 'Profile',
                      hint: 'Account',
                      icon: Icons.person_outline_rounded,
                      onTap: () => onNavigate(profileIndex),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _LinkStatusBanner(
                  linked: _clinicianLinked,
                  clinicianName: _clinicianName,
                  onTap: () => onNavigate(linkIndex),
                ),
                const SizedBox(height: 12),
                _TipCard(text: _tip),
                const SizedBox(height: 16),
                Text(
                  'Recent activity',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CuramindColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                _ActivityRow(
                  icon: Icons.medication_outlined,
                  title: 'Lamotrigine marked taken',
                  time: 'Today · 08:12',
                  onTap: () => onNavigate(medsIndex),
                ),
                _ActivityRow(
                  icon: Icons.show_chart_outlined,
                  title: '7-day mood average ${_avgMood7d.toStringAsFixed(1)}',
                  time: 'Dashboard',
                  onTap: () => onNavigate(dashboardIndex),
                ),
                _ActivityRow(
                  icon: Icons.self_improvement_outlined,
                  title: 'Breathing exercise completed',
                  time: 'Yesterday · 21:40',
                  onTap: () => onNavigate(distressIndex),
                ),
              ],
            ),
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
              fontWeight: FontWeight.w500,
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
            'Start with what feels doable — diary, meds, or a short calm skill.',
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

class _TodayGlance extends StatelessWidget {
  const _TodayGlance({
    required this.diaryDone,
    required this.medsTaken,
    required this.medsDue,
    required this.avgMood,
    required this.adherence,
    required this.onDiary,
    required this.onMeds,
    required this.onDashboard,
  });

  final bool diaryDone;
  final int medsTaken;
  final int medsDue;
  final double avgMood;
  final double adherence;
  final VoidCallback onDiary;
  final VoidCallback onMeds;
  final VoidCallback onDashboard;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GlanceChip(
            label: 'Diary',
            value: diaryDone ? 'Done' : 'Pending',
            color: diaryDone ? CuramindColors.sageDeep : CuramindColors.slate,
            onTap: onDiary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _GlanceChip(
            label: 'Meds',
            value: '$medsTaken/$medsDue',
            color: CuramindColors.ocean,
            onTap: onMeds,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _GlanceChip(
            label: '7d mood',
            value: avgMood.toStringAsFixed(1),
            color: CuramindColors.sageDeep,
            onTap: onDashboard,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _GlanceChip(
            label: 'Adhere',
            value: '${(adherence * 100).round()}%',
            color: CuramindColors.ocean,
            onTap: onDashboard,
          ),
        ),
      ],
    );
  }
}

class _GlanceChip extends StatelessWidget {
  const _GlanceChip({
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String value;
  final Color color;
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
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
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
                        height: 1.35,
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
    this.emphasize = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: emphasize
          ? CuramindColors.mistBlue
          : CuramindColors.white.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: emphasize ? CuramindColors.slate : CuramindColors.mistBlue,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: emphasize ? CuramindColors.ocean : CuramindColors.sageDeep,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CuramindColors.ink,
                ),
              ),
              const SizedBox(height: 2),
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

class _AttentionItem {
  const _AttentionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onTap;
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.item});

  final _AttentionItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CuramindColors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CuramindColors.mistBlue),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: CuramindColors.sageSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, size: 20, color: CuramindColors.sageDeep),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        color: CuramindColors.ink,
                      ),
                    ),
                    Text(
                      item.subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: CuramindColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                item.actionLabel,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: CuramindColors.ocean,
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

class _LinkStatusBanner extends StatelessWidget {
  const _LinkStatusBanner({
    required this.linked,
    required this.clinicianName,
    required this.onTap,
  });

  final bool linked;
  final String clinicianName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: linked
          ? CuramindColors.sageSoft.withValues(alpha: 0.55)
          : CuramindColors.mistBlue.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                linked ? Icons.verified_outlined : Icons.link_off_outlined,
                color: linked ? CuramindColors.sageDeep : CuramindColors.ocean,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  linked
                      ? 'Linked with $clinicianName · monitoring on'
                      : 'Not linked to a clinician yet',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: CuramindColors.ink,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: CuramindColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CuramindColors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CuramindColors.mistBlue),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: CuramindColors.slate, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gentle tip',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: CuramindColors.ocean,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    height: 1.4,
                    color: CuramindColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.title,
    required this.time,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: CuramindColors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CuramindColors.mistBlue),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: CuramindColors.sageDeep),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: CuramindColors.ink,
                    ),
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
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
