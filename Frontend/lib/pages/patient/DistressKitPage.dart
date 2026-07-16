import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/curamind_theme.dart';
import 'DistressCrisisSOSPage.dart';

class DistressKitPage extends StatefulWidget {
  const DistressKitPage({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  State<DistressKitPage> createState() => _DistressKitPageState();
}

class _DistressKitPageState extends State<DistressKitPage>
    with TickerProviderStateMixin {
  int _section = 0;

  late final TabController _tabController;
  late final AnimationController _breathController;
  late final Animation<double> _breathScale;

  bool _breathing = false;
  String _breathPhase = 'Ready';

  int _groundStep = 0;
  final Set<int> _groundChecked = {};

  final _warningSigns = TextEditingController();
  final _internalCoping = TextEditingController();
  final _socialDistraction = TextEditingController();
  final _askForHelp = TextEditingController();
  final _professionals = TextEditingController();
  final _saferEnvironment = TextEditingController();
  final _reasonsForLiving = TextEditingController();

  final List<_KitItem> _kitItems = [
    _KitItem(label: 'Ice pack or cold water on wrists', done: false),
    _KitItem(label: 'Soft grounding object (stone / cloth)', done: false),
    _KitItem(label: 'Calming playlist or white noise', done: false),
    _KitItem(label: 'Written coping card from last session', done: false),
    _KitItem(label: 'Photo or note of a safe person', done: false),
  ];
  final _kitAddController = TextEditingController();

  static const _groundingSteps = [
    _GroundStep(
      title: '5 things you can see',
      prompt: 'Name five things around you — colors, shapes, light.',
      count: 5,
    ),
    _GroundStep(
      title: '4 things you can touch',
      prompt: 'Notice texture, temperature, pressure on your skin.',
      count: 4,
    ),
    _GroundStep(
      title: '3 things you can hear',
      prompt: 'Listen for near and far sounds, even quiet ones.',
      count: 3,
    ),
    _GroundStep(
      title: '2 things you can smell',
      prompt: 'Find a scent nearby, or recall a calming smell.',
      count: 2,
    ),
    _GroundStep(
      title: '1 thing you can taste',
      prompt: 'Notice taste in your mouth, or sip water slowly.',
      count: 1,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _section = _tabController.index);
      }
    });

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _breathScale = Tween<double>(begin: 0.72, end: 1.08).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
    _breathController.addStatusListener(_onBreathStatus);

    _warningSigns.text = 'Racing thoughts, tight chest, urge to isolate';
    _internalCoping.text = 'Box breathing, paced walking, cold water';
    _socialDistraction.text = 'Sit in a cafe, call a friend, pet the dog';
    _askForHelp.text = 'Name — phone number';
    _professionals.text = 'Clinic / crisis line';
    _saferEnvironment.text = 'Remove sharp objects, stay with someone';
    _reasonsForLiving.text = 'People I care about, goals I still want';
  }

  void _onBreathStatus(AnimationStatus status) {
    if (!_breathing) return;
    if (status == AnimationStatus.completed) {
      setState(() => _breathPhase = 'Exhale');
      _breathController.reverse();
    } else if (status == AnimationStatus.dismissed) {
      setState(() => _breathPhase = 'Inhale');
      _breathController.forward();
    }
  }

  void _toggleBreathing() {
    if (_breathing) {
      _breathController.stop();
      setState(() {
        _breathing = false;
        _breathPhase = 'Ready';
      });
      return;
    }
    setState(() {
      _breathing = true;
      _breathPhase = 'Inhale';
    });
    _breathController.forward(from: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _breathController
      ..removeStatusListener(_onBreathStatus)
      ..dispose();
    _warningSigns.dispose();
    _internalCoping.dispose();
    _socialDistraction.dispose();
    _askForHelp.dispose();
    _professionals.dispose();
    _saferEnvironment.dispose();
    _reasonsForLiving.dispose();
    _kitAddController.dispose();
    super.dispose();
  }

  void _addKitItem() {
    final text = _kitAddController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _kitItems.add(_KitItem(label: text, done: false));
      _kitAddController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(8, widget.embedded ? 4 : 8, 16, 0),
          child: Row(
            children: [
              if (!widget.embedded)
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: CuramindColors.ink,
                )
              else
                const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Distress Kit',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fraunces(
                    fontSize: widget.embedded ? 24 : 28,
                    fontWeight: FontWeight.w600,
                    color: CuramindColors.ink,
                  ),
                ),
              ),
              SizedBox(width: widget.embedded ? 12 : 48),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
          child: Text(
            'Calm tools for intense moments — breathing, grounding, and your safety plan.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              height: 1.4,
              color: CuramindColors.inkMuted,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _SectionChips(
            index: _section,
            onChanged: (i) {
              setState(() => _section = i);
              _tabController.animateTo(i);
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _BreathingTab(
                breathScale: _breathScale,
                phase: _breathPhase,
                breathing: _breathing,
                onToggle: _toggleBreathing,
              ),
              _GroundingTab(
                steps: _groundingSteps,
                stepIndex: _groundStep,
                checked: _groundChecked,
                onStepChanged: (i) => setState(() => _groundStep = i),
                onToggleCheck: (key) {
                  setState(() {
                    if (_groundChecked.contains(key)) {
                      _groundChecked.remove(key);
                    } else {
                      _groundChecked.add(key);
                    }
                  });
                },
              ),
              _SafetyPlanTab(
                warningSigns: _warningSigns,
                internalCoping: _internalCoping,
                socialDistraction: _socialDistraction,
                askForHelp: _askForHelp,
                professionals: _professionals,
                saferEnvironment: _saferEnvironment,
                reasonsForLiving: _reasonsForLiving,
                onOpenSos: () {
                  DistressCrisisSOSPage.open(context);
                },
              ),
              _KitAndSosTab(
                kitItems: _kitItems,
                addController: _kitAddController,
                onAdd: _addKitItem,
                onToggleKit: (i) {
                  setState(() {
                    _kitItems[i] =
                        _kitItems[i].copyWith(done: !_kitItems[i].done);
                  });
                },
                onRemoveKit: (i) => setState(() => _kitItems.removeAt(i)),
                onOpenCrisisMode: () => DistressCrisisSOSPage.open(context),
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _Atmosphere(),
          SafeArea(child: body),
        ],
      ),
    );
  }
}

class _SectionChips extends StatelessWidget {
  const _SectionChips({
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  static const _labels = ['Breathe', 'Ground', 'Safety', 'Kit & SOS'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CuramindColors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CuramindColors.mistBlue),
      ),
      child: Row(
        children: List.generate(_labels.length, (i) {
          final selected = index == i;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: selected ? CuramindColors.sageDeep : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(11),
                  onTap: () => onChanged(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      _labels[i],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? CuramindColors.white
                            : CuramindColors.inkMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _BreathingTab extends StatelessWidget {
  const _BreathingTab({
    required this.breathScale,
    required this.phase,
    required this.breathing,
    required this.onToggle,
  });

  final Animation<double> breathScale;
  final String phase;
  final bool breathing;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(
        children: [
          Text(
            'Slow-paced breathing',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CuramindColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Follow the circle. Inhale as it grows, exhale as it softens.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: CuramindColors.inkMuted,
            ),
          ),
          const SizedBox(height: 36),
          SizedBox(
            height: 260,
            child: Center(
              child: AnimatedBuilder(
                animation: breathScale,
                builder: (context, child) {
                  return Transform.scale(
                    scale: breathScale.value,
                    child: child,
                  );
                },
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        CuramindColors.mistBlue,
                        CuramindColors.sageSoft.withValues(alpha: 0.85),
                        CuramindColors.slate.withValues(alpha: 0.35),
                      ],
                      stops: const [0.2, 0.65, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: CuramindColors.slate.withValues(alpha: 0.18),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      phase,
                      style: GoogleFonts.fraunces(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: CuramindColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: onToggle,
            icon: Icon(
              breathing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
            label: Text(breathing ? 'Pause' : 'Start breathing'),
          ),
          const SizedBox(height: 16),
          Text(
            'Tip: aim for about 4 seconds in, 4 seconds out. Stop anytime.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: CuramindColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroundingTab extends StatelessWidget {
  const _GroundingTab({
    required this.steps,
    required this.stepIndex,
    required this.checked,
    required this.onStepChanged,
    required this.onToggleCheck,
  });

  final List<_GroundStep> steps;
  final int stepIndex;
  final Set<int> checked;
  final ValueChanged<int> onStepChanged;
  final ValueChanged<int> onToggleCheck;

  @override
  Widget build(BuildContext context) {
    final step = steps[stepIndex];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '5-4-3-2-1 grounding',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CuramindColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bring attention back to the present, one sense at a time.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: CuramindColors.inkMuted,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: List.generate(steps.length, (i) {
              final active = i == stepIndex;
              final done = List.generate(steps[i].count, (j) => i * 10 + j)
                  .every(checked.contains);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < steps.length - 1 ? 6 : 0),
                  child: GestureDetector(
                    onTap: () => onStepChanged(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 8,
                      decoration: BoxDecoration(
                        color: done
                            ? CuramindColors.sage
                            : active
                                ? CuramindColors.slate
                                : CuramindColors.mistBlue,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: CuramindColors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CuramindColors.mistBlue),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step ${stepIndex + 1} of ${steps.length}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CuramindColors.ocean,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  step.title,
                  style: GoogleFonts.fraunces(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: CuramindColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  step.prompt,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    height: 1.45,
                    color: CuramindColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(step.count, (j) {
                  final key = stepIndex * 10 + j;
                  final isOn = checked.contains(key);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onToggleCheck(key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isOn
                                ? CuramindColors.sageSoft.withValues(alpha: 0.7)
                                : CuramindColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isOn
                                  ? CuramindColors.sage
                                  : CuramindColors.mistBlue,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isOn
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                color: isOn
                                    ? CuramindColors.sageDeep
                                    : CuramindColors.inkMuted,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Item ${j + 1}',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w500,
                                  color: CuramindColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: stepIndex == 0
                      ? null
                      : () => onStepChanged(stepIndex - 1),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CuramindColors.ocean,
                    side: const BorderSide(color: CuramindColors.slate),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: stepIndex >= steps.length - 1
                      ? null
                      : () => onStepChanged(stepIndex + 1),
                  child: const Text('Next sense'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SafetyPlanTab extends StatelessWidget {
  const _SafetyPlanTab({
    required this.warningSigns,
    required this.internalCoping,
    required this.socialDistraction,
    required this.askForHelp,
    required this.professionals,
    required this.saferEnvironment,
    required this.reasonsForLiving,
    required this.onOpenSos,
  });

  final TextEditingController warningSigns;
  final TextEditingController internalCoping;
  final TextEditingController socialDistraction;
  final TextEditingController askForHelp;
  final TextEditingController professionals;
  final TextEditingController saferEnvironment;
  final TextEditingController reasonsForLiving;
  final VoidCallback onOpenSos;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Safety Planning Intervention',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CuramindColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Work through each step when risk rises. Edit freely — this stays on your device for now.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              height: 1.4,
              color: CuramindColors.inkMuted,
            ),
          ),
          const SizedBox(height: 14),
          _SpiStep(step: 1, title: 'Warning signs', controller: warningSigns),
          _SpiStep(
            step: 2,
            title: 'Internal coping',
            controller: internalCoping,
          ),
          _SpiStep(
            step: 3,
            title: 'People & places for distraction',
            controller: socialDistraction,
          ),
          _SpiStep(
            step: 4,
            title: 'People to ask for help',
            controller: askForHelp,
          ),
          _SpiStep(
            step: 5,
            title: 'Professionals & agencies',
            controller: professionals,
          ),
          _SpiStep(
            step: 6,
            title: 'Make the environment safer',
            controller: saferEnvironment,
          ),
          _SpiStep(
            step: 7,
            title: 'Reasons for living',
            controller: reasonsForLiving,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onOpenSos,
            icon: const Icon(Icons.sos_outlined),
            label: const Text('Open crisis resources'),
            style: OutlinedButton.styleFrom(
              foregroundColor: CuramindColors.ocean,
              side: const BorderSide(color: CuramindColors.slate),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpiStep extends StatelessWidget {
  const _SpiStep({
    required this.step,
    required this.title,
    required this.controller,
  });

  final int step;
  final String title;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: CuramindColors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CuramindColors.mistBlue),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step $step',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: CuramindColors.slate,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: CuramindColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 3,
              minLines: 2,
              decoration: const InputDecoration(
                hintText: 'Write your plan here…',
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KitAndSosTab extends StatelessWidget {
  const _KitAndSosTab({
    required this.kitItems,
    required this.addController,
    required this.onAdd,
    required this.onToggleKit,
    required this.onRemoveKit,
    required this.onOpenCrisisMode,
  });

  final List<_KitItem> kitItems;
  final TextEditingController addController;
  final VoidCallback onAdd;
  final ValueChanged<int> onToggleKit;
  final ValueChanged<int> onRemoveKit;
  final VoidCallback onOpenCrisisMode;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Personal distress kit',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CuramindColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check what you have nearby when distress spikes.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: CuramindColors.inkMuted,
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(kitItems.length, (i) {
            final item = kitItems[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: CuramindColors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CuramindColors.mistBlue),
                ),
                child: ListTile(
                  leading: IconButton(
                    onPressed: () => onToggleKit(i),
                    icon: Icon(
                      item.done
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      color: item.done
                          ? CuramindColors.sageDeep
                          : CuramindColors.inkMuted,
                    ),
                  ),
                  title: Text(
                    item.label,
                    style: GoogleFonts.outfit(
                      color: CuramindColors.ink,
                      decoration:
                          item.done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  trailing: IconButton(
                    onPressed: () => onRemoveKit(i),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: CuramindColors.inkMuted,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: addController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onAdd(),
                  decoration: const InputDecoration(
                    labelText: 'Add kit item',
                    hintText: 'e.g. peppermint oil',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onAdd,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(52, 52),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: CuramindColors.mistBlue.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: CuramindColors.slate.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crisis resources',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: CuramindColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Curamind is not emergency care. If distress is extreme, open calm crisis mode first — it will not dial for you.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    height: 1.45,
                    color: CuramindColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onOpenCrisisMode,
                  icon: const Icon(Icons.sos_outlined),
                  label: const Text('Open crisis mode'),
                  style: FilledButton.styleFrom(
                    backgroundColor: CuramindColors.ocean,
                    foregroundColor: CuramindColors.white,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
                const SizedBox(height: 14),
                const _CrisisRow(
                  title: 'Local emergency',
                  detail: 'Call your country emergency number',
                  icon: Icons.local_hospital_outlined,
                ),
                const SizedBox(height: 8),
                const _CrisisRow(
                  title: 'Crisis hotline',
                  detail: 'Use your national suicide prevention line',
                  icon: Icons.phone_in_talk_outlined,
                ),
                const SizedBox(height: 8),
                const _CrisisRow(
                  title: 'Trusted clinician',
                  detail: 'Reach your linked psychiatrist / clinic',
                  icon: Icons.medical_services_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CrisisRow extends StatelessWidget {
  const _CrisisRow({
    required this.title,
    required this.detail,
    required this.icon,
  });

  final String title;
  final String detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CuramindColors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: CuramindColors.ocean),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    color: CuramindColors.ink,
                  ),
                ),
                Text(
                  detail,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: CuramindColors.inkMuted,
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

class _Atmosphere extends StatelessWidget {
  const _Atmosphere();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE6EEF0),
            Color(0xFFE8F0EC),
            Color(0xFFDDE8EB),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CuramindColors.sage.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CuramindColors.slate.withValues(alpha: 0.10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroundStep {
  const _GroundStep({
    required this.title,
    required this.prompt,
    required this.count,
  });

  final String title;
  final String prompt;
  final int count;
}

class _KitItem {
  const _KitItem({required this.label, required this.done});

  final String label;
  final bool done;

  _KitItem copyWith({String? label, bool? done}) {
    return _KitItem(
      label: label ?? this.label,
      done: done ?? this.done,
    );
  }
}
