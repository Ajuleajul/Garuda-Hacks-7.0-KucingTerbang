import 'package:flutter/material.dart';

import '../pages/patient/AuthGate.dart';
import '../pages/psychiatrist/PatientMonitoringDashboard.dart';
import '../pages/psychiatrist/ProfilePage.dart';
import '../pages/psychiatrist/DualBivariateDashboard.dart';
import '../pages/psychiatrist/MedicationPrescriptionInputPage.dart';
import '../pages/psychiatrist/MedicationManagementPage.dart';
import '../pages/psychiatrist/ExportClinicalReportPage.dart';
import '../theme/curamind_theme.dart';
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
    _index =
        widget.initialIndex.clamp(0, ClinicianShell.destinations.length - 1);
    _pages = [
      const PatientMonitoringDashboard(),
      const DualBivariateDashboard(),
      const MedicationPrescriptionInputPage(),
      const MedicationManagementPage(),
      const ExportClinicalReportPage(),
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
    final mobile = curamindUseBottomNav(context);

    return Scaffold(
      backgroundColor: CuramindColors.mist,
      appBar: CuramindAppHeader(
        destinations: ClinicianShell.destinations,
        selectedIndex: _index,
        onDestinationSelected: _go,
        userLabel: 'Clinic',
        showNav: !mobile,
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: mobile
          ? CuramindBottomNav(
              destinations: ClinicianShell.destinations,
              selectedIndex: _index,
              onDestinationSelected: _go,
            )
          : null,
    );
  }
}
