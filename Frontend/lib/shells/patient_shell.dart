import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../pages/patient/AuthPage.dart';
import '../pages/patient/ClinicianLinkPage.dart';
import '../pages/patient/ProfilePage.dart';
import '../theme/curamind_theme.dart';
import '../widgets/coming_soon_page.dart';
import '../widgets/curamind_app_header.dart';

class PatientShell extends StatefulWidget {
  const PatientShell({
    super.key,
    this.displayName = 'Patient',
    this.initialIndex = 0,
  });

  final String displayName;
  final int initialIndex;

  static const destinations = [
    NavDestination(label: 'Home', icon: Icons.home_outlined),
    NavDestination(label: 'Diary', icon: Icons.edit_note_outlined),
    NavDestination(label: 'Meds', icon: Icons.medication_outlined),
    NavDestination(label: 'Distress', icon: Icons.self_improvement_outlined),
    NavDestination(label: 'Dashboard', icon: Icons.show_chart_outlined),
    NavDestination(label: 'Link', icon: Icons.link_outlined),
    NavDestination(label: 'Profile', icon: Icons.person_outline_rounded),
  ];

  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  late int _index;
  late final List<Widget> _pages;

  void _signOut() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AuthPage()),
      (_) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, PatientShell.destinations.length - 1);
    _pages = [
      _PatientHomeBody(name: widget.displayName),
      const ComingSoonPage(
        title: 'DBT Diary',
        subtitle: 'Mood, triggers, urges, and coping journal coming next.',
        icon: Icons.edit_note_outlined,
      ),
      const ComingSoonPage(
        title: 'Medications',
        subtitle: 'Reminders and adherence logging coming next.',
        icon: Icons.medication_outlined,
      ),
      const ComingSoonPage(
        title: 'Distress Kit',
        subtitle: 'Breathing, grounding, and safety plan coming next.',
        icon: Icons.self_improvement_outlined,
      ),
      const ComingSoonPage(
        title: 'Personal Dashboard',
        subtitle: 'Dual mood × adherence chart coming next.',
        icon: Icons.show_chart_outlined,
      ),
      const ClinicianLinkPage(embedded: true),
      ProfilePage(
        name: widget.displayName,
        role: 'Patient',
        embedded: true,
        onSignedOut: _signOut,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CuramindColors.mist,
      appBar: CuramindAppHeader(
        destinations: PatientShell.destinations,
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        userLabel: 'Patient',
      ),
      body: IndexedStack(index: _index, children: _pages),
    );
  }
}

class _PatientHomeBody extends StatelessWidget {
  const _PatientHomeBody({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: CuramindColors.mist,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Hello, $name',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fraunces(
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    color: CuramindColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Use the header to open diary, medications, distress tools, and your dashboard.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    height: 1.45,
                    color: CuramindColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
