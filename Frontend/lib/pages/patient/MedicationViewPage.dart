import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/medication_service.dart';
import '../../services/reminder_service.dart';
import '../../theme/curamind_theme.dart';

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
  bool _loading = true;
  bool _busy = false;
  String? _error;
  List<MedicationModel> _meds = const [];
  MedDayStats _today = const MedDayStats(
    active: 0,
    due: 0,
    taken: 0,
    missed: 0,
    adherencePct: 0,
  );
  MedPeriodStats _period = const MedPeriodStats(
    days: 7,
    activeMeds: 0,
    taken: 0,
    missed: 0,
    logged: 0,
    adherencePct: 0,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bundle = await MedicationService.instance.loadMyMeds();
      if (!mounted) return;
      setState(() {
        _meds = bundle.medications;
        _today = bundle.today;
        _period = bundle.period;
        _loading = false;
      });
      try {
        final settings = await ReminderService.instance.loadSettings();
        if (settings.masterEnabled) {
          await ReminderService.instance.reschedule(settings);
        }
      } catch (_) {}
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _setTaken(MedicationModel med, bool taken) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (taken) {
        await MedicationService.instance.markTaken(med.id);
      } else {
        await MedicationService.instance.clearTodayLog(med.id);
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: CuramindColors.danger,
          content: Text(
            e.toString(),
            style: GoogleFonts.outfit(color: CuramindColors.white),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _markMissed(MedicationModel med) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await MedicationService.instance.markMissed(med.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: CuramindColors.danger,
          content: Text(
            e.toString(),
            style: GoogleFonts.outfit(color: CuramindColors.white),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = RefreshIndicator(
      onRefresh: _load,
      color: CuramindColors.sageDeep,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                  'Prescriptions from your linked clinician. Check when taken; uncheck to undo.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    height: 1.4,
                    color: CuramindColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 18),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  _ErrorBox(message: _error!, onRetry: _load)
                else ...[
                  _SummaryCard(today: _today, period: _period),
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
                  if (_meds.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: CuramindColors.white.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: CuramindColors.mistBlue),
                      ),
                      child: Text(
                        'No active prescriptions yet. Ask your clinician to prescribe after you join their care group.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          height: 1.45,
                          color: CuramindColors.inkMuted,
                        ),
                      ),
                    )
                  else
                    ..._meds.map(
                      (med) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _MedCard(
                          med: med,
                          enabled: !_busy,
                          onTakenChanged: (v) => _setTaken(med, v),
                          onMissed: () => _markMissed(med),
                        ),
                      ),
                    ),
                ],
              ],
            ),
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

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: CuramindColors.inkMuted,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.today,
    required this.period,
  });

  final MedDayStats today;
  final MedPeriodStats period;

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
              _StatPill(
                label: 'Due',
                value: '${today.due}',
                color: CuramindColors.slate,
              ),
              const SizedBox(width: 8),
              _StatPill(
                label: 'Taken',
                value: '${today.taken}',
                color: CuramindColors.sageDeep,
              ),
              const SizedBox(width: 8),
              _StatPill(
                label: 'Missed',
                value: '${today.missed}',
                color: CuramindColors.danger,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (today.taken + today.missed) == 0
                  ? 0
                  : today.taken / (today.taken + today.missed).clamp(1, 999),
              minHeight: 8,
              backgroundColor: CuramindColors.mistBlue,
              color: CuramindColors.sage,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            today.taken + today.missed == 0
                ? '${today.active} active meds · no doses logged yet'
                : '${today.adherencePct}% of today’s logged doses taken',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: CuramindColors.inkMuted,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: CuramindColors.mistBlue.withValues(alpha: 0.8)),
          const SizedBox(height: 12),
          Text(
            'Last ${period.days} days',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: CuramindColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatPill(
                label: 'Taken',
                value: '${period.taken}',
                color: CuramindColors.sageDeep,
              ),
              const SizedBox(width: 8),
              _StatPill(
                label: 'Missed',
                value: '${period.missed}',
                color: CuramindColors.danger,
              ),
              const SizedBox(width: 8),
              _StatPill(
                label: 'Rate',
                value: '${period.adherencePct}%',
                color: CuramindColors.ocean,
              ),
            ],
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

class _MedCard extends StatelessWidget {
  const _MedCard({
    required this.med,
    required this.enabled,
    required this.onTakenChanged,
    required this.onMissed,
  });

  final MedicationModel med;
  final bool enabled;
  final ValueChanged<bool> onTakenChanged;
  final VoidCallback onMissed;

  @override
  Widget build(BuildContext context) {
    final taken = med.todayStatus == MedDoseStatus.taken;
    final missed = med.todayStatus == MedDoseStatus.missed;
    final (statusLabel, statusColor) = switch (med.todayStatus) {
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
              Checkbox(
                value: taken,
                onChanged: enabled
                    ? (v) => onTakenChanged(v == true)
                    : null,
                activeColor: CuramindColors.sageDeep,
              ),
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
                        decoration:
                            taken ? TextDecoration.lineThrough : null,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CuramindColors.mistBlue,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (med.todayLoggedAt != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Text(
                'Logged ${_fmtTime(med.todayLoggedAt!.toLocal())}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: CuramindColors.inkMuted,
                ),
              ),
            ),
          ],
          if (!taken) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: enabled && !missed ? onMissed : null,
                child: Text(missed ? 'Marked missed' : 'Mark missed'),
              ),
            ),
          ],
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
