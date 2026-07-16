import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../../animated_cursor.dart';
import '../../theme/curamind_theme.dart';

class DualBivariateDashboard extends StatefulWidget {
  const DualBivariateDashboard({super.key});

  @override
  State<DualBivariateDashboard> createState() => _DualBivariateDashboardState();
}

class _DualBivariateDashboardState extends State<DualBivariateDashboard> {
  String _selectedPatient = 'Alex Johnson';
  final List<String> _patients = [
    'Alex Johnson',
    'Sarah Williams',
    'Michael Chen',
    'Emma Davis'
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Dual Chart Analysis',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: CuramindColors.ink,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Correlate mood fluctuations with medication adherence over time.',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: CuramindColors.inkMuted,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: CuramindColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: CuramindColors.sageSoft),
                      ),
                      child: CursorHoverRegion(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedPatient,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down,
                                color: CuramindColors.slate),
                            dropdownColor: CuramindColors.white,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: CuramindColors.ink,
                            ),
                            items: _patients.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedPatient = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CursorHoverRegion(
                    child: FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.filter_list_rounded, size: 20),
                      label: const Text('Last 30 Days'),
                      style: FilledButton.styleFrom(
                        backgroundColor: CuramindColors.white,
                        foregroundColor: CuramindColors.slate,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(
                              color: CuramindColors.sageSoft),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                height: 380,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: CuramindColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: CuramindColors.slate.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mood vs Adherence',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: CuramindColors.ink,
                          ),
                        ),
                        Row(
                          children: [
                            _LegendItem(
                              color: CuramindColors.ocean,
                              label: 'Mood Score',
                            ),
                            const SizedBox(width: 16),
                            _LegendItem(
                              color: CuramindColors.sageDeep,
                              label: 'Med Adherence',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: CustomPaint(
                        painter: _BivariateChartPainter(),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Avg Adherence',
                      value: '86%',
                      trend: '+4%',
                      isPositive: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Avg Mood',
                      value: '7.2 / 10',
                      trend: '-0.5',
                      isPositive: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: CuramindColors.inkMuted,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final bool isPositive;

  const _StatCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CuramindColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CuramindColors.sageSoft.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: CuramindColors.slate,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: CuramindColors.ink,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive
                      ? CuramindColors.sageSoft.withValues(alpha: 0.5)
                      : CuramindColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trend,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isPositive ? CuramindColors.sageDeep : CuramindColors.danger,
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

class _BivariateChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = CuramindColors.mistBlue
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const xSegments = 6;
    final xStep = size.width / xSegments;
    for (int i = 0; i <= xSegments; i++) {
      canvas.drawLine(
        Offset(i * xStep, 0),
        Offset(i * xStep, size.height),
        paintGrid,
      );
    }

    const ySegments = 4;
    final yStep = size.height / ySegments;
    for (int i = 0; i <= ySegments; i++) {
      canvas.drawLine(
        Offset(0, i * yStep),
        Offset(size.width, i * yStep),
        paintGrid,
      );
    }

    final moodData = [40.0, 50.0, 45.0, 60.0, 55.0, 70.0, 80.0];
    final adherenceData = [80.0, 90.0, 85.0, 100.0, 60.0, 100.0, 100.0];

    _drawSmoothLine(canvas, size, moodData, CuramindColors.ocean);
    _drawSmoothLine(canvas, size, adherenceData, CuramindColors.sageDeep);
  }

  void _drawSmoothLine(Canvas canvas, Size size, List<double> data, Color color) {
    if (data.isEmpty) return;

    final paintLine = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final paintShadow = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (data.length - 1);
    final maxData = 100.0; 

    Offset getPoint(int index) {
      final x = index * stepX;
      final y = size.height - (data[index] / maxData) * size.height;
      return Offset(x, y);
    }

    final p0 = getPoint(0);
    path.moveTo(p0.dx, p0.dy);
    fillPath.moveTo(p0.dx, size.height);
    fillPath.lineTo(p0.dx, p0.dy);

    for (int i = 0; i < data.length - 1; i++) {
      final p1 = getPoint(i);
      final p2 = getPoint(i + 1);

      final controlPoint1 = Offset(p1.dx + stepX / 2, p1.dy);
      final controlPoint2 = Offset(p2.dx - stepX / 2, p2.dy);

      path.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        p2.dx, p2.dy,
      );
      
      fillPath.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        p2.dx, p2.dy,
      );
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, paintShadow);
    canvas.drawPath(path, paintLine);

    final paintDotOuter = Paint()..color = CuramindColors.white;
    final paintDotInner = Paint()..color = color;

    for (int i = 0; i < data.length; i++) {
      final p = getPoint(i);
      canvas.drawCircle(p, 6, paintDotOuter);
      canvas.drawCircle(p, 4, paintDotInner);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
