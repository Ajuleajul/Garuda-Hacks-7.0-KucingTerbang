import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/curamind_theme.dart';
import '../../services/diary_service.dart';
import '../../services/link_service.dart';
import 'patient_emotion_summary.dart';

class PatientDetailsPage extends StatefulWidget {
  const PatientDetailsPage({
    super.key,
    required this.groupName,
    required this.summary,
  });

  final String groupName;
  final PatientEmotionSummary summary;

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  int _rangeDays = 14;
  late bool _monitoringOn;
  late List<DiaryEntryModel> _entries;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _monitoringOn = widget.summary.member.monitoringOn;
    _entries = List<DiaryEntryModel>.from(widget.summary.entries);
  }

  PatientEmotionSummary get s => PatientEmotionSummary(
        member: widget.summary.member.copyWith(monitoringOn: _monitoringOn),
        entries: _monitoringOn ? _entries : const [],
      );

  Future<void> _setMonitoring(bool on) async {
    final previous = _monitoringOn;
    setState(() {
      _toggling = true;
      _monitoringOn = on;
    });
    try {
      await LinkService.instance.setMonitoring(
        on,
        patientId: widget.summary.member.patientId,
      );
      if (!mounted) return;
      if (on) {
        try {
          final entries =
              await DiaryService.instance.loadClinicianPatientEntries(
            widget.summary.member.patientId,
            limit: 90,
          );
          if (!mounted) return;
          setState(() {
            _entries = entries;
            _toggling = false;
          });
        } catch (_) {
          if (!mounted) return;
          setState(() => _toggling = false);
        }
      } else {
        setState(() => _toggling = false);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            on ? 'Monitoring turned on.' : 'Monitoring turned off.',
          ),
          backgroundColor: CuramindColors.sageDeep,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _monitoringOn = previous;
        _toggling = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: CuramindColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<DiaryEntryModel> get _dbtInRange {
    final cutoff = DateTime.now().subtract(Duration(days: _rangeDays));
    return s.dbtEntries.where((e) => e.createdAt.isAfter(cutoff)).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  List<_DaySeries> get _daySeries {
    final byDay = <String, _DayBucket>{};
    for (final e in _dbtInRange) {
      final d = e.createdAt.toLocal();
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final bucket = byDay.putIfAbsent(key, () => _DayBucket(date: d));
      if (e.mood > 0) bucket.moods.add(e.mood.toDouble());
      if (e.affectIntensity > 0) {
        bucket.affects.add(e.affectIntensity.toDouble());
      }
      bucket.urges.add(math.max(e.urgeNssi, e.urgeSubstance).toDouble());
      bucket.emotions.addAll(e.emotions);
      bucket.triggers.addAll(e.triggers);
      bucket.skills.addAll(e.skills);
    }
    final keys = byDay.keys.toList()..sort();
    return keys.map((k) {
      final b = byDay[k]!;
      return _DaySeries(
        label: '${b.date.month}/${b.date.day}',
        mood: b.moods.isEmpty
            ? null
            : b.moods.reduce((a, c) => a + c) / b.moods.length,
        affect: b.affects.isEmpty
            ? null
            : b.affects.reduce((a, c) => a + c) / b.affects.length,
        urge: b.urges.isEmpty ? null : b.urges.reduce(math.max),
      );
    }).toList();
  }

  Map<String, int> _countTags(Iterable<String> tags) {
    final counts = <String, int>{};
    for (final t in tags) {
      final key = t.trim();
      if (key.isEmpty) continue;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(8));
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = d.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day} · $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final member = s.member;
    final series = _daySeries;
    final moods = _dbtInRange.where((e) => e.mood > 0).map((e) => e.mood);
    final avgMood = moods.isEmpty
        ? null
        : moods.reduce((a, b) => a + b) / moods.length;
    final peakUrge = _dbtInRange.isEmpty
        ? null
        : _dbtInRange
            .map((e) => math.max(e.urgeNssi, e.urgeSubstance))
            .reduce(math.max);
    final emotions = _countTags(_dbtInRange.expand((e) => e.emotions));
    final triggers = _countTags(_dbtInRange.expand((e) => e.triggers));
    final skills = _countTags(_dbtInRange.expand((e) => e.skills));
    final recentLogs = s.entries.take(12).toList();

    return Scaffold(
      backgroundColor: CuramindColors.mist,
      appBar: AppBar(
        backgroundColor: CuramindColors.mist,
        elevation: 0,
        iconTheme: const IconThemeData(color: CuramindColors.ink),
        title: Text(
          member.patientName,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: CuramindColors.ink,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CuramindColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CuramindColors.mistBlue),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'In group · ${widget.groupName}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CuramindColors.ocean,
                  ),
                ),
                if (member.email != null && member.email!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    member.email!,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: CuramindColors.inkMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(
                      label: member.monitoringOn
                          ? 'Monitoring on'
                          : 'Monitoring off',
                      color: member.monitoringOn
                          ? CuramindColors.sageDeep
                          : CuramindColors.danger,
                    ),
                    _Chip(
                      label: '${member.diaryEntries} diary total',
                      color: CuramindColors.slate,
                    ),
                    _Chip(
                      label: '${member.activeMedsCount} active meds',
                      color: CuramindColors.ocean,
                    ),
                    _Chip(
                      label: 'Joined ${_fmtDate(member.linkedAt)}',
                      color: CuramindColors.inkMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Remote monitoring',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      color: CuramindColors.ink,
                    ),
                  ),
                  subtitle: Text(
                    member.monitoringOn
                        ? 'Diary sharing is on'
                        : 'Diary sharing is paused',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: CuramindColors.inkMuted,
                    ),
                  ),
                  value: member.monitoringOn,
                  activeThumbColor: CuramindColors.sageDeep,
                  onChanged: _toggling ? null : _setMonitoring,
                ),
              ],
            ),
          ),
          if (!member.monitoringOn) ...[
            const SizedBox(height: 12),
            Text(
              'Monitoring is off. Emotion charts and diary logs are hidden until sharing is turned back on.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: CuramindColors.danger,
              ),
            ),
          ],
          if (member.monitoringOn) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CuramindColors.mistBlue.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: CuramindColors.mistBlue),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.hasTodayDiary
                        ? 'Review today’s diary'
                        : 'Today’s diary — waiting for patient entry',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: CuramindColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Mood',
                          value: s.todayMood == null
                              ? '—'
                              : s.todayMood!.toStringAsFixed(0),
                          hint: '/ 10',
                          color: CuramindColors.ocean,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          title: 'Affect',
                          value: s.todayAffect == null
                              ? '—'
                              : s.todayAffect!.toStringAsFixed(0),
                          hint: '/ 10',
                          color: CuramindColors.slate,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          title: 'Urge',
                          value: s.todayPeakUrge?.toString() ?? '—',
                          hint: '/ 10',
                          color: (s.todayPeakUrge ?? 0) >= 7
                              ? CuramindColors.danger
                              : CuramindColors.sageDeep,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: [7, 14, 30].map((d) {
              final selected = _rangeDays == d;
              return ChoiceChip(
                label: Text('${d}d'),
                selected: selected,
                onSelected: (_) => setState(() => _rangeDays = d),
                selectedColor: CuramindColors.sageSoft,
                labelStyle: GoogleFonts.outfit(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Avg mood',
                  value: avgMood == null ? '—' : avgMood.toStringAsFixed(1),
                  hint: '/ 10',
                  color: CuramindColors.ocean,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  title: 'Peak urge',
                  value: peakUrge?.toString() ?? '—',
                  hint: '/ 10',
                  color: (peakUrge ?? 0) >= 7
                      ? CuramindColors.danger
                      : CuramindColors.slate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  title: 'DBT cards',
                  value: '${_dbtInRange.length}',
                  hint: 'in range',
                  color: CuramindColors.sageDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Mood · affect · urge',
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: CuramindColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Daily averages from diary cards (0–10 scale).',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: CuramindColors.inkMuted,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 240,
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            decoration: BoxDecoration(
              color: CuramindColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CuramindColors.mistBlue),
            ),
            child: series.length < 2
                ? Center(
                    child: Text(
                      'Not enough diary points in this range yet.',
                      style: GoogleFonts.outfit(
                        color: CuramindColors.inkMuted,
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 10,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (v) => FlLine(
                          color: CuramindColors.mistBlue,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: 2,
                            getTitlesWidget: (v, _) => Text(
                              v.toInt().toString(),
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: CuramindColors.inkMuted,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: math.max(
                              1,
                              (series.length / 4).floorToDouble(),
                            ),
                            getTitlesWidget: (v, _) {
                              final i = v.round();
                              if (i < 0 || i >= series.length) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                series[i].label,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: CuramindColors.inkMuted,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        _line(
                          series,
                          (p) => p.mood,
                          CuramindColors.ocean,
                        ),
                        _line(
                          series,
                          (p) => p.affect,
                          CuramindColors.sageDeep,
                        ),
                        _line(
                          series,
                          (p) => p.urge,
                          CuramindColors.danger,
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (spots) => spots.map((s) {
                            final labels = ['Mood', 'Affect', 'Urge'];
                            return LineTooltipItem(
                              '${labels[s.barIndex]} ${s.y.toStringAsFixed(1)}',
                              GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: CuramindColors.white,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              _Legend(color: CuramindColors.ocean, label: 'Mood'),
              SizedBox(width: 14),
              _Legend(color: CuramindColors.sageDeep, label: 'Affect'),
              SizedBox(width: 14),
              _Legend(color: CuramindColors.danger, label: 'Urge'),
            ],
          ),
          const SizedBox(height: 20),
          _TagSection(title: 'Frequent emotions', counts: emotions),
          const SizedBox(height: 12),
          _TagSection(title: 'Frequent triggers', counts: triggers),
          const SizedBox(height: 12),
          _TagSection(title: 'Skills used', counts: skills),
          const SizedBox(height: 20),
          Text(
            'Recent diary log',
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: CuramindColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          if (recentLogs.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CuramindColors.mistBlue.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'No diary entries available for this patient.',
                style: GoogleFonts.outfit(color: CuramindColors.inkMuted),
              ),
            )
          else
            ...recentLogs.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _DiaryLogTile(entry: e, formatDate: _fmtDate),
              ),
            ),
          if (member.medications.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Active prescriptions',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: CuramindColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            ...member.medications.map(
              (med) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CuramindColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CuramindColors.mistBlue),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.name,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          color: CuramindColors.ink,
                        ),
                      ),
                      Text(
                        med.dosageAndFreq,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: CuramindColors.slate,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  LineChartBarData _line(
    List<_DaySeries> series,
    double? Function(_DaySeries) pick,
    Color color,
  ) {
    final spots = <FlSpot>[];
    for (var i = 0; i < series.length; i++) {
      final v = pick(series[i]);
      if (v != null) spots.add(FlSpot(i.toDouble(), v));
    }
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2.5,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }
}

class _DayBucket {
  _DayBucket({required this.date});
  final DateTime date;
  final List<double> moods = [];
  final List<double> affects = [];
  final List<double> urges = [];
  final List<String> emotions = [];
  final List<String> triggers = [];
  final List<String> skills = [];
}

class _DaySeries {
  const _DaySeries({
    required this.label,
    required this.mood,
    required this.affect,
    required this.urge,
  });
  final String label;
  final double? mood;
  final double? affect;
  final double? urge;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.hint,
    required this.color,
  });

  final String title;
  final String value;
  final String hint;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CuramindColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CuramindColors.mistBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: CuramindColors.inkMuted,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  hint,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: CuramindColors.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: CuramindColors.inkMuted,
          ),
        ),
      ],
    );
  }
}

class _TagSection extends StatelessWidget {
  const _TagSection({required this.title, required this.counts});
  final String title;
  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CuramindColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CuramindColors.mistBlue),
      ),
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
          const SizedBox(height: 8),
          if (counts.isEmpty)
            Text(
              'No tagged data in this range.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: CuramindColors.inkMuted,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: counts.entries
                  .map(
                    (e) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: CuramindColors.mistBlue.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${e.key} · ${e.value}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: CuramindColors.ocean,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _DiaryLogTile extends StatelessWidget {
  const _DiaryLogTile({
    required this.entry,
    required this.formatDate,
  });

  final DiaryEntryModel entry;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    final isDbt = entry.kind == DiaryEntryKind.dbtCard;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CuramindColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CuramindColors.mistBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDbt
                      ? CuramindColors.sageSoft.withValues(alpha: 0.6)
                      : CuramindColors.mistBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isDbt ? 'DBT card' : 'Coping',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDbt
                        ? CuramindColors.sageDeep
                        : CuramindColors.ocean,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                formatDate(entry.createdAt),
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: CuramindColors.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isDbt) ...[
            Text(
              'Mood ${entry.mood} · Affect ${entry.affectIntensity} · '
              'Urge NSSI ${entry.urgeNssi} · Substance ${entry.urgeSubstance}',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CuramindColors.ink,
              ),
            ),
            if (entry.emotions.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Emotions: ${entry.emotions.join(', ')}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: CuramindColors.slate,
                ),
              ),
            ],
            if (entry.triggers.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Triggers: ${entry.triggers.join(', ')}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: CuramindColors.slate,
                ),
              ),
            ],
            if (entry.skills.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Skills: ${entry.skills.join(', ')}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: CuramindColors.slate,
                ),
              ),
            ],
            if (entry.notes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                entry.notes,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: CuramindColors.inkMuted,
                  height: 1.35,
                ),
              ),
            ],
          ] else ...[
            if (entry.situation.isNotEmpty)
              Text(
                'Situation: ${entry.situation}',
                style: GoogleFonts.outfit(fontSize: 12, color: CuramindColors.slate),
              ),
            if (entry.thoughts.isNotEmpty)
              Text(
                'Thoughts: ${entry.thoughts}',
                style: GoogleFonts.outfit(fontSize: 12, color: CuramindColors.slate),
              ),
            if (entry.behavior.isNotEmpty)
              Text(
                'Behavior: ${entry.behavior}',
                style: GoogleFonts.outfit(fontSize: 12, color: CuramindColors.slate),
              ),
            if (entry.outcome.isNotEmpty)
              Text(
                'Outcome: ${entry.outcome}',
                style: GoogleFonts.outfit(fontSize: 12, color: CuramindColors.slate),
              ),
          ],
        ],
      ),
    );
  }
}
