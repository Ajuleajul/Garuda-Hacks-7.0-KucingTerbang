import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/diary_service.dart';
import '../../services/link_service.dart';
import '../../services/medication_service.dart';
import '../../theme/curamind_theme.dart';

class ClinicianHomePage extends StatefulWidget {
  const ClinicianHomePage({
    super.key,
    required this.displayName,
    required this.onNavigate,
    this.active = true,
  });

  final String displayName;
  final ValueChanged<int> onNavigate;
  final bool active;

  static const codesIndex = 1;
  static const monitorIndex = 2;
  static const dualChartIndex = 3;
  static const medsIndex = 4;
  static const exportIndex = 5;
  static const profileIndex = 6;

  @override
  State<ClinicianHomePage> createState() => _ClinicianHomePageState();
}

class _HomeAlert {
  const _HomeAlert({
    required this.name,
    required this.detail,
    required this.priority,
  });

  final String name;
  final String detail;
  final int priority;
}

class _ClinicianHomePageState extends State<ClinicianHomePage> {
  bool _loading = true;
  String? _error;
  int _patientCount = 0;
  int _groupCount = 0;
  int _alertCount = 0;
  int? _adherencePct;
  int _activeRx = 0;
  int _missedToday = 0;
  List<_HomeAlert> _alerts = const [];

  String get _greetingName {
    final raw = widget.displayName.trim();
    if (raw.isEmpty ||
        raw.toLowerCase() == 'clinician' ||
        raw.toLowerCase() == 'unknown' ||
        raw.toLowerCase() == 'doctor') {
      return 'Doctor';
    }
    final parts = raw.split(RegExp(r'\s+'));
    final first = parts.first;
    final lower = first.toLowerCase();
    if (lower == 'dr' || lower == 'dr.' || lower.startsWith('dr.')) {
      if (parts.length >= 2) return 'Dr. ${parts[1]}';
      return 'Doctor';
    }
    return 'Dr. $first';
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  void initState() {
    super.initState();
    if (widget.active) _load();
  }

  @override
  void didUpdateWidget(covariant ClinicianHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        LinkService.instance.listMyGroups(),
        MedicationService.instance.loadLinkedPatients(),
        MedicationService.instance.loadClinicianMeds(),
      ]);
      final groups = results[0] as List<JoinGroup>;
      final patients = results[1] as List<LinkedPatient>;
      final meds = results[2] as List<MedicationModel>;

      final activeMeds = meds.where((m) => m.isActive).toList();
      final taken = activeMeds
          .where((m) => m.todayStatus == MedDoseStatus.taken)
          .length;
      final missed = activeMeds
          .where((m) => m.todayStatus == MedDoseStatus.missed)
          .length;
      final logged = taken + missed;
      final adherence = logged == 0
          ? null
          : ((taken / logged) * 100).round().clamp(0, 100);

      final alerts = <_HomeAlert>[];
      final missedByPatient = <String, List<MedicationModel>>{};
      for (final m in activeMeds) {
        if (m.todayStatus != MedDoseStatus.missed) continue;
        missedByPatient.putIfAbsent(m.patientId, () => []).add(m);
      }
      for (final entry in missedByPatient.entries) {
        final first = entry.value.first;
        alerts.add(
          _HomeAlert(
            name: first.patientName,
            detail: entry.value.length == 1
                ? 'Missed ${first.name} today'
                : 'Missed ${entry.value.length} doses today',
            priority: 2,
          ),
        );
      }

      final dueByPatient = <String, List<MedicationModel>>{};
      for (final m in activeMeds) {
        if (m.todayStatus != MedDoseStatus.due) continue;
        dueByPatient.putIfAbsent(m.patientId, () => []).add(m);
      }
      for (final entry in dueByPatient.entries) {
        if (missedByPatient.containsKey(entry.key)) continue;
        final first = entry.value.first;
        alerts.add(
          _HomeAlert(
            name: first.patientName,
            detail: entry.value.length == 1
                ? '${first.name} still due today'
                : '${entry.value.length} doses still due today',
            priority: 1,
          ),
        );
      }

      for (final p in patients) {
        if (!p.monitoringOn) {
          alerts.add(
            _HomeAlert(
              name: p.patientName,
              detail: 'Monitoring paused — diary sharing is off',
              priority: 2,
            ),
          );
        }
      }

      final sample =
          patients.where((p) => p.monitoringOn).take(6).toList();
      final diaryResults = await Future.wait(
        sample.map((p) async {
          try {
            final entries =
                await DiaryService.instance.loadClinicianPatientEntries(
              p.patientId,
              limit: 20,
            );
            return MapEntry(p, entries);
          } catch (_) {
            return MapEntry(p, const <DiaryEntryModel>[]);
          }
        }),
      );

      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      for (final pair in diaryResults) {
        final patient = pair.key;
        final recent = pair.value.where(
          (e) =>
              e.kind == DiaryEntryKind.dbtCard && e.createdAt.isAfter(cutoff),
        );
        if (recent.isEmpty) continue;
        var peak = 0;
        var moodSum = 0;
        var moodN = 0;
        for (final e in recent) {
          peak = math.max(peak, math.max(e.urgeNssi, e.urgeSubstance));
          if (e.mood > 0) {
            moodSum += e.mood;
            moodN++;
          }
        }
        if (peak >= 7) {
          alerts.add(
            _HomeAlert(
              name: patient.patientName,
              detail: 'High urge logged in diary (peak $peak/10)',
              priority: 3,
            ),
          );
        } else if (moodN > 0 && (moodSum / moodN) <= 3.5) {
          alerts.add(
            _HomeAlert(
              name: patient.patientName,
              detail:
                  'Low average mood last 7 days (${(moodSum / moodN).toStringAsFixed(1)}/10)',
              priority: 2,
            ),
          );
        }
      }

      alerts.sort((a, b) => b.priority.compareTo(a.priority));
      final unique = <String, _HomeAlert>{};
      for (final a in alerts) {
        unique.putIfAbsent('${a.name}|${a.detail}', () => a);
      }
      final topAlerts = unique.values.take(5).toList();

      if (!mounted) return;
      setState(() {
        _groupCount = groups.length;
        _patientCount = patients.length;
        _activeRx = activeMeds.length;
        _missedToday = missed;
        _adherencePct = adherence;
        _alerts = topAlerts;
        _alertCount = topAlerts.length;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: CuramindColors.mist,
      child: RefreshIndicator(
        onRefresh: _load,
        color: CuramindColors.sageDeep,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '$_greeting, $_greetingName',
                    style: GoogleFonts.fraunces(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: CuramindColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _loading
                        ? 'Syncing caseload…'
                        : _patientCount == 0
                            ? 'Create a care group, then invite your first patient.'
                            : '$_patientCount linked patient${_patientCount == 1 ? '' : 's'} across $_groupCount group${_groupCount == 1 ? '' : 's'}.',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      height: 1.4,
                      color: CuramindColors.inkMuted,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: CuramindColors.danger,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _Metric(
                        label: 'Patients',
                        value: _loading ? '—' : '$_patientCount',
                        onTap: () =>
                            widget.onNavigate(ClinicianHomePage.monitorIndex),
                      ),
                      const SizedBox(width: 8),
                      _Metric(
                        label: 'Alerts',
                        value: _loading ? '—' : '$_alertCount',
                        emphasize: _alertCount > 0,
                        onTap: () =>
                            widget.onNavigate(ClinicianHomePage.monitorIndex),
                      ),
                      const SizedBox(width: 8),
                      _Metric(
                        label: 'Adhere',
                        value: _loading
                            ? '—'
                            : _adherencePct == null
                                ? 'n/a'
                                : '$_adherencePct%',
                        onTap: () => widget
                            .onNavigate(ClinicianHomePage.dualChartIndex),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Most used',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: CuramindColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _PrimaryTile(
                    title: 'Patient monitor',
                    subtitle: _loading
                        ? 'Loading caseload…'
                        : _alertCount > 0
                            ? '$_alertCount need review · $_patientCount active'
                            : '$_patientCount active · no urgent alerts',
                    detail: 'Mood, urge, and diary signals by care group',
                    icon: Icons.monitor_heart_outlined,
                    onTap: () =>
                        widget.onNavigate(ClinicianHomePage.monitorIndex),
                  ),
                  const SizedBox(height: 10),
                  _PrimaryTile(
                    title: 'Care groups',
                    subtitle: _loading
                        ? 'Loading groups…'
                        : _groupCount == 0
                            ? 'Create your first invite group'
                            : '$_groupCount group${_groupCount == 1 ? '' : 's'} · manage members & codes',
                    detail: 'Invite links, members, and patient details',
                    icon: Icons.groups_2_outlined,
                    tone: _PrimaryTone.sage,
                    onTap: () =>
                        widget.onNavigate(ClinicianHomePage.codesIndex),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _SecondaryTile(
                          title: 'Dual chart',
                          subtitle: 'Mood × adherence',
                          detail: 'Compare trends by patient',
                          icon: Icons.stacked_line_chart,
                          onTap: () => widget
                              .onNavigate(ClinicianHomePage.dualChartIndex),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SecondaryTile(
                          title: 'Meds',
                          subtitle: _loading
                              ? 'Prescriptions'
                              : '$_activeRx active Rx',
                          detail: _missedToday > 0
                              ? '$_missedToday missed today'
                              : 'Schedules & dose logs',
                          icon: Icons.list_alt_outlined,
                          onTap: () =>
                              widget.onNavigate(ClinicianHomePage.medsIndex),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _SecondaryTile(
                    title: 'Export clinical PDF',
                    subtitle: 'Shareable report for visits',
                    detail: 'Select group, patient, and sections',
                    icon: Icons.picture_as_pdf_outlined,
                    wide: true,
                    onTap: () =>
                        widget.onNavigate(ClinicianHomePage.exportIndex),
                  ),
                  const SizedBox(height: 18),
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
                      if (!_loading && _alerts.isNotEmpty)
                        TextButton(
                          onPressed: () => widget
                              .onNavigate(ClinicianHomePage.monitorIndex),
                          child: Text(
                            'Open monitor',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              color: CuramindColors.ocean,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_alerts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CuramindColors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: CuramindColors.mistBlue),
                      ),
                      child: Text(
                        _patientCount == 0
                            ? 'No alerts yet — link a patient to start monitoring.'
                            : 'No priority alerts right now. Caseload looks steady.',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: CuramindColors.inkMuted,
                        ),
                      ),
                    )
                  else
                    ..._alerts.map(
                      (a) => _AlertRow(
                        name: a.name,
                        detail: a.detail,
                        onTap: () => widget
                            .onNavigate(ClinicianHomePage.monitorIndex),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'More',
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
                        label: 'Profile',
                        icon: Icons.person_outline_rounded,
                        onTap: () =>
                            widget.onNavigate(ClinicianHomePage.profileIndex),
                      ),
                      _ToolChip(
                        label: 'Refresh',
                        icon: Icons.refresh_rounded,
                        onTap: _load,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _PrimaryTone { ocean, sage }

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.onTap,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool emphasize;

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
              border: Border.all(
                color: emphasize
                    ? CuramindColors.danger.withValues(alpha: 0.45)
                    : CuramindColors.mistBlue,
              ),
            ),
            child: Column(
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: emphasize
                        ? CuramindColors.danger
                        : CuramindColors.sageDeep,
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
    required this.detail,
    required this.icon,
    required this.onTap,
    this.tone = _PrimaryTone.ocean,
  });

  final String title;
  final String subtitle;
  final String detail;
  final IconData icon;
  final VoidCallback onTap;
  final _PrimaryTone tone;

  @override
  Widget build(BuildContext context) {
    final bg = tone == _PrimaryTone.ocean
        ? CuramindColors.ocean
        : CuramindColors.sageDeep;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: CuramindColors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: CuramindColors.white),
              ),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: CuramindColors.white.withValues(alpha: 0.92),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: CuramindColors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded,
                  color: CuramindColors.white),
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
    required this.detail,
    required this.icon,
    required this.onTap,
    this.wide = false,
  });

  final String title;
  final String subtitle;
  final String detail;
  final IconData icon;
  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CuramindColors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: wide ? double.infinity : null,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CuramindColors.mistBlue),
          ),
          child: wide
              ? Row(
                  children: [
                    Icon(icon, color: CuramindColors.ocean),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                              fontSize: 12,
                              color: CuramindColors.inkMuted,
                            ),
                          ),
                          Text(
                            detail,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: CuramindColors.slate,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: CuramindColors.ocean,
                      size: 18,
                    ),
                  ],
                )
              : Column(
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
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: CuramindColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: CuramindColors.slate,
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
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: CuramindColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
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
