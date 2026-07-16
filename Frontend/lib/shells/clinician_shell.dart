import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../pages/psychiatrist/ClinicianLoginPage.dart';
import '../pages/psychiatrist/ProfilePage.dart';
import '../theme/curamind_theme.dart';
import '../widgets/coming_soon_page.dart';
import '../widgets/curamind_app_header.dart';

class ClinicianShell extends StatefulWidget {
  const ClinicianShell({
    super.key,
    this.displayName = 'Clinician',
    this.initialIndex = 0,
  });

  final String displayName;
  final int initialIndex;

  static const destinations = [
    NavDestination(label: 'Monitor', icon: Icons.monitor_heart_outlined),
    NavDestination(label: 'Dual Chart', icon: Icons.stacked_line_chart),
    NavDestination(label: 'Prescribe', icon: Icons.medication_liquid_outlined),
    NavDestination(label: 'Meds', icon: Icons.list_alt_outlined),
    NavDestination(label: 'Export', icon: Icons.picture_as_pdf_outlined),
    NavDestination(label: 'Profile', icon: Icons.person_outline_rounded),
  ];

  @override
  State<ClinicianShell> createState() => _ClinicianShellState();
}

class _ClinicianShellState extends State<ClinicianShell> {
  late int _index;
  late final List<Widget> _pages;

  void _signOut() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const ClinicianLoginPage()),
      (_) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    _index =
        widget.initialIndex.clamp(0, ClinicianShell.destinations.length - 1);
    _pages = [
      _ClinicianHomeBody(name: widget.displayName),
      const ComingSoonPage(
        title: 'Dual-Correlation',
        subtitle: 'Mood × adherence detail chart for a selected patient.',
        icon: Icons.stacked_line_chart,
      ),
      const ComingSoonPage(
        title: 'Prescription Input',
        subtitle: 'Adjust dosages and manage active prescriptions.',
        icon: Icons.medication_liquid_outlined,
      ),
      const ComingSoonPage(
        title: 'Medication Management',
        subtitle: 'Digital medication log and session notes coming next.',
        icon: Icons.list_alt_outlined,
      ),
      const ComingSoonPage(
        title: 'Export Report',
        subtitle: 'Export longitudinal clinical data to PDF / EMR.',
        icon: Icons.picture_as_pdf_outlined,
      ),
      ProfilePage(
        name: widget.displayName,
        role: 'Psychiatrist',
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
        destinations: ClinicianShell.destinations,
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        userLabel: 'Clinic',
      ),
      body: IndexedStack(index: _index, children: _pages),
    );
  }
}

class _ClinicianHomeBody extends StatelessWidget {
  const _ClinicianHomeBody({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: CuramindColors.mist,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome, $name',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fraunces(
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    color: CuramindColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Patient monitoring lives here. Use the header to move between clinical tools.',
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
