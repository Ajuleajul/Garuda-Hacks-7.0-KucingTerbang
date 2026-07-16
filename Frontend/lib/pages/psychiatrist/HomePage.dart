import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/curamind_theme.dart';

/// Clinician shell indices (with Home at 0):
/// 0 Home · 1 Monitor · 2 Dual Chart · 3 Prescribe · 4 Meds · 5 Export · 6 Profile
class ClinicianHomePage extends StatelessWidget {
  const ClinicianHomePage({
    super.key,
    required this.displayName,
    required this.onNavigate,
  });

  final String displayName;
  final ValueChanged<int> onNavigate;

  static const monitorIndex = 1;
  static const dualChartIndex = 2;
  static const prescribeIndex = 3;
  static const medsIndex = 4;
  static const exportIndex = 5;
  static const profileIndex = 6;

  static const _activePatients = 5;
  static const _alertCount = 2;
  static const _avgAdherence = 0.81;
  static const _pendingLinks = 1;

  String get _firstName {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? 'Doctor' : parts.first;
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
    final alerts = const [
      _ClinicAlert(
        patient: 'Luke Crain',
        detail: 'NSSI urge logged in diary',
        severity: _AlertSeverity.high,
        icon: Icons.priority_high_rounded,
      ),
      _ClinicAlert(
        patient: 'Theo Crain',
        detail: 'Missed medication · adherence 45%',
        severity: _AlertSeverity.medium,
        icon: Icons.medication_outlined,
      ),
    ];

    return ColoredBox(
      color: CuramindColors.mist,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ClinicGreeting(
                  greeting: _greeting,
                  name: _firstName,
                  dateLabel: _dateLabel,
                  alertCount: _alertCount,
                ),
                const SizedBox(height: 16),
                _CaseloadGlance(
                  activePatients: _activePatients,
                  alertCount: _alertCount,
                  avgAdherence: _avgAdherence,
                  pendingLinks: _pendingLinks,
                  onMonitor: () => onNavigate(monitorIndex),
                  onExport: () => onNavigate(exportIndex),
                ),
                const SizedBox(height: 16),
                _PrimaryCta(
                  title: 'Open patient monitor',
                  subtitle:
                      '$_activePatients active · $_alertCount need review today',
                  icon: Icons.monitor_heart_outlined,
                  onTap: () => onNavigate(monitorIndex),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _SecondaryCta(
                        title: 'Dual chart',
                        subtitle: 'Mood × adherence',
                        icon: Icons.stacked_line_chart,
                        onTap: () => onNavigate(dualChartIndex),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SecondaryCta(
                        title: 'Prescribe',
                        subtitle: 'Adjust dosages',
                        icon: Icons.medication_liquid_outlined,
                        onTap: () => onNavigate(prescribeIndex),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Priority alerts',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: CuramindColors.ink,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => onNavigate(monitorIndex),
                      child: const Text('View all'),
                    ),
                  ],
                ),
                ...alerts.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AlertCard(
                      alert: a,
                      onTap: () => onNavigate(monitorIndex),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Clinical tools',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CuramindColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                _ToolGrid(
                  items: [
                    _ToolItem(
                      label: 'Med logs',
                      hint: 'Session notes',
                      icon: Icons.list_alt_outlined,
                      onTap: () => onNavigate(medsIndex),
                    ),
                    _ToolItem(
                      label: 'Export',
                      hint: 'PDF / EMR',
                      icon: Icons.picture_as_pdf_outlined,
                      onTap: () => onNavigate(exportIndex),
                    ),
                    _ToolItem(
                      label: 'Dual chart',
                      hint: 'Correlations',
                      icon: Icons.stacked_line_chart,
                      onTap: () => onNavigate(dualChartIndex),
                    ),
                    _ToolItem(
                      label: 'Profile',
                      hint: 'Account',
                      icon: Icons.person_outline_rounded,
                      onTap: () => onNavigate(profileIndex),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _WorkflowCard(
                  steps: const [
                    ('Review alerts', 'Check NSSI / missed meds first'),
                    ('Open dual chart', 'Confirm mood–adherence pattern'),
                    ('Adjust Rx if needed', 'Update dose or frequency'),
                    ('Export note', 'Share longitudinal summary'),
                  ],
                  onStart: () => onNavigate(monitorIndex),
                ),
                const SizedBox(height: 12),
                _InviteBanner(
                  pendingLinks: _pendingLinks,
                  onTap: () => onNavigate(monitorIndex),
                ),
                const SizedBox(height: 16),
                Text(
                  'Caseload snapshot',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CuramindColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                const _PatientMiniRow(
                  name: 'Eleanor Vance',
                  meta: 'Adherence 92% · mood rising',
                  status: 'Stable',
                  statusColor: CuramindColors.sageDeep,
                ),
                const _PatientMiniRow(
                  name: 'Theo Crain',
                  meta: 'Adherence 45% · missed doses',
                  status: 'Meds',
                  statusColor: CuramindColors.slate,
                ),
                const _PatientMiniRow(
                  name: 'Luke Crain',
                  meta: 'Urge spike logged yesterday',
                  status: 'NSSI',
                  statusColor: CuramindColors.danger,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => onNavigate(monitorIndex),
                    child: const Text('Open full monitor'),
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

enum _AlertSeverity { high, medium }

class _ClinicAlert {
  const _ClinicAlert({
    required this.patient,
    required this.detail,
    required this.severity,
    required this.icon,
  });

  final String patient;
  final String detail;
  final _AlertSeverity severity;
  final IconData icon;
}

class _ClinicGreeting extends StatelessWidget {
  const _ClinicGreeting({
    required this.greeting,
    required this.name,
    required this.dateLabel,
    required this.alertCount,
  });

  final String greeting;
  final String name;
  final String dateLabel;
  final int alertCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CuramindColors.mistBlue.withValues(alpha: 0.95),
            CuramindColors.sageSoft.withValues(alpha: 0.7),
            CuramindColors.white.withValues(alpha: 0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CuramindColors.mistBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                dateLabel,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: CuramindColors.inkMuted,
                ),
              ),
              const Spacer(),
              if (alertCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: CuramindColors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: CuramindColors.slate),
                  ),
                  child: Text(
                    '$alertCount alerts',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: CuramindColors.ocean,
                    ),
                  ),
                ),
            ],
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
            'Review alerts first, then deepen with dual charts and Rx updates.',
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

class _CaseloadGlance extends StatelessWidget {
  const _CaseloadGlance({
    required this.activePatients,
    required this.alertCount,
    required this.avgAdherence,
    required this.pendingLinks,
    required this.onMonitor,
    required this.onExport,
  });

  final int activePatients;
  final int alertCount;
  final double avgAdherence;
  final int pendingLinks;
  final VoidCallback onMonitor;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricChip(
            label: 'Patients',
            value: '$activePatients',
            onTap: onMonitor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricChip(
            label: 'Alerts',
            value: '$alertCount',
            accent: CuramindColors.danger,
            onTap: onMonitor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricChip(
            label: 'Adhere',
            value: '${(avgAdherence * 100).round()}%',
            onTap: onMonitor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricChip(
            label: 'Pending',
            value: '$pendingLinks',
            onTap: onExport,
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.onTap,
    this.accent = CuramindColors.sageDeep,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CuramindColors.white.withValues(alpha: 0.85),
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
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: accent,
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
      color: CuramindColors.ocean,
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
                        color: CuramindColors.white.withValues(alpha: 0.85),
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
      color: CuramindColors.white.withValues(alpha: 0.85),
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
              Icon(icon, color: CuramindColors.ocean),
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

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.onTap});

  final _ClinicAlert alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = alert.severity == _AlertSeverity.high
        ? CuramindColors.danger
        : CuramindColors.slate;

    return Material(
      color: CuramindColors.white.withValues(alpha: 0.88),
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
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(alert.icon, color: tone, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.patient,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        color: CuramindColors.ink,
                      ),
                    ),
                    Text(
                      alert.detail,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: CuramindColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Review',
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

class _ToolItem {
  const _ToolItem({
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

class _ToolGrid extends StatelessWidget {
  const _ToolGrid({required this.items});

  final List<_ToolItem> items;

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
        childAspectRatio: 2.2,
      ),
      itemBuilder: (context, i) {
        final item = items[i];
        return Material(
          color: CuramindColors.white.withValues(alpha: 0.85),
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
                  Icon(item.icon, color: CuramindColors.ocean, size: 22),
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

class _WorkflowCard extends StatelessWidget {
  const _WorkflowCard({
    required this.steps,
    required this.onStart,
  });

  final List<(String, String)> steps;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CuramindColors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CuramindColors.mistBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Suggested session flow',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: CuramindColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(steps.length, (i) {
            final step = steps[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: CuramindColors.mistBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: CuramindColors.ocean,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.$1,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            color: CuramindColors.ink,
                          ),
                        ),
                        Text(
                          step.$2,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: CuramindColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          FilledButton(
            onPressed: onStart,
            child: const Text('Start with monitor'),
          ),
        ],
      ),
    );
  }
}

class _InviteBanner extends StatelessWidget {
  const _InviteBanner({
    required this.pendingLinks,
    required this.onTap,
  });

  final int pendingLinks;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CuramindColors.sageSoft.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.link_outlined, color: CuramindColors.sageDeep),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  pendingLinks > 0
                      ? '$pendingLinks patient invite pending confirmation'
                      : 'No pending link requests',
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

class _PatientMiniRow extends StatelessWidget {
  const _PatientMiniRow({
    required this.name,
    required this.meta,
    required this.status,
    required this.statusColor,
  });

  final String name;
  final String meta;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: CuramindColors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CuramindColors.mistBlue),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      color: CuramindColors.ink,
                    ),
                  ),
                  Text(
                    meta,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: CuramindColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
