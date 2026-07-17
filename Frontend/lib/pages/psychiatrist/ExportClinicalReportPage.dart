import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../animated_cursor.dart';
import '../../services/clinical_report_service.dart';
import '../../services/link_service.dart';
import '../../theme/curamind_theme.dart';

class ExportClinicalReportPage extends StatefulWidget {
  const ExportClinicalReportPage({
    super.key,
    this.embedded = false,
    this.active = true,
  });

  final bool embedded;
  final bool active;

  @override
  State<ExportClinicalReportPage> createState() =>
      _ExportClinicalReportPageState();
}

class _ExportClinicalReportPageState extends State<ExportClinicalReportPage> {
  List<JoinGroup> _groups = [];
  List<GroupMember> _members = [];
  String? _selectedGroupId;
  String? _selectedPatientId;
  int _selectedDays = 30;

  bool _loadingMeta = true;
  bool _isGenerating = false;
  String? _error;

  bool _includeDemographics = true;
  bool _includeExecutiveSummary = true;
  bool _includeMoodAffect = true;
  bool _includeUrgeRisk = true;
  bool _includeEmotionTags = true;
  bool _includeMedications = true;
  bool _includeAdherenceChart = true;
  bool _includeDiaryLog = true;
  bool _includeCopingLog = true;

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
  void didUpdateWidget(covariant ExportClinicalReportPage oldWidget) {
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
        _selectedGroupId = groups.isNotEmpty ? groups.first.id : null;
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingMeta = false;
      });
    }
  }

  void _selectAll(bool value) {
    setState(() {
      _includeDemographics = value;
      _includeExecutiveSummary = value;
      _includeMoodAffect = value;
      _includeUrgeRisk = value;
      _includeEmotionTags = value;
      _includeMedications = value;
      _includeAdherenceChart = value;
      _includeDiaryLog = value;
      _includeCopingLog = value;
    });
  }

  bool get _anySelected =>
      _includeDemographics ||
      _includeExecutiveSummary ||
      _includeMoodAffect ||
      _includeUrgeRisk ||
      _includeEmotionTags ||
      _includeMedications ||
      _includeAdherenceChart ||
      _includeDiaryLog ||
      _includeCopingLog;

  Future<void> _downloadReport() async {
    final group = _selectedGroup;
    final member = _selectedMember;
    if (group == null || member == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Select a care group and patient first.'),
          backgroundColor: CuramindColors.slate,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!_anySelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Select at least one report section.'),
          backgroundColor: CuramindColors.slate,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final bytes = await ClinicalReportService.instance.buildPdf(
        group: group,
        member: member,
        options: ClinicalReportOptions(
          includeDemographics: _includeDemographics,
          includeExecutiveSummary: _includeExecutiveSummary,
          includeMoodAffect: _includeMoodAffect,
          includeUrgeRisk: _includeUrgeRisk,
          includeEmotionTags: _includeEmotionTags,
          includeMedications: _includeMedications,
          includeAdherenceChart: _includeAdherenceChart,
          includeDiaryLog: _includeDiaryLog,
          includeCopingLog: _includeCopingLog,
          days: _selectedDays,
        ),
      );
      if (!mounted) return;

      final safeName = member.patientName
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .trim()
          .replaceAll(RegExp(r'\s+'), '_');
      final filename =
          'Curamind_Clinical_Report_${safeName.isEmpty ? 'Patient' : safeName}.pdf';

      final savedPath =
          await ClinicalReportService.instance.downloadPdf(bytes, filename);

      if (!mounted) return;
      setState(() => _isGenerating = false);
      final location = savedPath.trim().isEmpty ||
              savedPath.contains('Something went wrong')
          ? 'Downloads'
          : savedPath;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF downloaded: $location'),
          backgroundColor: CuramindColors.sageDeep,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _error = e.toString();
      });
      debugPrint('Clinical PDF failed: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF failed: $e'),
          backgroundColor: CuramindColors.danger,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Widget _dropdown({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: CuramindColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CuramindColors.mistBlue),
      ),
      child: child,
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: CuramindColors.slate,
        ),
      ),
    );
  }

  Widget _checkTile({
    required bool value,
    required String title,
    required String subtitle,
    required ValueChanged<bool?> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: CursorHoverRegion(
        child: CheckboxListTile(
          value: value,
          onChanged: onChanged,
          title: Text(
            title,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: CuramindColors.inkMuted,
            ),
          ),
          activeColor: CuramindColors.sageDeep,
          checkColor: CuramindColors.white,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = RefreshIndicator(
      onRefresh: _loadGroups,
      color: CuramindColors.sageDeep,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Export Clinical Report',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: CuramindColors.ink,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Generate an industry-style PHI PDF: demographics, EMA trends, '
                  'charts, medications, and full diary logs for a linked patient.',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: CuramindColors.inkMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
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
                      'No care groups yet. Create a group and link patients before exporting.',
                      style:
                          GoogleFonts.outfit(color: CuramindColors.inkMuted),
                    ),
                  )
                else ...[
                  _sectionLabel('Care group'),
                  _dropdown(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedGroupId,
                        isExpanded: true,
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
                  ),
                  const SizedBox(height: 16),
                  _sectionLabel('Patient'),
                  _dropdown(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPatientId,
                        isExpanded: true,
                        hint: Text(
                          _members.isEmpty
                              ? 'No patients in this group'
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
                            : (id) =>
                                setState(() => _selectedPatientId = id),
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: CuramindColors.ink,
                        ),
                      ),
                    ),
                  ),
                  if (_selectedMember != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      [
                        if (_selectedMember!.email != null &&
                            _selectedMember!.email!.isNotEmpty)
                          _selectedMember!.email!,
                        '${_selectedMember!.diaryEntries} diary entries',
                        '${_selectedMember!.activeMedsCount} active meds',
                      ].join(' · '),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: CuramindColors.inkMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _sectionLabel('Observation window'),
                  _dropdown(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedDays,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: 7,
                            child: Text('Last 7 days'),
                          ),
                          DropdownMenuItem(
                            value: 14,
                            child: Text('Last 14 days'),
                          ),
                          DropdownMenuItem(
                            value: 30,
                            child: Text('Last 30 days'),
                          ),
                          DropdownMenuItem(
                            value: 90,
                            child: Text('Last 90 days'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedDays = v);
                        },
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: CuramindColors.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _sectionLabel('Included clinical sections'),
                      ),
                      TextButton(
                        onPressed: () => _selectAll(true),
                        child: const Text('All'),
                      ),
                      TextButton(
                        onPressed: () => _selectAll(false),
                        child: const Text('None'),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: CuramindColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: CuramindColors.mistBlue),
                    ),
                    child: Column(
                      children: [
                        _checkTile(
                          value: _includeDemographics,
                          title: 'Patient identification',
                          subtitle:
                              'IDs, care group, link status, clinician attribution',
                          onChanged: (v) => setState(
                            () => _includeDemographics = v ?? true,
                          ),
                        ),
                        const Divider(
                          height: 1,
                          color: CuramindColors.mistBlue,
                        ),
                        _checkTile(
                          value: _includeExecutiveSummary,
                          title: 'Executive clinical summary',
                          subtitle:
                              'Avg mood/affect, peak urge, adherence, alert flags',
                          onChanged: (v) => setState(
                            () => _includeExecutiveSummary = v ?? true,
                          ),
                        ),
                        const Divider(
                          height: 1,
                          color: CuramindColors.mistBlue,
                        ),
                        _checkTile(
                          value: _includeMoodAffect,
                          title: 'Mood & affect trajectory',
                          subtitle: 'Trend chart + daily mood/affect table',
                          onChanged: (v) => setState(
                            () => _includeMoodAffect = v ?? true,
                          ),
                        ),
                        const Divider(
                          height: 1,
                          color: CuramindColors.mistBlue,
                        ),
                        _checkTile(
                          value: _includeUrgeRisk,
                          title: 'Urge & risk monitoring',
                          subtitle: 'Peak NSSI/substance urge chart + table',
                          onChanged: (v) =>
                              setState(() => _includeUrgeRisk = v ?? true),
                        ),
                        const Divider(
                          height: 1,
                          color: CuramindColors.mistBlue,
                        ),
                        _checkTile(
                          value: _includeEmotionTags,
                          title: 'Emotions, triggers & skills',
                          subtitle: 'Frequency counts from DBT cards',
                          onChanged: (v) => setState(
                            () => _includeEmotionTags = v ?? true,
                          ),
                        ),
                        const Divider(
                          height: 1,
                          color: CuramindColors.mistBlue,
                        ),
                        _checkTile(
                          value: _includeMedications,
                          title: 'Medication profile',
                          subtitle:
                              'Active prescriptions and period adherence totals',
                          onChanged: (v) => setState(
                            () => _includeMedications = v ?? true,
                          ),
                        ),
                        const Divider(
                          height: 1,
                          color: CuramindColors.mistBlue,
                        ),
                        _checkTile(
                          value: _includeAdherenceChart,
                          title: 'Adherence chart & daily log',
                          subtitle: 'Daily adherence %, taken / missed doses',
                          onChanged: (v) => setState(
                            () => _includeAdherenceChart = v ?? true,
                          ),
                        ),
                        const Divider(
                          height: 1,
                          color: CuramindColors.mistBlue,
                        ),
                        _checkTile(
                          value: _includeDiaryLog,
                          title: 'Full DBT diary log',
                          subtitle:
                              'Mood, affect, urges, emotions, triggers, skills, notes',
                          onChanged: (v) =>
                              setState(() => _includeDiaryLog = v ?? true),
                        ),
                        const Divider(
                          height: 1,
                          color: CuramindColors.mistBlue,
                        ),
                        _checkTile(
                          value: _includeCopingLog,
                          title: 'Coping / CBT log',
                          subtitle:
                              'Situation, thoughts, behavior, outcome entries',
                          onChanged: (v) =>
                              setState(() => _includeCopingLog = v ?? true),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: GoogleFonts.outfit(color: CuramindColors.danger),
                    ),
                  ],
                  const SizedBox(height: 28),
                  CursorHoverRegion(
                    child: FilledButton.icon(
                      onPressed: _isGenerating ||
                              _selectedPatientId == null ||
                              _loadingMeta
                          ? null
                          : _downloadReport,
                      icon: _isGenerating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: CuramindColors.white,
                              ),
                            )
                          : const Icon(Icons.download_rounded),
                      label: Text(
                        _isGenerating
                            ? 'Generating PDF…'
                            : 'Download PDF',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: CuramindColors.sageDeep,
                        minimumSize: const Size.fromHeight(56),
                        textStyle: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Saves the clinical report PDF to your device Downloads folder.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: CuramindColors.inkMuted,
                      height: 1.4,
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
