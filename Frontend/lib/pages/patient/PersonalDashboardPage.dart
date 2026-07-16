import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  static final List<_DayPoint> _allDays = _buildDemoSeries();

  List<_DayPoint> get _visible {
    return _allDays.sublist(_allDays.length - _rangeDays);
  }

  double get _avgMood {
    final pts = _visible;
    if (pts.isEmpty) return 0;
    return pts.map((p) => p.mood).reduce((a, b) => a + b) / pts.length;
  }

  double get _avgAdherence {
    final pts = _visible;
    if (pts.isEmpty) return 0;
    return pts.map((p) => p.adherence).reduce((a, b) => a + b) / pts.length;
  }

  int get _diaryCount => _visible.where((p) => p.hasDiary).length;

  double get _peakUrge {
    if (_visible.isEmpty) return 0;
    return _visible.map((p) => p.urge).reduce(math.max);
  }

  String get _insight {
    final mood = _avgMood;
    final adh = _avgAdherence;
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
    return 'Mood and adherence move together across the window — tap days on the chart for detail.';
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
                'Mood scores and medication adherence over time.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  height: 1.4,
                  color: CuramindColors.inkMuted,
                ),
              ),
              const SizedBox(height: 16),
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
                      value: _avgMood.toStringAsFixed(1),
                      hint: 'of 10',
                      color: CuramindColors.sageDeep,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      label: 'Adherence',
                      value: '${(_avgAdherence * 100).round()}%',
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
                      value: _peakUrge.toStringAsFixed(0),
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
              const SizedBox(height: 8),
              Text(
                'Demo data for now. Live diary and med logs will feed this chart later.',
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

List<_DayPoint> _buildDemoSeries() {
  final now = DateTime.now();
  const moods = [
    5.0, 6.0, 4.5, 5.5, 7.0, 6.5, 5.0, 4.0, 3.5, 5.0,
    6.0, 7.5, 7.0, 6.0, 5.5, 6.5, 7.0, 8.0, 6.5, 5.0,
    4.5, 5.5, 6.0, 6.5, 7.0, 6.0, 5.5, 6.0, 7.0, 6.5,
  ];
  const adherence = [
    1.0, 1.0, 0.75, 1.0, 1.0, 0.5, 1.0, 0.75, 0.5, 1.0,
    1.0, 1.0, 1.0, 0.75, 1.0, 1.0, 1.0, 1.0, 0.75, 0.5,
    0.75, 1.0, 1.0, 1.0, 1.0, 0.75, 1.0, 1.0, 1.0, 1.0,
  ];
  const urges = [
    4.0, 3.0, 6.0, 4.0, 2.0, 3.0, 5.0, 7.0, 8.0, 4.0,
    3.0, 2.0, 2.0, 3.0, 4.0, 2.0, 2.0, 1.0, 3.0, 5.0,
    6.0, 4.0, 3.0, 2.0, 2.0, 3.0, 3.0, 2.0, 2.0, 2.0,
  ];

  return List.generate(30, (i) {
    final day = now.subtract(Duration(days: 29 - i));
    return _DayPoint(
      date: DateTime(day.year, day.month, day.day),
      mood: moods[i],
      adherence: adherence[i],
      urge: urges[i],
      hasDiary: i % 3 != 1,
    );
  });
}

class _DayPoint {
  const _DayPoint({
    required this.date,
    required this.mood,
    required this.adherence,
    required this.urge,
    required this.hasDiary,
  });

  final DateTime date;
  final double mood;
  final double adherence;
  final double urge;
  final bool hasDiary;
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

    // Adherence as soft bars
    final barPaint = Paint()
      ..color = CuramindColors.slate.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    final barW = (stepX * 0.45).clamp(4.0, 14.0);

    for (var i = 0; i < n; i++) {
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

    // Mood line
    final linePaint = Paint()
      ..color = CuramindColors.sageDeep
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (var i = 0; i < n; i++) {
      final x = leftPad + i * stepX;
      final y = origin.dy - (points[i].mood / 10) * chartH;
      if (i == 0) {
        path.moveTo(x, y);
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
      final x = leftPad + i * stepX;
      final y = origin.dy - (points[i].mood / 10) * chartH;
      canvas.drawCircle(Offset(x, y), 4.5, ringPaint);
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }

    // X labels: first, mid, last
    final labelIdx = n <= 3
        ? List.generate(n, (i) => i)
        : [0, n ~/ 2, n - 1];
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
                  'Mood ${point.mood.toStringAsFixed(1)} · Urge ${point.urge.toStringAsFixed(0)}',
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
            '${(point.adherence * 100).round()}%',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: point.adherence < 0.75
                  ? CuramindColors.danger
                  : CuramindColors.sageDeep,
            ),
          ),
        ],
      ),
    );
  }
}
