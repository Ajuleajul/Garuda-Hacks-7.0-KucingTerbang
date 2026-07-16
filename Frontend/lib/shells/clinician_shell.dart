import 'package:flutter/material.dart';

import '../pages/psychiatrist/ClinicianLoginPage.dart';
import '../pages/psychiatrist/HomePage.dart';
import '../pages/psychiatrist/PatientMonitoringDashboard.dart';
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
    NavDestination(label: 'Home', icon: Icons.home_outlined),
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

  void _go(int i) => setState(() => _index = i);

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
      ClinicianHomePage(
        displayName: widget.displayName,
        onNavigate: _go,
      ),
      const PatientMonitoringDashboard(),
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
        onDestinationSelected: _go,
        userLabel: 'Clinic',
      ),
      body: IndexedStack(index: _index, children: _pages),
    );
  }
}
