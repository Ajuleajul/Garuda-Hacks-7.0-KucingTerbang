import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/curamind_theme.dart';
import '../../animated_cursor.dart';
import 'PatientMonitoringDashboard.dart';

class PatientDetailsPage extends StatelessWidget {
  final MockPatient patient;

  const PatientDetailsPage({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final bool hasAlert = patient.hasNssiAlert || patient.missedMedicationAlert;

    return Scaffold(
      backgroundColor: CuramindColors.mist,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  CursorHoverRegion(
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name,
                          style: GoogleFonts.fraunces(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: CuramindColors.ink,
                          ),
                        ),
                        Text(
                          'Patient ID: #${patient.id.padLeft(4, '0')}',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: CuramindColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasAlert)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Action Required',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Overview Cards
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Overall Adherence',
                      value: '${(patient.adherence * 100).toInt()}%',
                      color: patient.adherence < 0.8 ? Colors.orangeAccent : CuramindColors.sageDeep,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Current Mood Avg',
                      value: '${(patient.recentMood.reduce((a,b)=>a+b)/patient.recentMood.length).toStringAsFixed(1)} / 10',
                      color: CuramindColors.ocean,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Chart Area
              Text(
                'Recent Mood Trend',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: CuramindColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 200,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: CuramindColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: CuramindColors.sageSoft),
                  boxShadow: [
                    BoxShadow(
                      color: CuramindColors.slate.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _BigSparklinePainter(moods: patient.recentMood, color: CuramindColors.ocean),
                  child: const SizedBox.expand(),
                ),
              ),
              const SizedBox(height: 32),

              // Alerts / Logs
              Text(
                'Recent Clinical Logs & Alerts',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: CuramindColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              if (patient.hasNssiAlert)
                 _LogEntry(
                   title: 'NSSI Urge Logged',
                   description: 'Patient reported a high urge for non-suicidal self-injury on the DBT diary card.',
                   isWarning: true,
                   time: '2 hours ago',
                 ),
              if (patient.missedMedicationAlert)
                 _LogEntry(
                   title: 'Missed Medication',
                   description: 'System flagged missing adherence data for yesterday\'s prescribed dose.',
                   isWarning: true,
                   time: '1 day ago',
                 ),
              const _LogEntry(
                title: 'Routine Check-in Completed',
                description: 'Patient completed the standard weekly mood and symptom assessment.',
                isWarning: false,
                time: '3 days ago',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CuramindColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CuramindColors.sageSoft),
        boxShadow: [
          BoxShadow(
            color: CuramindColors.slate.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: CuramindColors.slate,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogEntry extends StatelessWidget {
  final String title;
  final String description;
  final bool isWarning;
  final String time;

  const _LogEntry({
    required this.title,
    required this.description,
    required this.isWarning,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CuramindColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWarning ? Colors.redAccent.withValues(alpha: 0.3) : CuramindColors.sageSoft,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isWarning ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
            color: isWarning ? Colors.redAccent : CuramindColors.ocean,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CuramindColors.ink,
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: CuramindColors.inkMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: CuramindColors.slate,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BigSparklinePainter extends CustomPainter {
  final List<double> moods;
  final Color color;

  _BigSparklinePainter({required this.moods, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = color
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final paintFill = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    
    final double stepX = size.width / (moods.length - 1);
    
    final double minY = moods.reduce((a, b) => a < b ? a : b) - 1;
    final double maxY = moods.reduce((a, b) => a > b ? a : b) + 1;
    final double rangeY = (maxY - minY).clamp(1.0, 10.0);

    Offset getPoint(int i) {
      final double x = i * stepX;
      final double normalizedY = 1 - ((moods[i] - minY) / rangeY);
      final double y = normalizedY * size.height;
      return Offset(x, y);
    }

    final p0 = getPoint(0);
    path.moveTo(p0.dx, p0.dy);
    fillPath.moveTo(p0.dx, size.height);
    fillPath.lineTo(p0.dx, p0.dy);

    for (int i = 0; i < moods.length - 1; i++) {
      final p1 = getPoint(i);
      final p2 = getPoint(i + 1);

      final cp1 = Offset(p1.dx + stepX / 2, p1.dy);
      final cp2 = Offset(p2.dx - stepX / 2, p2.dy);

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
      fillPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, paintFill);
    canvas.drawPath(path, paintLine);
    
    final dotOuter = Paint()..color = CuramindColors.white;
    final dotInner = Paint()..color = color;
    
    for (int i = 0; i < moods.length; i++) {
      final p = getPoint(i);
      canvas.drawCircle(p, 8, dotOuter);
      canvas.drawCircle(p, 5, dotInner);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
