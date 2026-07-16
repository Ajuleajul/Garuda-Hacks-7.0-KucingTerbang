import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/diary_service.dart';
import '../../theme/curamind_theme.dart';

enum _HistoryFilter { all, dbtCard, coping }

class EMADiaryPage extends StatefulWidget {
  const EMADiaryPage({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  State<EMADiaryPage> createState() => _EMADiaryPageState();
}

class _EMADiaryPageState extends State<EMADiaryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  double _mood = 5;
  double _urgeNssi = 0;
  double _urgeSubstance = 0;
  double _affectIntensity = 5;

  final Set<String> _emotions = {};
  final Set<String> _triggers = {};
  final Set<String> _skills = {};

  final _notesController = TextEditingController();
  final _situationController = TextEditingController();
  final _thoughtsController = TextEditingController();
  final _behaviorController = TextEditingController();
  final _outcomeController = TextEditingController();

  bool _savingDbt = false;
  bool _savingCoping = false;
  bool _loadingHistory = true;
  final List<DiaryEntryModel> _history = [];
  _HistoryFilter _historyFilter = _HistoryFilter.all;

  static const _emotionOptions = [
    'Sad',
    'Anxious',
    'Angry',
    'Shame',
    'Lonely',
    'Empty',
    'Hopeful',
    'Calm',
  ];

  static const _triggerOptions = [
    'Conflict',
    'Rejection',
    'Work/school',
    'Sleep loss',
    'Reminder of trauma',
    'Isolation',
    'Substance cue',
    'Other',
  ];

  static const _skillOptions = [
    'Mindfulness',
    'Distress tolerance',
    'Emotion regulation',
    'Interpersonal effectiveness',
    'Opposite action',
    'TIPP / cold water',
    'PLEASE',
    'Self-soothe',
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _notesController.dispose();
    _situationController.dispose();
    _thoughtsController.dispose();
    _behaviorController.dispose();
    _outcomeController.dispose();
    super.dispose();
  }

  void _resetDbtForm() {
    setState(() {
      _mood = 5;
      _urgeNssi = 0;
      _urgeSubstance = 0;
      _affectIntensity = 5;
      _emotions.clear();
      _triggers.clear();
      _skills.clear();
      _notesController.clear();
    });
  }

  void _resetCopingForm() {
    setState(() {
      _situationController.clear();
      _thoughtsController.clear();
      _behaviorController.clear();
      _outcomeController.clear();
    });
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final entries = await DiaryService.instance.loadMyEntries();
      if (!mounted) return;
      setState(() {
        _history
          ..clear()
          ..addAll(entries);
        _loadingHistory = false;
      });
    } on DiaryFailure catch (e) {
      if (!mounted) return;
      setState(() => _loadingHistory = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: CuramindColors.danger,
          content: Text(
            e.message,
            style: GoogleFonts.outfit(color: CuramindColors.white),
          ),
        ),
      );
    }
  }

  Future<void> _saveDbtEntry() async {
    setState(() => _savingDbt = true);
    try {
      final entry = await DiaryService.instance.saveDbtCard(
        mood: _mood.round(),
        affectIntensity: _affectIntensity.round(),
        urgeNssi: _urgeNssi.round(),
        urgeSubstance: _urgeSubstance.round(),
        emotions: _emotions.toList(),
        triggers: _triggers.toList(),
        skills: _skills.toList(),
        notes: _notesController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _history.insert(0, entry);
        _savingDbt = false;
      });
      _resetDbtForm();
      _tabs.animateTo(2);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: CuramindColors.sageDeep,
          content: Text(
            'DBT card saved.',
            style: GoogleFonts.outfit(color: CuramindColors.white),
          ),
        ),
      );
    } on DiaryFailure catch (e) {
      if (!mounted) return;
      setState(() => _savingDbt = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: CuramindColors.danger,
          content: Text(
            e.message,
            style: GoogleFonts.outfit(color: CuramindColors.white),
          ),
        ),
      );
    }
  }

  Future<void> _saveCopingEntry() async {
    setState(() => _savingCoping = true);
    try {
      final entry = await DiaryService.instance.saveCoping(
        situation: _situationController.text.trim(),
        thoughts: _thoughtsController.text.trim(),
        behavior: _behaviorController.text.trim(),
        outcome: _outcomeController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _history.insert(0, entry);
        _savingCoping = false;
      });
      _resetCopingForm();
      _tabs.animateTo(2);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: CuramindColors.sageDeep,
          content: Text(
            'Coping entry saved.',
            style: GoogleFonts.outfit(color: CuramindColors.white),
          ),
        ),
      );
    } on DiaryFailure catch (e) {
      if (!mounted) return;
      setState(() => _savingCoping = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: CuramindColors.danger,
          content: Text(
            e.message,
            style: GoogleFonts.outfit(color: CuramindColors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Column(
            children: [
              if (!widget.embedded)
                Text(
                  'EMA Diary',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fraunces(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: CuramindColors.ink,
                  ),
                ),
              Text(
                'Track momentary mood, urges, DBT skills, and dialectical reflection.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  height: 1.4,
                  color: CuramindColors.inkMuted,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: CuramindColors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: CuramindColors.mistBlue),
                ),
                child: TabBar(
                  controller: _tabs,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: CuramindColors.sageDeep,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  labelColor: CuramindColors.white,
                  unselectedLabelColor: CuramindColors.inkMuted,
                  labelStyle: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(text: 'DBT Card'),
                    Tab(text: 'Coping'),
                    Tab(text: 'History'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _DbtCardTab(
                mood: _mood,
                affectIntensity: _affectIntensity,
                urgeNssi: _urgeNssi,
                urgeSubstance: _urgeSubstance,
                emotions: _emotions,
                triggers: _triggers,
                skills: _skills,
                notesController: _notesController,
                emotionOptions: _emotionOptions,
                triggerOptions: _triggerOptions,
                skillOptions: _skillOptions,
                onMood: (v) => setState(() => _mood = v),
                onAffect: (v) => setState(() => _affectIntensity = v),
                onUrgeNssi: (v) => setState(() => _urgeNssi = v),
                onUrgeSubstance: (v) => setState(() => _urgeSubstance = v),
                onToggleEmotion: (e) => setState(() {
                  _emotions.contains(e)
                      ? _emotions.remove(e)
                      : _emotions.add(e);
                }),
                onToggleTrigger: (t) => setState(() {
                  _triggers.contains(t)
                      ? _triggers.remove(t)
                      : _triggers.add(t);
                }),
                onToggleSkill: (s) => setState(() {
                  _skills.contains(s) ? _skills.remove(s) : _skills.add(s);
                }),
                saving: _savingDbt,
                onSave: _saveDbtEntry,
              ),
              _CopingTab(
                situationController: _situationController,
                thoughtsController: _thoughtsController,
                behaviorController: _behaviorController,
                outcomeController: _outcomeController,
                saving: _savingCoping,
                onSave: _saveCopingEntry,
              ),
              _HistoryTab(
                entries: _history,
                loading: _loadingHistory,
                filter: _historyFilter,
                onFilter: (f) => setState(() => _historyFilter = f),
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return ColoredBox(color: CuramindColors.mist, child: body);
    }

    return Scaffold(
      backgroundColor: CuramindColors.mist,
      body: SafeArea(child: body),
    );
  }
}

class _DbtCardTab extends StatelessWidget {
  const _DbtCardTab({
    required this.mood,
    required this.affectIntensity,
    required this.urgeNssi,
    required this.urgeSubstance,
    required this.emotions,
    required this.triggers,
    required this.skills,
    required this.notesController,
    required this.emotionOptions,
    required this.triggerOptions,
    required this.skillOptions,
    required this.onMood,
    required this.onAffect,
    required this.onUrgeNssi,
    required this.onUrgeSubstance,
    required this.onToggleEmotion,
    required this.onToggleTrigger,
    required this.onToggleSkill,
    required this.saving,
    required this.onSave,
  });

  final double mood;
  final double affectIntensity;
  final double urgeNssi;
  final double urgeSubstance;
  final Set<String> emotions;
  final Set<String> triggers;
  final Set<String> skills;
  final TextEditingController notesController;
  final List<String> emotionOptions;
  final List<String> triggerOptions;
  final List<String> skillOptions;
  final ValueChanged<double> onMood;
  final ValueChanged<double> onAffect;
  final ValueChanged<double> onUrgeNssi;
  final ValueChanged<double> onUrgeSubstance;
  final ValueChanged<String> onToggleEmotion;
  final ValueChanged<String> onToggleTrigger;
  final ValueChanged<String> onToggleSkill;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionCard(
                title: 'Momentary affect',
                child: Column(
                  children: [
                    _SliderRow(
                      label: 'Mood',
                      value: mood,
                      low: 'Very low',
                      high: 'Very high',
                      onChanged: onMood,
                    ),
                    const SizedBox(height: 8),
                    _SliderRow(
                      label: 'Emotion intensity',
                      value: affectIntensity,
                      low: 'Mild',
                      high: 'Overwhelming',
                      onChanged: onAffect,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Emotions present',
                child: _ChipWrap(
                  options: emotionOptions,
                  selected: emotions,
                  onToggle: onToggleEmotion,
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Behavioral urges',
                child: Column(
                  children: [
                    _SliderRow(
                      label: 'Self-harm urge (NSSI)',
                      value: urgeNssi,
                      low: 'None',
                      high: 'Severe',
                      onChanged: onUrgeNssi,
                    ),
                    const SizedBox(height: 8),
                    _SliderRow(
                      label: 'Substance urge',
                      value: urgeSubstance,
                      low: 'None',
                      high: 'Severe',
                      onChanged: onUrgeSubstance,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Triggers',
                child: _ChipWrap(
                  options: triggerOptions,
                  selected: triggers,
                  onToggle: onToggleTrigger,
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'DBT skills used',
                child: _ChipWrap(
                  options: skillOptions,
                  selected: skills,
                  onToggle: onToggleSkill,
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Short note',
                child: TextField(
                  controller: notesController,
                  maxLines: 3,
                  minLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Anything else about this moment…',
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: saving ? null : onSave,
                child: saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: CuramindColors.white,
                        ),
                      )
                    : const Text('Save DBT card'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CopingTab extends StatelessWidget {
  const _CopingTab({
    required this.situationController,
    required this.thoughtsController,
    required this.behaviorController,
    required this.outcomeController,
    required this.saving,
    required this.onSave,
  });

  final TextEditingController situationController;
  final TextEditingController thoughtsController;
  final TextEditingController behaviorController;
  final TextEditingController outcomeController;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Dialectical Coping Diary',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CuramindColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Reflect on both sides of the experience — what hurt, what helped, and what changed.',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  height: 1.4,
                  color: CuramindColors.inkMuted,
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Situation',
                child: TextField(
                  controller: situationController,
                  maxLines: 3,
                  minLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'What happened?',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Thoughts & emotions',
                child: TextField(
                  controller: thoughtsController,
                  maxLines: 3,
                  minLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'What went through your mind and body?',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Behavior / skill response',
                child: TextField(
                  controller: behaviorController,
                  maxLines: 3,
                  minLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'What did you do? Which skills did you try?',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Outcome & distress change',
                child: TextField(
                  controller: outcomeController,
                  maxLines: 3,
                  minLines: 2,
                  decoration: const InputDecoration(
                    hintText:
                        'Did distress drop? Any shift in depression / borderline symptoms?',
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: saving ? null : onSave,
                child: saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: CuramindColors.white,
                        ),
                      )
                    : const Text('Save coping entry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({
    required this.entries,
    required this.loading,
    required this.filter,
    required this.onFilter,
  });

  final List<DiaryEntryModel> entries;
  final bool loading;
  final _HistoryFilter filter;
  final ValueChanged<_HistoryFilter> onFilter;

  List<DiaryEntryModel> get _filtered {
    switch (filter) {
      case _HistoryFilter.all:
        return entries;
      case _HistoryFilter.dbtCard:
        return entries.where((e) => e.kind == DiaryEntryKind.dbtCard).toList();
      case _HistoryFilter.coping:
        return entries.where((e) => e.kind == DiaryEntryKind.coping).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _FilterChip(
                label: 'All',
                selected: filter == _HistoryFilter.all,
                onTap: () => onFilter(_HistoryFilter.all),
              ),
              _FilterChip(
                label: 'DBT Card',
                selected: filter == _HistoryFilter.dbtCard,
                onTap: () => onFilter(_HistoryFilter.dbtCard),
              ),
              _FilterChip(
                label: 'Coping',
                selected: filter == _HistoryFilter.coping,
                onTap: () => onFilter(_HistoryFilter.coping),
              ),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: CuramindColors.sageDeep,
                  ),
                )
              : list.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.menu_book_outlined,
                          size: 42,
                          color: CuramindColors.slate,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No entries yet',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: CuramindColors.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          filter == _HistoryFilter.all
                              ? 'Saved DBT cards and coping entries will appear here.'
                              : filter == _HistoryFilter.dbtCard
                                  ? 'No DBT cards in this filter yet.'
                                  : 'No coping entries in this filter yet.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: CuramindColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _HistoryCard(entry: list[i]),
                ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: CuramindColors.sageSoft,
      labelStyle: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? CuramindColors.sageDeep : CuramindColors.inkMuted,
      ),
      side: BorderSide(
        color: selected ? CuramindColors.sage : CuramindColors.mistBlue,
      ),
      backgroundColor: CuramindColors.mist,
      showCheckmark: false,
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry});

  final DiaryEntryModel entry;

  static const _months = [
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

  static const _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  String get _stamp {
    final d = entry.createdAt.toLocal();
    final wd = _weekdays[d.weekday - 1];
    final mo = _months[d.month - 1];
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    final ss = d.second.toString().padLeft(2, '0');
    return '$wd, $mo ${d.day}, ${d.year} · $hh:$mm:$ss';
  }

  bool get _isDbt => entry.kind == DiaryEntryKind.dbtCard;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CuramindColors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CuramindColors.mistBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isDbt
                      ? CuramindColors.sageSoft
                      : CuramindColors.mistBlue,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  _isDbt ? 'DBT Card' : 'Coping',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _isDbt
                        ? CuramindColors.sageDeep
                        : CuramindColors.ocean,
                  ),
                ),
              ),
              const Spacer(),
              if (_isDbt)
                Text(
                  'Mood ${entry.mood}/10',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    color: CuramindColors.ink,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 16,
                color: CuramindColors.ocean,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _stamp,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CuramindColors.ocean,
                  ),
                ),
              ),
            ],
          ),
          if (_isDbt) ...[
            const SizedBox(height: 10),
            Text(
              'Intensity ${entry.affectIntensity}/10 · NSSI urge ${entry.urgeNssi} · Substance urge ${entry.urgeSubstance}',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: CuramindColors.inkMuted,
              ),
            ),
            if (entry.emotions.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Emotions: ${entry.emotions.join(', ')}',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: CuramindColors.ink,
                ),
              ),
            ],
            if (entry.triggers.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Triggers: ${entry.triggers.join(', ')}',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: CuramindColors.ink,
                ),
              ),
            ],
            if (entry.skills.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Skills: ${entry.skills.join(', ')}',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: CuramindColors.ink,
                ),
              ),
            ],
            if (entry.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                entry.notes,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  height: 1.4,
                  color: CuramindColors.inkMuted,
                ),
              ),
            ],
          ] else ...[
            if (entry.situation.isNotEmpty) ...[
              const SizedBox(height: 10),
              _CopingLine(label: 'Situation', text: entry.situation),
            ],
            if (entry.thoughts.isNotEmpty) ...[
              const SizedBox(height: 8),
              _CopingLine(label: 'Thoughts', text: entry.thoughts),
            ],
            if (entry.behavior.isNotEmpty) ...[
              const SizedBox(height: 8),
              _CopingLine(label: 'Response', text: entry.behavior),
            ],
            if (entry.outcome.isNotEmpty) ...[
              const SizedBox(height: 8),
              _CopingLine(label: 'Outcome', text: entry.outcome),
            ],
          ],
        ],
      ),
    );
  }
}

class _CopingLine extends StatelessWidget {
  const _CopingLine({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: CuramindColors.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 13,
            height: 1.4,
            color: CuramindColors.inkMuted,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: CuramindColors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CuramindColors.mistBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: CuramindColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.low,
    required this.high,
    required this.onChanged,
  });

  final String label;
  final double value;
  final String low;
  final String high;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w500,
                  color: CuramindColors.ink,
                ),
              ),
            ),
            Text(
              value.round().toString(),
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                color: CuramindColors.ocean,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: CuramindColors.sage,
            inactiveTrackColor: CuramindColors.mistBlue,
            thumbColor: CuramindColors.sageDeep,
            overlayColor: CuramindColors.sage.withValues(alpha: 0.15),
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: onChanged,
          ),
        ),
        Row(
          children: [
            Text(
              low,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: CuramindColors.inkMuted,
              ),
            ),
            const Spacer(),
            Text(
              high,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: CuramindColors.inkMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final on = selected.contains(option);
        return FilterChip(
          label: Text(option),
          selected: on,
          onSelected: (_) => onToggle(option),
          selectedColor: CuramindColors.sageSoft,
          checkmarkColor: CuramindColors.sageDeep,
          labelStyle: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: on ? CuramindColors.sageDeep : CuramindColors.inkMuted,
          ),
          side: BorderSide(
            color: on ? CuramindColors.sage : CuramindColors.mistBlue,
          ),
          backgroundColor: CuramindColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }).toList(),
    );
  }
}
