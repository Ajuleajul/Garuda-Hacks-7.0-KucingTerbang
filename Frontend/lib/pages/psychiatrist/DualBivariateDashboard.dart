import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../animated_cursor.dart';
import '../../theme/curamind_theme.dart';

class DualBivariateDashboard extends StatefulWidget {
  const DualBivariateDashboard({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

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

  int _selectedDays = 30;
  List<FlSpot> _moodSpots = [];
  List<FlSpot> _adherenceSpots = [];

  double _avgMood = 0;
  double _avgAdherence = 0;

  @override
  void initState() {
    super.initState();
    _generateMockData();
  }

  void _generateMockData() {
    final random = Random(_selectedPatient.hashCode + _selectedDays);
    _moodSpots = [];
    _adherenceSpots = [];

    double currentMood = 6.5;
    double currentAdherence = 85.0;

    double sumMood = 0;
    double sumAdherence = 0;

    for (int i = 0; i < _selectedDays; i++) {
      currentMood += (random.nextDouble() * 2 - 1);
      currentMood = currentMood.clamp(3.0, 9.5);

      if (currentMood < 5.0) {
        currentAdherence -= random.nextDouble() * 15;
      } else {
        currentAdherence += random.nextDouble() * 10;
      }
      currentAdherence = currentAdherence.clamp(40.0, 100.0);

      sumMood += currentMood;
      sumAdherence += currentAdherence;

      _moodSpots.add(FlSpot(i.toDouble(), currentMood * 10));
      _adherenceSpots.add(FlSpot(i.toDouble(), currentAdherence));
    }

    _avgMood = sumMood / _selectedDays;
    _avgAdherence = sumAdherence / _selectedDays;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
              const SizedBox(width: 12),
              Tooltip(
                message:
                    "Visualizing mood variations alongside medication adherence has been shown to be beneficial for patient self-awareness, adherence, and the patient-physician relationship (Hamlin et al., 2023).",
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: CuramindColors.ink.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.outfit(
                  color: CuramindColors.white,
                  fontSize: 13,
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: CuramindColors.slate,
                  size: 22,
                ),
              ),
            ],
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
                              _generateMockData();
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
                child: PopupMenuButton<int>(
                  initialValue: _selectedDays,
                  onSelected: (val) {
                    setState(() {
                      _selectedDays = val;
                      _generateMockData();
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 7, child: Text('Last 7 Days')),
                    const PopupMenuItem(value: 30, child: Text('Last 30 Days')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: CuramindColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: CuramindColors.sageSoft),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list_rounded,
                            size: 20, color: CuramindColors.slate),
                        const SizedBox(width: 8),
                        Text('Last $_selectedDays Days',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w500,
                              color: CuramindColors.slate,
                            )),
                      ],
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
                          label: 'Mood Score (x10)',
                        ),
                        const SizedBox(width: 16),
                        _LegendItem(
                          color: CuramindColors.sageDeep,
                          label: 'Med Adherence (%)',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 100,
                      minX: 0,
                      maxX: (_selectedDays - 1).toDouble(),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 20,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: CuramindColors.mistBlue,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: _selectedDays == 30 ? 7 : 1,
                            getTitlesWidget: (value, meta) {
                              if (value == _selectedDays - 1 || value == 0) return const SizedBox.shrink();
                              return SideTitleWidget(
                                meta: meta,
                                space: 8,
                                child: Text(
                                  'Day ${value.toInt() + 1}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: CuramindColors.inkMuted,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _moodSpots,
                          isCurved: true,
                          color: CuramindColors.ocean,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: CuramindColors.ocean.withValues(alpha: 0.1),
                          ),
                        ),
                        LineChartBarData(
                          spots: _adherenceSpots,
                          isCurved: true,
                          color: CuramindColors.sageDeep,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: CuramindColors.sageDeep.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (touchedSpot) => CuramindColors.white,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              if (spot.barIndex == 0) {
                                return LineTooltipItem(
                                  'Mood: ${(spot.y / 10).toStringAsFixed(1)}/10',
                                  GoogleFonts.outfit(
                                    color: CuramindColors.ocean,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              } else {
                                return LineTooltipItem(
                                  'Adherence: ${spot.y.toStringAsFixed(0)}%',
                                  GoogleFonts.outfit(
                                    color: CuramindColors.sageDeep,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }
                            }).toList();
                          },
                        ),
                      ),
                    ),
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
                  value: '${_avgAdherence.toStringAsFixed(1)}%',
                  trend: _avgAdherence > 80 ? '+ Good' : '- Watch',
                  isPositive: _avgAdherence > 80,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  title: 'Avg Mood',
                  value: '${_avgMood.toStringAsFixed(1)} / 10',
                  trend: _avgMood > 6.5 ? '+ Stable' : '- Low',
                  isPositive: _avgMood > 6.5,
                ),
              ),
            ],
          ),
        ],
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
        border: Border.all(
            color: CuramindColors.sageSoft.withValues(alpha: 0.5)),
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
                    color: isPositive
                        ? CuramindColors.sageDeep
                        : CuramindColors.danger,
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
