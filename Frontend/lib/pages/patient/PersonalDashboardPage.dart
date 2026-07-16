import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/diary_service.dart';
import '../../services/medication_service.dart';
import '../../theme/curamind_theme.dart';

class PersonalDashboardPage extends StatefulWidget {
  const PersonalDashboardPage({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  State<PersonalDashboardPage> createState() => _PersonalDashboardPageState();
}

class _PersonalDashboardPageState extends State<PersonalDashboardPage> {
  int _rangeDays = 7;
  bool _loading = true;
  String? _error;
  List<_DayPoint> _allDays = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<_DayPoint> get _visible {
    if (_allDays.length <= _rangeDays) return _allDays;
    return _allDays.sublist(_allDays.length - _rangeDays);
  }

  double get _avgMood {
    final pts = _visible.where((p) => p.hasMood).toList();
    if (pts.isEmpty) return 0;
    return pts.map((p) => p.mood).reduce((a, b) => a + b) / pts.length;
  }

  double get _avgAdherence {
    final pts = _visible.where((p) => p.hasAdherence).toList();
    if (pts.isEmpty) return 0;
    return pts.map((p) => p.adherence).reduce((a, b) => a + b) / pts.length;
  }

  int get _diaryCount => _visible.where((p) => p.hasDiary).length;

  double get _peakUrge {
    final pts = _visible.where((p) => p.hasMood).toList();
    if (pts.isEmpty) return 0;
    return pts.map((p) => p.urge).reduce(math.max);
  }

  String get _insight {
    final moodPts = _visible.where((p) => p.hasMood).length;
    final adhPts = _visible.where((p) => p.hasAdherence).length;
    if (moodPts == 0 && adhPts == 0) {
      return 'No diary or medication logs in this window yet. Log a diary entry and check off meds to see trends.';
    }
    final mood = _avgMood;
    final adh = _avgAdherence;
    if (adhPts == 0) {
      return 'Mood data is building. Check off today’s meds so adherence can appear beside mood.';
    }
    if (moodPts == 0) {
      return 'Medication logs are in. Add diary entries to compare mood with adherence.';
    }
    if (adh >= 0.85 && mood >= 6) {
      return 'Mood and adherence are both steady this period — keep the current routine.';
    }
    if (adh < 0.7 && mood < 5) {
      return 'Lower adherence lines up with softer mood days. Gentle reminders may help.';
    }
    if (adh >= 0.85 && mood < 5) {
      return 'Meds look consistent, but mood dipped. Skills practice or a clinician check-in may help.';
    }
    if (adh < 0.7 && mood >= 6) {
      return 'Mood held up even with some missed doses. Still worth tightening the schedule.';
    }
    return 'Mood and adherence across your real logs for this window.';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      List<DiaryEntryModel> diary = const [];
      MedPeriodStats medStats = const MedPeriodStats(
        days: 30,
        activeMeds: 0,
        taken: 0,
        missed: 0,
        logged: 0,
        adherencePct: 0,
      );

      Object? firstError;
      try {
        diary = await DiaryService.instance.loadMyEntries();
      } catch (e) {
        firstError = e;
      }
      try {
        medStats = await MedicationService.instance.loadMyStats(days: 30);
      } catch (e) {
        firstError ??= e;
      }

      if (diary.isEmpty &&
          medStats.byDay.isEmpty &&
          medStats.activeMeds == 0 &&
          firstError != null) {
        throw firstError;
      }

      if (!mounted) return;
      setState(() {
        _allDays = _buildSeries(diary: diary, medStats: medStats);
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

  static String _dayKey(DateTime d) {
    final u = d.toUtc();
    final m = u.month.toString().padLeft(2, '0');
    final day = u.day.toString().padLeft(2, '0');
    return '${u.year}-$m-$day';
  }

  static DateTime _dateFromKey(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return DateTime.now().toUtc();
    return DateTime.utc(
      int.tryParse(parts[0]) ?? 1970,
      int.tryParse(parts[1]) ?? 1,
      int.tryParse(parts[2]) ?? 1,
    );
  }

  static List<_DayPoint> _buildSeries({
    required List<DiaryEntryModel> diary,
    required MedPeriodStats medStats,
  }) {
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final medByDay = {
      for (final d in medStats.byDay) d.dayKey: d,
    };
    final active = medStats.activeMeds;

    final moodByDay = <String, List<double>>{};
    final urgeByDay = <String, List<double>>{};
    final diaryDays = <String>{};

    for (final e in diary) {
      final key = _dayKey(e.createdAt);
      diaryDays.add(key);
      if (e.kind == DiaryEntryKind.dbtCard && e.mood > 0) {
        moodByDay.putIfAbsent(key, () => []).add(e.mood.toDouble());
        final urge = math.max(e.urgeNssi, e.urgeSubstance).toDouble();
        urgeByDay.putIfAbsent(key, () => []).add(urge);
      }
    }

    return List.generate(30, (i) {
      final day = today.subtract(Duration(days: 29 - i));
      final key = _dayKey(day);
      final moods = moodByDay[key];
      final urges = urgeByDay[key];
      final med = medByDay[key];
      final logged = (med?.taken ?? 0) + (med?.missed ?? 0);

      double adherence = 0;
      var hasAdherence = false;
      if (active > 0) {
        hasAdherence = true;
        adherence = (med?.taken ?? 0) / active;
      } else if (logged > 0) {
        hasAdherence = true;
        adherence = (med?.taken ?? 0) / logged;
      }

      final hasMood = moods != null && moods.isNotEmpty;
      final mood = hasMood
          ? moods.reduce((a, b) => a + b) / moods.length
          : 0.0;
      final urge = (urges != null && urges.isNotEmpty)
          ? urges.reduce(math.max)
          : 0.0;

      return _DayPoint(
        date: _dateFromKey(key).toLocal(),
        mood: mood,
        adherence: adherence.clamp(0.0, 1.0),
        urge: urge,
        hasDiary: diaryDays.contains(key),
        hasMood: hasMood,
        hasAdherence: hasAdherence,
      );
    });
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
                    'Dashboard',
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
                  'Mood scores and medication adherence from your diary and med logs.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    height: 1.4,
                    color: CuramindColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 16),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  _ErrorBox(message: _error!, onRetry: _load)
                else ...[
                  _RangeChips(
                    selected: _rangeDays,
                    onSelected: (d) => setState(() => _rangeDays = d),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          label: 'Avg mood',
                          value: _visible.any((p) => p.hasMood)
                              ? _avgMood.toStringAsFixed(1)
                              : '—',
                          hint: 'of 10',
                          color: CuramindColors.sageDeep,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          label: 'Adherence',
                          value: _visible.any((p) => p.hasAdherence)
                              ? '${(_avgAdherence * 100).round()}%'
                              : '—',
                          hint: 'of doses',
                          color: CuramindColors.ocean,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          label: 'Diary days',
                          value: '$_diaryCount',
                          hint: 'of $_rangeDays',
                          color: CuramindColors.slate,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          label: 'Peak urge',
                          value: _visible.any((p) => p.hasMood)
                              ? _peakUrge.toStringAsFixed(0)
                              : '—',
                          hint: 'of 10',
                          color: CuramindColors.danger,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _DualChartCard(points: _visible),
                  const SizedBox(height: 12),
                  _InsightCard(text: _insight),
                  const SizedBox(height: 18),
                  Text(
                    'Recent days',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CuramindColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._visible.reversed.take(5).map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _DayRow(point: p),
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

class _DayPoint {
  const _DayPoint({
    required this.date,
    required this.mood,
    required this.adherence,
    required this.urge,
    required this.hasDiary,
    required this.hasMood,
    required this.hasAdherence,
  });

  final DateTime date;
  final double mood;
  final double adherence;
  final double urge;
  final bool hasDiary;
  final bool hasMood;
  final bool hasAdherence;
}

class _RangeChips extends StatelessWidget {
  const _RangeChips({
    required this.selected,
    required this.onSelected,
  });

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [7, 14, 30].map((d) {
        final on = selected == d;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: d == 30 ? 0 : 8),
            child: Material(
              color: on
                  ? CuramindColors.sageDeep
                  : CuramindColors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onSelected(d),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: on
                          ? CuramindColors.sageDeep
                          : CuramindColors.mistBlue,
                    ),
                  ),
                  child: Text(
                    '${d}d',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      color: on ? CuramindColors.white : CuramindColors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.hint,
    required this.color,
  });

  final String label;
  final String value;
  final String hint;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CuramindColors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CuramindColors.mistBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
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
              const SizedBox(width: 6),
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

class _DualChartCard extends StatelessWidget {
  const _DualChartCard({required this.points});

  final List<_DayPoint> points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: CuramindColors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CuramindColors.mistBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Mood × adherence',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: CuramindColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Left: mood (0–10) · Right: adherence %',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: CuramindColors.inkMuted,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: _DualAxisPainter(points: points),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _LegendDot(color: CuramindColors.sageDeep, label: 'Mood'),
              const SizedBox(width: 16),
              _LegendDot(color: CuramindColors.slate, label: 'Adherence'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
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

class _DualAxisPainter extends CustomPainter {
  _DualAxisPainter({required this.points});

  final List<_DayPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const leftPad = 28.0;
    const rightPad = 28.0;
    const topPad = 8.0;
    const bottomPad = 22.0;

    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - topPad - bottomPad;
    final origin = Offset(leftPad, topPad + chartH);

    final gridPaint = Paint()
      ..color = CuramindColors.mistBlue
      ..strokeWidth = 1;

    final labelStyle = TextStyle(
      color: CuramindColors.inkMuted,
      fontSize: 10,
      fontFamily: 'Outfit',
    );

    for (var i = 0; i <= 4; i++) {
      final t = i / 4;
      final y = topPad + chartH * (1 - t);
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(leftPad + chartW, y),
        gridPaint,
      );

      final moodLabel = (t * 10).round().toString();
      final adhLabel = '${(t * 100).round()}';
      _drawText(canvas, moodLabel, Offset(2, y - 6), labelStyle);
      _drawText(
        canvas,
        adhLabel,
        Offset(leftPad + chartW + 4, y - 6),
        labelStyle,
      );
    }

    final n = points.length;
    final stepX = n == 1 ? 0.0 : chartW / (n - 1);

    final barPaint = Paint()
      ..color = CuramindColors.slate.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    final barW = (stepX * 0.45).clamp(4.0, 14.0);

    for (var i = 0; i < n; i++) {
      if (!points[i].hasAdherence) continue;
      final x = leftPad + i * stepX;
      final h = points[i].adherence * chartH;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - barW / 2, origin.dy - h, barW, h),
          const Radius.circular(3),
        ),
        barPaint,
      );
    }

    final linePaint = Paint()
      ..color = CuramindColors.sageDeep
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    var started = false;
    for (var i = 0; i < n; i++) {
      if (!points[i].hasMood) {
        started = false;
        continue;
      }
      final x = leftPad + i * stepX;
      final y = origin.dy - (points[i].mood / 10) * chartH;
      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = CuramindColors.sageDeep;
    final ringPaint = Paint()
      ..color = CuramindColors.white
      ..style = PaintingStyle.fill;

    for (var i = 0; i < n; i++) {
      if (!points[i].hasMood) continue;
      final x = leftPad + i * stepX;
      final y = origin.dy - (points[i].mood / 10) * chartH;
      canvas.drawCircle(Offset(x, y), 4.5, ringPaint);
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }

    final labelIdx = n <= 3 ? List.generate(n, (i) => i) : [0, n ~/ 2, n - 1];
    for (final i in labelIdx.toSet()) {
      final x = leftPad + i * stepX;
      final d = points[i].date;
      final label = '${d.month}/${d.day}';
      _drawText(
        canvas,
        label,
        Offset(x - 12, origin.dy + 6),
        labelStyle,
      );
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _DualAxisPainter oldDelegate) =>
      oldDelegate.points != points;
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CuramindColors.sageSoft.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CuramindColors.sageSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.insights_outlined,
            color: CuramindColors.sageDeep,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 13,
                height: 1.45,
                color: CuramindColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.point});

  final _DayPoint point;

  @override
  Widget build(BuildContext context) {
    final d = point.date;
    final weekday = const [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ][d.weekday - 1];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CuramindColors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CuramindColors.mistBlue),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weekday,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CuramindColors.ink,
                  ),
                ),
                Text(
                  '${d.month}/${d.day}',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: CuramindColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  point.hasMood
                      ? 'Mood ${point.mood.toStringAsFixed(1)} · Urge ${point.urge.toStringAsFixed(0)}'
                      : 'No mood log',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: CuramindColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  point.hasDiary ? 'Diary logged' : 'No diary entry',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: CuramindColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            point.hasAdherence
                ? '${(point.adherence * 100).round()}%'
                : '—',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: !point.hasAdherence
                  ? CuramindColors.inkMuted
                  : point.adherence < 0.75
                      ? CuramindColors.danger
                      : CuramindColors.sageDeep,
            ),
          ),
        ],
      ),
    );
  }
}
