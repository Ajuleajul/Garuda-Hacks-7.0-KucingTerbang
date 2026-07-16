import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/curamind_theme.dart';

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

  bool _saving = false;
  final List<_DiaryEntry> _history = [];

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

  void _resetForm() {
    setState(() {
      _mood = 5;
      _urgeNssi = 0;
      _urgeSubstance = 0;
      _affectIntensity = 5;
      _emotions.clear();
      _triggers.clear();
      _skills.clear();
      _notesController.clear();
      _situationController.clear();
      _thoughtsController.clear();
      _behaviorController.clear();
      _outcomeController.clear();
    });
  }

  Future<void> _saveEntry() async {
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final entry = _DiaryEntry(
      createdAt: DateTime.now(),
      mood: _mood.round(),
      affectIntensity: _affectIntensity.round(),
      urgeNssi: _urgeNssi.round(),
      urgeSubstance: _urgeSubstance.round(),
      emotions: _emotions.toList(),
      triggers: _triggers.toList(),
      skills: _skills.toList(),
      notes: _notesController.text.trim(),
      situation: _situationController.text.trim(),
      thoughts: _thoughtsController.text.trim(),
      behavior: _behaviorController.text.trim(),
      outcome: _outcomeController.text.trim(),
    );

    setState(() {
      _history.insert(0, entry);
      _saving = false;
    });
    _resetForm();
    _tabs.animateTo(2);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: CuramindColors.sageDeep,
        content: Text(
          'Diary entry saved (local demo).',
          style: GoogleFonts.outfit(color: CuramindColors.white),
        ),
      ),
    );
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
                  _emotions.contains(e) ? _emotions.remove(e) : _emotions.add(e);
                }),
                onToggleTrigger: (t) => setState(() {
                  _triggers.contains(t) ? _triggers.remove(t) : _triggers.add(t);
                }),
                onToggleSkill: (s) => setState(() {
                  _skills.contains(s) ? _skills.remove(s) : _skills.add(s);
                }),
                saving: _saving,
                onSave: _saveEntry,
              ),
              _CopingTab(
                situationController: _situationController,
                thoughtsController: _thoughtsController,
                behaviorController: _behaviorController,
                outcomeController: _outcomeController,
                saving: _saving,
                onSave: _saveEntry,
              ),
              _HistoryTab(entries: _history),
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
                    : const Text('Save diary entry'),
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
  const _HistoryTab({required this.entries});

  final List<_DiaryEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
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
                'Saved diary cards will appear here for today’s session.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: CuramindColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final e = entries[i];
        final time =
            '${e.createdAt.hour.toString().padLeft(2, '0')}:${e.createdAt.minute.toString().padLeft(2, '0')}';
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
                  Text(
                    time,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      color: CuramindColors.ocean,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Mood ${e.mood}/10',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      color: CuramindColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Urges · NSSI ${e.urgeNssi} · Substance ${e.urgeSubstance}',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: CuramindColors.inkMuted,
                ),
              ),
              if (e.emotions.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Emotions: ${e.emotions.join(', ')}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: CuramindColors.ink,
                  ),
                ),
              ],
              if (e.skills.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Skills: ${e.skills.join(', ')}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: CuramindColors.ink,
                  ),
                ),
              ],
              if (e.notes.isNotEmpty || e.situation.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  e.notes.isNotEmpty ? e.notes : e.situation,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    height: 1.4,
                    color: CuramindColors.inkMuted,
                  ),
                ),
              ],
            ],
          ),
        );
      },
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

class _DiaryEntry {
  const _DiaryEntry({
    required this.createdAt,
    required this.mood,
    required this.affectIntensity,
    required this.urgeNssi,
    required this.urgeSubstance,
    required this.emotions,
    required this.triggers,
    required this.skills,
    required this.notes,
    required this.situation,
    required this.thoughts,
    required this.behavior,
    required this.outcome,
  });

  final DateTime createdAt;
  final int mood;
  final int affectIntensity;
  final int urgeNssi;
  final int urgeSubstance;
  final List<String> emotions;
  final List<String> triggers;
  final List<String> skills;
  final String notes;
  final String situation;
  final String thoughts;
  final String behavior;
  final String outcome;
}
