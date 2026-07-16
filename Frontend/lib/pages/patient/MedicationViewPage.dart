import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/curamind_theme.dart';

enum MedDoseStatus { due, taken, missed }

class MedicationViewPage extends StatefulWidget {
  const MedicationViewPage({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  State<MedicationViewPage> createState() => _MedicationViewPageState();
}

class _MedicationViewPageState extends State<MedicationViewPage> {
  bool _remindersOn = true;

  final List<_MedItem> _meds = [
    _MedItem(
      id: '1',
      name: 'Sertraline',
      dosageAndFreq: '50 mg · once daily · morning',
      scheduleLabel: '08:00',
      status: MedDoseStatus.due,
      isActive: true,
    ),
    _MedItem(
      id: '2',
      name: 'Lamotrigine',
      dosageAndFreq: '100 mg · twice daily · morning & evening',
      scheduleLabel: '08:00',
      status: MedDoseStatus.taken,
      isActive: true,
      loggedAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    _MedItem(
      id: '3',
      name: 'Lamotrigine',
      dosageAndFreq: '100 mg · twice daily · morning & evening',
      scheduleLabel: '20:00',
      status: MedDoseStatus.due,
      isActive: true,
    ),
    _MedItem(
      id: '4',
      name: 'Quetiapine',
      dosageAndFreq: '25 mg · as needed for sleep',
      scheduleLabel: '22:00',
      status: MedDoseStatus.due,
      isActive: true,
    ),
  ];

  int get _dueCount =>
      _meds.where((m) => m.status == MedDoseStatus.due).length;
  int get _takenCount =>
      _meds.where((m) => m.status == MedDoseStatus.taken).length;
  int get _missedCount =>
      _meds.where((m) => m.status == MedDoseStatus.missed).length;
  int get _activeCount => _meds.where((m) => m.isActive).length;

  double get _adherencePct {
    final done = _takenCount + _missedCount;
    if (done == 0) return 0;
    return (_takenCount / done) * 100;
  }

  void _mark(String id, MedDoseStatus status) {
    setState(() {
      final i = _meds.indexWhere((m) => m.id == id);
      if (i < 0) return;
      _meds[i] = _meds[i].copyWith(
        status: status,
        loggedAt: DateTime.now(),
      );
    });

    final label = status == MedDoseStatus.taken ? 'Taken' : 'Missed';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: CuramindColors.sageDeep,
        content: Text(
          'Logged as $label (local demo).',
          style: GoogleFonts.outfit(color: CuramindColors.white),
        ),
      ),
    );
  }

  void _undo(String id) {
    setState(() {
      final i = _meds.indexWhere((m) => m.id == id);
      if (i < 0) return;
      _meds[i] = _meds[i].copyWith(
        status: MedDoseStatus.due,
        clearLoggedAt: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.embedded) ...[
                Text(
                  'Medications',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fraunces(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: CuramindColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                'Today’s schedule, reminders, and adherence confirmation.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  height: 1.4,
                  color: CuramindColors.inkMuted,
                ),
              ),
              const SizedBox(height: 18),
              _SummaryCard(
                due: _dueCount,
                taken: _takenCount,
                missed: _missedCount,
                adherencePct: _adherencePct,
                activeCount: _activeCount,
              ),
              const SizedBox(height: 12),
              _ReminderCard(
                enabled: _remindersOn,
                onChanged: (v) => setState(() => _remindersOn = v),
              ),
              const SizedBox(height: 18),
              Text(
                'Today’s doses',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CuramindColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              ..._meds.map(
                (med) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MedCard(
                    med: med,
                    onTaken: () => _mark(med.id, MedDoseStatus.taken),
                    onMissed: () => _mark(med.id, MedDoseStatus.missed),
                    onUndo: () => _undo(med.id),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Prescriptions come from your linked clinician. Logging is local demo for now.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  height: 1.4,
                  color: CuramindColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.embedded) {
      return ColoredBox(color: CuramindColors.mist, child: content);
    }

    return Scaffold(
      backgroundColor: CuramindColors.mist,
      body: SafeArea(child: content),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.due,
    required this.taken,
    required this.missed,
    required this.adherencePct,
    required this.activeCount,
  });

  final int due;
  final int taken;
  final int missed;
  final double adherencePct;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CuramindColors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CuramindColors.mistBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adherence today',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: CuramindColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatPill(label: 'Due', value: '$due', color: CuramindColors.slate),
              const SizedBox(width: 8),
              _StatPill(
                label: 'Taken',
                value: '$taken',
                color: CuramindColors.sageDeep,
              ),
              const SizedBox(width: 8),
              _StatPill(
                label: 'Missed',
                value: '$missed',
                color: CuramindColors.danger,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (taken + missed) == 0
                  ? 0
                  : taken / (taken + missed).clamp(1, 999),
              minHeight: 8,
              backgroundColor: CuramindColors.mistBlue,
              color: CuramindColors.sage,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            taken + missed == 0
                ? '$activeCount active meds · no doses logged yet'
                : '${adherencePct.round()}% of logged doses taken',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: CuramindColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: CuramindColors.mistBlue.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
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
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.enabled,
    required this.onChanged,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: CuramindColors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CuramindColors.mistBlue),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(
          'In-app reminders',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CuramindColors.ink,
          ),
        ),
        subtitle: Text(
          enabled
              ? 'You’ll see gentle prompts near dose times'
              : 'Reminders are paused',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: CuramindColors.inkMuted,
          ),
        ),
        value: enabled,
        activeThumbColor: CuramindColors.sageDeep,
        onChanged: onChanged,
      ),
    );
  }
}

class _MedCard extends StatelessWidget {
  const _MedCard({
    required this.med,
    required this.onTaken,
    required this.onMissed,
    required this.onUndo,
  });

  final _MedItem med;
  final VoidCallback onTaken;
  final VoidCallback onMissed;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = switch (med.status) {
      MedDoseStatus.due => ('Due', CuramindColors.slate),
      MedDoseStatus.taken => ('Taken', CuramindColors.sageDeep),
      MedDoseStatus.missed => ('Missed', CuramindColors.danger),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CuramindColors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CuramindColors.mistBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CuramindColors.sageSoft,
                ),
                child: const Icon(
                  Icons.medication_outlined,
                  color: CuramindColors.sageDeep,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CuramindColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      med.dosageAndFreq,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: CuramindColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CuramindColors.mistBlue,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  med.scheduleLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: CuramindColors.ocean,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.circle, size: 8, color: statusColor),
              const SizedBox(width: 6),
              Text(
                statusLabel,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
              if (med.loggedAt != null) ...[
                const SizedBox(width: 8),
                Text(
                  '· ${_fmtTime(med.loggedAt!)}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: CuramindColors.inkMuted,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (med.status == MedDoseStatus.due)
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onTaken,
                    child: const Text('Mark taken'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onMissed,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CuramindColors.ocean,
                      side: const BorderSide(color: CuramindColors.slate),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Missed'),
                  ),
                ),
              ],
            )
          else
            TextButton(
              onPressed: onUndo,
              child: const Text('Undo log'),
            ),
        ],
      ),
    );
  }

  String _fmtTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _MedItem {
  const _MedItem({
    required this.id,
    required this.name,
    required this.dosageAndFreq,
    required this.scheduleLabel,
    required this.status,
    required this.isActive,
    this.loggedAt,
  });

  final String id;
  final String name;
  final String dosageAndFreq;
  final String scheduleLabel;
  final MedDoseStatus status;
  final bool isActive;
  final DateTime? loggedAt;

  _MedItem copyWith({
    MedDoseStatus? status,
    DateTime? loggedAt,
    bool clearLoggedAt = false,
  }) {
    return _MedItem(
      id: id,
      name: name,
      dosageAndFreq: dosageAndFreq,
      scheduleLabel: scheduleLabel,
      status: status ?? this.status,
      isActive: isActive,
      loggedAt: clearLoggedAt ? null : (loggedAt ?? this.loggedAt),
    );
  }
}
