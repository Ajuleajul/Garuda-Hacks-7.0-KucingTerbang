import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/curamind_theme.dart';

/// Clinician shell indices (with Home at 0):
/// 0 Home · 1 Codes · 2 Monitor · 3 Dual Chart · 4 Meds · 5 Export · 6 Profile
class ClinicianHomePage extends StatelessWidget {
  const ClinicianHomePage({
    super.key,
    required this.displayName,
    required this.onNavigate,
  });

  final String displayName;
  final ValueChanged<int> onNavigate;

  static const codesIndex = 1;
  static const monitorIndex = 2;
  static const dualChartIndex = 3;
  static const medsIndex = 4;
  static const exportIndex = 5;
  static const profileIndex = 6;

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

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: CuramindColors.mist,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '$_greeting, $_firstName',
                  style: GoogleFonts.fraunces(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: CuramindColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Review alerts first, then deepen with dual charts and Rx updates.',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    height: 1.4,
                    color: CuramindColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _Metric(
                      label: 'Patients',
                      value: '5',
                      onTap: () => onNavigate(monitorIndex),
                    ),
                    const SizedBox(width: 8),
                    _Metric(
                      label: 'Alerts',
                      value: '2',
                      onTap: () => onNavigate(monitorIndex),
                    ),
                    const SizedBox(width: 8),
                    _Metric(
                      label: 'Adhere',
                      value: '81%',
                      onTap: () => onNavigate(dualChartIndex),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _PrimaryTile(
                  title: 'Open patient monitor',
                  subtitle: '5 active · 2 need review today',
                  icon: Icons.monitor_heart_outlined,
                  onTap: () => onNavigate(monitorIndex),
                ),
                const SizedBox(height: 10),
                _PrimaryTile(
                  title: 'Join codes',
                  subtitle: 'Create groups so patients can link',
                  icon: Icons.qr_code_2_outlined,
                  onTap: () => onNavigate(codesIndex),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _SecondaryTile(
                        title: 'Dual chart',
                        subtitle: 'Mood × adherence',
                        icon: Icons.stacked_line_chart,
                        onTap: () => onNavigate(dualChartIndex),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SecondaryTile(
                        title: 'Meds',
                        subtitle: 'Schedules & logs',
                        icon: Icons.list_alt_outlined,
                        onTap: () => onNavigate(medsIndex),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Priority alerts',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CuramindColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                _AlertRow(
                  name: 'Luke Crain',
                  detail: 'NSSI urge logged in diary',
                  onTap: () => onNavigate(monitorIndex),
                ),
                _AlertRow(
                  name: 'Theo Crain',
                  detail: 'Missed medication · adherence 45%',
                  onTap: () => onNavigate(monitorIndex),
                ),
                const SizedBox(height: 12),
                Text(
                  'Clinical tools',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CuramindColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ToolChip(
                      label: 'Join codes',
                      icon: Icons.qr_code_2_outlined,
                      onTap: () => onNavigate(codesIndex),
                    ),
                    _ToolChip(
                      label: 'Med logs',
                      icon: Icons.list_alt_outlined,
                      onTap: () => onNavigate(medsIndex),
                    ),
                    _ToolChip(
                      label: 'Export',
                      icon: Icons.picture_as_pdf_outlined,
                      onTap: () => onNavigate(exportIndex),
                    ),
                    _ToolChip(
                      label: 'Profile',
                      icon: Icons.person_outline_rounded,
                      onTap: () => onNavigate(profileIndex),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: CuramindColors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CuramindColors.mistBlue),
            ),
            child: Column(
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: CuramindColors.sageDeep,
                  ),
                ),
                Text(
                  label,
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

class _PrimaryTile extends StatelessWidget {
  const _PrimaryTile({
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: CuramindColors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        color: CuramindColors.white,
                      ),
                    ),
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

class _SecondaryTile extends StatelessWidget {
  const _SecondaryTile({
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
              const SizedBox(height: 8),
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

class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.name,
    required this.detail,
    required this.onTap,
  });

  final String name;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: CuramindColors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
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
                          fontWeight: FontWeight.w700,
                          color: CuramindColors.ink,
                        ),
                      ),
                      Text(
                        detail,
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
      ),
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CuramindColors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CuramindColors.mistBlue),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: CuramindColors.ocean),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: CuramindColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
