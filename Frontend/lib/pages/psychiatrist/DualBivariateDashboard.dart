import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../animated_cursor.dart';
import '../../services/diary_service.dart';
import '../../services/link_service.dart';
import '../../services/medication_service.dart';
import '../../theme/curamind_theme.dart';

class DualBivariateDashboard extends StatefulWidget {
  const DualBivariateDashboard({
    super.key,
    this.embedded = false,
    this.active = true,
  });

  final bool embedded;
  final bool active;

  @override
  State<DualBivariateDashboard> createState() => _DualBivariateDashboardState();
}

class _DualBivariateDashboardState extends State<DualBivariateDashboard> {
  List<JoinGroup> _groups = [];
  List<GroupMember> _members = [];
  String? _selectedGroupId;
  String? _selectedPatientId;
  int _selectedDays = 30;

  bool _loadingMeta = true;
  bool _loadingChart = false;
  String? _error;

  List<FlSpot> _moodSpots = [];
  List<FlSpot> _adherenceSpots = [];
  List<String> _dayLabels = [];
  int _moodDays = 0;
  int _adherenceDays = 0;
  double _avgMood = 0;
  double _avgAdherence = 0;
  int _diaryCards = 0;
  int _activeMeds = 0;

  JoinGroup? get _selectedGroup {
    for (final g in _groups) {
      if (g.id == _selectedGroupId) return g;
    }
    return null;
  }

  GroupMember? get _selectedMember {
    for (final m in _members) {
      if (m.patientId == _selectedPatientId) return m;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    if (widget.active) _loadGroups();
  }

  @override
  void didUpdateWidget(covariant DualBivariateDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _loadGroups();
    }
  }

  Future<void> _loadGroups() async {
    setState(() {
      _loadingMeta = true;
      _error = null;
    });
    try {
      final groups = await LinkService.instance.listMyGroups();
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _loadingMeta = false;
        if (groups.isNotEmpty) {
          _selectedGroupId = groups.first.id;
        }
      });
      if (groups.isNotEmpty) {
        await _loadMembers(groups.first.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingMeta = false;
      });
    }
  }

  Future<void> _loadMembers(String groupId) async {
    setState(() {
      _loadingMeta = true;
      _members = [];
      _selectedPatientId = null;
      _clearChart();
      _error = null;
    });
    try {
      final members = await LinkService.instance.listGroupMembers(groupId);
      if (!mounted) return;
      setState(() {
        _members = members;
        _loadingMeta = false;
        _selectedPatientId =
            members.isNotEmpty ? members.first.patientId : null;
      });
      if (members.isNotEmpty) {
        await _loadChartData();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingMeta = false;
      });
    }
  }

  void _clearChart() {
    _moodSpots = [];
    _adherenceSpots = [];
    _dayLabels = [];
    _moodDays = 0;
    _adherenceDays = 0;
    _avgMood = 0;
    _avgAdherence = 0;
    _diaryCards = 0;
    _activeMeds = 0;
  }

  static String _dayKey(DateTime dt) {
    final d = dt.toUtc();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _loadChartData() async {
    final patientId = _selectedPatientId;
    if (patientId == null) {
      setState(_clearChart);
      return;
    }

    setState(() {
      _loadingChart = true;
      _error = null;
    });

    try {
      final member = _selectedMember;
      final results = await Future.wait([
        (member != null && member.monitoringOn)
            ? DiaryService.instance.loadClinicianPatientEntries(
                patientId,
                limit: 200,
              )
            : Future.value(const <DiaryEntryModel>[]),
        MedicationService.instance.loadPatientPeriodStats(
          patientId,
          days: _selectedDays,
        ),
      ]);
      final diary = results[0] as List<DiaryEntryModel>;
      final medStats = results[1] as MedPeriodStats;

      final now = DateTime.now().toUtc();
      final today = DateTime.utc(now.year, now.month, now.day);
      final medByDay = {
        for (final d in medStats.byDay) d.dayKey: d,
      };

      final moodByDay = <String, List<double>>{};
      var diaryCards = 0;
      for (final e in diary) {
        final age = today.difference(
          DateTime.utc(
            e.createdAt.toUtc().year,
            e.createdAt.toUtc().month,
            e.createdAt.toUtc().day,
          ),
        );
        if (age.inDays < 0 || age.inDays >= _selectedDays) continue;
        if (e.kind == DiaryEntryKind.dbtCard) {
          diaryCards += 1;
          if (e.mood > 0) {
            final key = _dayKey(e.createdAt);
            moodByDay.putIfAbsent(key, () => []).add(e.mood.toDouble());
          }
        }
      }

      final moodSpots = <FlSpot>[];
      final adherenceSpots = <FlSpot>[];
      final labels = <String>[];
      var sumMood = 0.0;
      var moodCount = 0;
      var sumAdh = 0.0;
      var adhCount = 0;
      final active = medStats.activeMeds;

      for (var i = 0; i < _selectedDays; i++) {
        final day = today.subtract(Duration(days: _selectedDays - 1 - i));
        final key = _dayKey(day);
        final local = day.toLocal();
        labels.add('${local.month}/${local.day}');

        final moods = moodByDay[key];
        if (moods != null && moods.isNotEmpty) {
          final avg = moods.reduce((a, b) => a + b) / moods.length;
          moodSpots.add(FlSpot(i.toDouble(), avg * 10));
          sumMood += avg;
          moodCount += 1;
        }

        final med = medByDay[key];
        final taken = med?.taken ?? 0;
        final missed = med?.missed ?? 0;
        final logged = taken + missed;
        double? adhPct;
        if (active > 0) {
          adhPct = (taken / active) * 100;
        } else if (logged > 0) {
          adhPct = (taken / logged) * 100;
        }
        if (adhPct != null) {
          final clamped = adhPct.clamp(0.0, 100.0);
          adherenceSpots.add(FlSpot(i.toDouble(), clamped));
          sumAdh += clamped;
          adhCount += 1;
        }
      }

      if (!mounted) return;
      setState(() {
        _moodSpots = moodSpots;
        _adherenceSpots = adherenceSpots;
        _dayLabels = labels;
        _moodDays = moodCount;
        _adherenceDays = adhCount;
        _avgMood = moodCount == 0 ? 0 : sumMood / moodCount;
        _avgAdherence = adhCount == 0 ? 0 : sumAdh / adhCount;
        _diaryCards = diaryCards;
        _activeMeds = active;
        _loadingChart = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingChart = false;
        _clearChart();
      });
    }
  }

  Widget _dropdownShell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: CuramindColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CuramindColors.sageSoft),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = RefreshIndicator(
      onRefresh: () async {
        if (_selectedGroupId != null) {
          await _loadMembers(_selectedGroupId!);
        } else {
          await _loadGroups();
        }
      },
      color: CuramindColors.sageDeep,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Dual Chart Analysis',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: CuramindColors.ink,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Tooltip(
                  message:
                      'Mood from DBT diary cards and med adherence from daily logs, aligned by calendar day.',
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
              'Pick a care group and patient to correlate real mood with medication adherence.',
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: CuramindColors.inkMuted,
              ),
            ),
            const SizedBox(height: 20),
            if (_loadingMeta && _groups.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(
                    color: CuramindColors.sageDeep,
                  ),
                ),
              )
            else if (_groups.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CuramindColors.mistBlue.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'No care groups yet. Create a group and link patients first.',
                  style: GoogleFonts.outfit(color: CuramindColors.inkMuted),
                ),
              )
            else ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 640;
                  final groupDrop = _dropdownShell(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedGroupId,
                        isExpanded: true,
                        hint: Text(
                          'Select group',
                          style: GoogleFonts.outfit(
                            color: CuramindColors.inkMuted,
                          ),
                        ),
                        items: _groups
                            .map(
                              (g) => DropdownMenuItem(
                                value: g.id,
                                child: Text(
                                  '${g.name} (${g.memberCount})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (id) async {
                          if (id == null || id == _selectedGroupId) return;
                          setState(() => _selectedGroupId = id);
                          await _loadMembers(id);
                        },
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: CuramindColors.ink,
                        ),
                      ),
                    ),
                  );
                  final patientDrop = _dropdownShell(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPatientId,
                        isExpanded: true,
                        hint: Text(
                          _members.isEmpty
                              ? 'No patients in group'
                              : 'Select patient',
                          style: GoogleFonts.outfit(
                            color: CuramindColors.inkMuted,
                          ),
                        ),
                        items: _members
                            .map(
                              (m) => DropdownMenuItem(
                                value: m.patientId,
                                child: Text(
                                  m.patientName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _members.isEmpty
                            ? null
                            : (id) async {
                                if (id == null) return;
                                setState(() => _selectedPatientId = id);
                                await _loadChartData();
                              },
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: CuramindColors.ink,
                        ),
                      ),
                    ),
                  );
                  final rangeBtn = CursorHoverRegion(
                    child: PopupMenuButton<int>(
                      initialValue: _selectedDays,
                      onSelected: (val) async {
                        setState(() => _selectedDays = val);
                        await _loadChartData();
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 7, child: Text('Last 7 Days')),
                        PopupMenuItem(value: 14, child: Text('Last 14 Days')),
                        PopupMenuItem(value: 30, child: Text('Last 30 Days')),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: CuramindColors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: CuramindColors.sageSoft),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.filter_list_rounded,
                              size: 20,
                              color: CuramindColors.slate,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Last $_selectedDays Days',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w500,
                                color: CuramindColors.slate,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );

                  if (wide) {
                    return Row(
                      children: [
                        Expanded(child: groupDrop),
                        const SizedBox(width: 10),
                        Expanded(child: patientDrop),
                        const SizedBox(width: 10),
                        rangeBtn,
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      groupDrop,
                      const SizedBox(height: 10),
                      patientDrop,
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: rangeBtn,
                      ),
                    ],
                  );
                },
              ),
              if (_selectedMember != null) ...[
                const SizedBox(height: 12),
                Text(
                  [
                    _selectedGroup?.name ?? 'Group',
                    _selectedMember!.patientName,
                    if (_selectedMember!.email != null &&
                        _selectedMember!.email!.isNotEmpty)
                      _selectedMember!.email!,
                  ].join(' · '),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: CuramindColors.inkMuted,
                  ),
                ),
                if (!_selectedMember!.monitoringOn) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Monitoring is off for this patient. Mood diary is hidden; adherence still shows.',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: CuramindColors.danger,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 16),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: GoogleFonts.outfit(color: CuramindColors.danger),
                  ),
                ),
              if (_loadingChart)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: CuramindColors.sageDeep,
                    ),
                  ),
                )
              else if (_selectedPatientId == null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: CuramindColors.mistBlue.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Select a patient in this group to plot mood vs adherence.',
                    style: GoogleFonts.outfit(color: CuramindColors.inkMuted),
                  ),
                )
              else
                _buildChartCard(),
              if (_selectedPatientId != null && !_loadingChart) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Avg adherence',
                        value: _adherenceDays == 0
                            ? '—'
                            : '${_avgAdherence.toStringAsFixed(0)}%',
                        trend: _adherenceDays == 0
                            ? 'No logs'
                            : _avgAdherence > 80
                                ? '+ Good'
                                : '- Watch',
                        isPositive: _adherenceDays > 0 && _avgAdherence > 80,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Avg mood',
                        value: _moodDays == 0
                            ? '—'
                            : '${_avgMood.toStringAsFixed(1)} / 10',
                        trend: _moodDays == 0
                            ? 'No diary'
                            : _avgMood > 6.5
                                ? '+ Stable'
                                : '- Low',
                        isPositive: _moodDays > 0 && _avgMood > 6.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'DBT cards in range',
                        value: '$_diaryCards',
                        trend: '$_moodDays mood days',
                        isPositive: _diaryCards > 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Active meds',
                        value: '$_activeMeds',
                        trend: '$_adherenceDays logged days',
                        isPositive: _activeMeds > 0,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
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

  Widget _buildChartCard() {
    final hasData = _moodSpots.isNotEmpty || _adherenceSpots.isNotEmpty;
    return Container(
      height: 400,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CuramindColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CuramindColors.mistBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Mood vs Adherence',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: CuramindColors.ink,
                  ),
                ),
              ),
              _LegendItem(
                color: CuramindColors.ocean,
                label: 'Mood (×10)',
              ),
              const SizedBox(width: 12),
              _LegendItem(
                color: CuramindColors.sageDeep,
                label: 'Adherence %',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Both series use the same 0–100 axis. Mood 7/10 plots as 70.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: CuramindColors.inkMuted,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: !hasData
                ? Center(
                    child: Text(
                      'No diary mood or medication logs in this range yet.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: CuramindColors.inkMuted,
                      ),
                    ),
                  )
                : LineChart(
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
                            reservedSize: 28,
                            interval: _selectedDays <= 7
                                ? 1
                                : _selectedDays <= 14
                                    ? 2
                                    : 5,
                            getTitlesWidget: (value, meta) {
                              final i = value.round();
                              if (i < 0 || i >= _dayLabels.length) {
                                return const SizedBox.shrink();
                              }
                              return SideTitleWidget(
                                meta: meta,
                                space: 6,
                                child: Text(
                                  _dayLabels[i],
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    color: CuramindColors.inkMuted,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            interval: 20,
                            getTitlesWidget: (v, _) => Text(
                              v.toInt().toString(),
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: CuramindColors.inkMuted,
                              ),
                            ),
                          ),
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
                        if (_moodSpots.isNotEmpty)
                          LineChartBarData(
                            spots: _moodSpots,
                            isCurved: true,
                            color: CuramindColors.ocean,
                            barWidth: 3,
                            dotData: FlDotData(
                              show: _moodSpots.length <= 14,
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: CuramindColors.ocean
                                  .withValues(alpha: 0.1),
                            ),
                          ),
                        if (_adherenceSpots.isNotEmpty)
                          LineChartBarData(
                            spots: _adherenceSpots,
                            isCurved: true,
                            color: CuramindColors.sageDeep,
                            barWidth: 3,
                            dotData: FlDotData(
                              show: _adherenceSpots.length <= 14,
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: CuramindColors.sageDeep
                                  .withValues(alpha: 0.1),
                            ),
                          ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => CuramindColors.white,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final i = spot.x.round();
                              final day = (i >= 0 && i < _dayLabels.length)
                                  ? _dayLabels[i]
                                  : '';
                              final isMood =
                                  spot.bar.color == CuramindColors.ocean;
                              if (isMood) {
                                return LineTooltipItem(
                                  '$day\nMood: ${(spot.y / 10).toStringAsFixed(1)}/10',
                                  GoogleFonts.outfit(
                                    color: CuramindColors.ocean,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                );
                              }
                              return LineTooltipItem(
                                '$day\nAdherence: ${spot.y.toStringAsFixed(0)}%',
                                GoogleFonts.outfit(
                                  color: CuramindColors.sageDeep,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
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
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CuramindColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CuramindColors.sageSoft.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: CuramindColors.slate,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: CuramindColors.ink,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive
                      ? CuramindColors.sageSoft.withValues(alpha: 0.5)
                      : CuramindColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trend,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
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
