import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../animated_cursor.dart';
import '../../services/diary_service.dart';
import '../../services/link_service.dart';
import '../../theme/curamind_theme.dart';
import 'PatientDetailsPage.dart';
import 'patient_emotion_summary.dart';

class PatientMonitoringDashboard extends StatefulWidget {
  const PatientMonitoringDashboard({
    super.key,
    required this.group,
  });

  final JoinGroup group;

  @override
  State<PatientMonitoringDashboard> createState() =>
      _PatientMonitoringDashboardState();
}

class _PatientMonitoringDashboardState
    extends State<PatientMonitoringDashboard> {
  bool _loading = true;
  String? _error;
  List<PatientEmotionSummary> _summaries = const [];

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
      final members =
          await LinkService.instance.listGroupMembers(widget.group.id);
      final futures = members.map((m) async {
        try {
          final entries =
              await DiaryService.instance.loadClinicianPatientEntries(
            m.patientId,
            limit: 60,
          );
          return PatientEmotionSummary(member: m, entries: entries);
        } catch (_) {
          return PatientEmotionSummary(member: m, entries: const []);
        }
      });
      final summaries = await Future.wait(futures);
      summaries.sort((a, b) {
        final alertCmp = (b.hasAlert ? 1 : 0).compareTo(a.hasAlert ? 1 : 0);
        if (alertCmp != 0) return alertCmp;
        return a.member.patientName
            .toLowerCase()
            .compareTo(b.member.patientName.toLowerCase());
      });
      if (!mounted) return;
      setState(() {
        _summaries = summaries;
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
    final alertCount = _summaries.where((s) => s.hasAlert).length;

    return Scaffold(
      backgroundColor: CuramindColors.mist,
      appBar: AppBar(
        backgroundColor: CuramindColors.mist,
        elevation: 0,
        iconTheme: const IconThemeData(color: CuramindColors.ink),
        title: Text(
          widget.group.name,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: CuramindColors.ink,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: CuramindColors.sageDeep,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text(
              'Group emotion overview',
              style: GoogleFonts.fraunces(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: CuramindColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Last 7 days of DBT diary cards — mood, affect, and urge signals.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: CuramindColors.inkMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            if (!_loading && _error == null)
              Row(
                children: [
                  Expanded(
                    child: _GroupStatChip(
                      label: 'Patients',
                      value: '${_summaries.length}',
                      color: CuramindColors.ocean,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _GroupStatChip(
                      label: 'Needs attention',
                      value: '$alertCount',
                      color: alertCount > 0
                          ? CuramindColors.danger
                          : CuramindColors.sageDeep,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _GroupStatChip(
                      label: 'Diary (7d)',
                      value:
                          '${_summaries.fold<int>(0, (n, s) => n + s.recentDbt.length)}',
                      color: CuramindColors.sageDeep,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: CircularProgressIndicator(
                    color: CuramindColors.sageDeep,
                  ),
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style:
                          GoogleFonts.outfit(color: CuramindColors.inkMuted),
                    ),
                    FilledButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              )
            else if (_summaries.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: CuramindColors.mistBlue.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'No patients in this group yet. Share an invite link from Groups.',
                  style: GoogleFonts.outfit(
                    color: CuramindColors.inkMuted,
                    height: 1.4,
                  ),
                ),
              )
            else
              ..._summaries.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PatientEmotionCard(
                    summary: s,
                    groupName: widget.group.name,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GroupStatChip extends StatelessWidget {
  const _GroupStatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: CuramindColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CuramindColors.mistBlue),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: CuramindColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientEmotionCard extends StatelessWidget {
  const _PatientEmotionCard({
    required this.summary,
    required this.groupName,
  });

  final PatientEmotionSummary summary;
  final String groupName;

  @override
  Widget build(BuildContext context) {
    final m = summary.member;
    final spark = summary.moodSpark;
    final alerts = <String>[
      if (!m.monitoringOn) 'Monitoring off',
      if (summary.highUrgeAlert) 'High urge',
      if (summary.lowMoodAlert) 'Low mood',
      if (summary.inactiveAlert) 'Quiet 3d+',
    ];

    return CursorHoverRegion(
      child: Material(
        color: CuramindColors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PatientDetailsPage(
                  groupName: groupName,
                  summary: summary,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: summary.hasAlert
                    ? CuramindColors.danger.withValues(alpha: 0.45)
                    : CuramindColors.mistBlue,
                width: summary.hasAlert ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: CuramindColors.sageSoft,
                      child: Text(
                        m.patientName.trim().isEmpty
                            ? '?'
                            : m.patientName.trim()[0].toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          color: CuramindColors.sageDeep,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.patientName,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: CuramindColors.ink,
                            ),
                          ),
                          if (m.email != null && m.email!.isNotEmpty)
                            Text(
                              m.email!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: CuramindColors.inkMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (summary.hasAlert)
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: CuramindColors.danger,
                        size: 22,
                      ),
                  ],
                ),
                if (alerts.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: alerts
                        .map(
                          (a) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  CuramindColors.danger.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              a,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: CuramindColors.danger,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCell(
                        label: 'Mood 7d',
                        value: summary.avgMood7d == null
                            ? '—'
                            : summary.avgMood7d!.toStringAsFixed(1),
                      ),
                    ),
                    Expanded(
                      child: _MetricCell(
                        label: 'Affect',
                        value: summary.avgAffect7d == null
                            ? '—'
                            : summary.avgAffect7d!.toStringAsFixed(1),
                      ),
                    ),
                    Expanded(
                      child: _MetricCell(
                        label: 'Peak urge',
                        value: summary.peakUrge7d?.toString() ?? '—',
                      ),
                    ),
                    Expanded(
                      child: _MetricCell(
                        label: 'Cards',
                        value: '${summary.recentDbt.length}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  child: spark.length < 2
                      ? Center(
                          child: Text(
                            summary.entries.isEmpty
                                ? 'No diary data yet'
                                : 'Need more points for a trend',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: CuramindColors.inkMuted,
                            ),
                          ),
                        )
                      : CustomPaint(
                          painter: _MiniSparklinePainter(
                            values: spark,
                            color: CuramindColors.ocean,
                          ),
                          child: const SizedBox.expand(),
                        ),
                ),
                if (summary.topEmotions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Top emotions: ${summary.topEmotions.keys.join(', ')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: CuramindColors.slate,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Open full report →',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CuramindColors.ocean,
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

class _MetricCell extends StatelessWidget {
  const _MetricCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: CuramindColors.ink,
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
    );
  }
}

class _MiniSparklinePainter extends CustomPainter {
  _MiniSparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = (maxV - minV).abs() < 0.01 ? 1.0 : (maxV - minV);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i / (values.length - 1) * size.width;
      final y = size.height - ((values[i] - minV) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MiniSparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}
