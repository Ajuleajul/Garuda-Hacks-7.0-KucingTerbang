@ -0,0 +1,401 @@
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../animated_cursor.dart';
import '../../theme/curamind_theme.dart';

class MockPatient {
  final String id;
  final String name;
  final double adherence;
  final bool hasNssiAlert;
  final bool missedMedicationAlert;
  final List<double> recentMood;

  const MockPatient({
    required this.id,
    required this.name,
    required this.adherence,
    this.hasNssiAlert = false,
    this.missedMedicationAlert = false,
    required this.recentMood,
  });
}

final List<MockPatient> _mockPatients = [
  const MockPatient(
    id: '1',
    name: 'Eleanor Vance',
    adherence: 0.92,
    recentMood: [5, 6, 5, 7, 7, 8, 7],
  ),
  const MockPatient(
    id: '2',
    name: 'Theo Crain',
    adherence: 0.45,
    missedMedicationAlert: true,
    recentMood: [4, 4, 3, 2, 4, 3, 2],
  ),
  const MockPatient(
    id: '3',
    name: 'Luke Crain',
    adherence: 0.78,
    hasNssiAlert: true,
    recentMood: [6, 7, 5, 2, 3, 5, 4],
  ),
  const MockPatient(
    id: '4',
    name: 'Steven Crain',
    adherence: 1.0,
    recentMood: [7, 7, 8, 7, 8, 8, 9],
  ),
  const MockPatient(
    id: '5',
    name: 'Shirley Crain',
    adherence: 0.88,
    recentMood: [6, 6, 7, 6, 7, 6, 6],
  ),
];

class PatientMonitoringDashboard extends StatelessWidget {
  const PatientMonitoringDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    int crossAxisCount = 1;
    if (screenWidth > 1200) {
      crossAxisCount = 4;
    } else if (screenWidth > 900) {
      crossAxisCount = 3;
    } else if (screenWidth > 600) {
      crossAxisCount = 2;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Active Patients',
                style: GoogleFonts.fraunces(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: CuramindColors.ink,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Monitor adherence and recent DBT diary trends.',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: CuramindColors.inkMuted,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: _mockPatients.length,
                  itemBuilder: (context, index) {
                    final patient = _mockPatients[index];
                    return _PatientCard(patient: patient);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final MockPatient patient;

  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    final bool hasAlert = patient.hasNssiAlert || patient.missedMedicationAlert;

    return CursorHoverRegion(
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Viewing details for ${patient.name}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: CuramindColors.sageDeep,
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: CuramindColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasAlert ? Colors.red.withValues(alpha: 0.3) : CuramindColors.sageSoft.withValues(alpha: 0.5),
              width: hasAlert ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: CuramindColors.slate.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      patient.name,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: CuramindColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasAlert)
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    )
                  else
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: CuramindColors.sageDeep,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'ID: #${patient.id.padLeft(4, '0')}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: CuramindColors.inkMuted,
                ),
              ),
              const Spacer(),
              if (patient.hasNssiAlert)
                _AlertBadge(
                  label: 'NSSI Urge Logged',
                  color: Colors.redAccent,
                ),
              if (patient.missedMedicationAlert) ...[
                if (patient.hasNssiAlert) const SizedBox(height: 6),
                _AlertBadge(
                  label: 'Missed Medication',
                  color: Colors.orangeAccent,
                ),
              ],
              if (!hasAlert)
                _AlertBadge(
                  label: 'Stable',
                  color: CuramindColors.sageDeep,
                ),
              const Spacer(),
              const Divider(height: 1, color: CuramindColors.sageSoft),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Adherence',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: CuramindColors.inkMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${(patient.adherence * 100).toInt()}%',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: patient.adherence < 0.8 ? Colors.orangeAccent : CuramindColors.ink,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 30,
                    width: 60,
                    alignment: Alignment.centerRight,
                    child: _MiniSparkline(moods: patient.recentMood),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _AlertBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _MiniSparkline extends StatelessWidget {
  final List<double> moods;

  const _MiniSparkline({required this.moods});

  @override
  Widget build(BuildContext context) {
    if (moods.isEmpty) return const SizedBox.shrink();
    return CustomPaint(
      size: const Size(60, 30),
      painter: _SparklinePainter(moods: moods, color: CuramindColors.sageDeep),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> moods;
  final Color color;

  _SparklinePainter({required this.moods, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double stepX = size.width / (moods.length - 1);
    
    final double minY = moods.reduce((a, b) => a < b ? a : b) - 1;
    final double maxY = moods.reduce((a, b) => a > b ? a : b) + 1;
    final double rangeY = (maxY - minY).clamp(1.0, 10.0);

    for (int i = 0; i < moods.length; i++) {
      final double x = i * stepX;
      final double normalizedY = 1 - ((moods[i] - minY) / rangeY);
      final double y = normalizedY * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}