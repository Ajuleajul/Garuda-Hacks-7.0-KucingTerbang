import 'package:flutter/material.dart';

import '../pages/patient/AuthGate.dart';
import '../pages/patient/ClinicianLinkPage.dart';
import '../pages/patient/DistressKitPage.dart';
import '../pages/patient/EMADiaryPage.dart';
import '../pages/patient/HomePage.dart';
import '../pages/patient/MedicationViewPage.dart';
import '../pages/patient/PersonalDashboardPage.dart';
import '../pages/patient/ProfilePage.dart';
import '../theme/curamind_theme.dart';
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

  void _go(int i) => setState(() => _index = i);

  void _signOut() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AuthGate()),
      (_) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, PatientShell.destinations.length - 1);
    _pages = [
      PatientHomePage(
        displayName: widget.displayName,
        onNavigate: _go,
      ),
      const EMADiaryPage(embedded: true),
      const MedicationViewPage(embedded: true),
      const DistressKitPage(embedded: true),
      const PersonalDashboardPage(embedded: true),
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
        onDestinationSelected: _go,
        userLabel: 'Patient',
      ),
      body: IndexedStack(index: _index, children: _pages),
    );
  }
}
