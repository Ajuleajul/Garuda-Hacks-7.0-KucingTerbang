import 'package:flutter/material.dart';

import '../pages/patient/AuthGate.dart';
import '../pages/psychiatrist/HomePage.dart';
import '../pages/psychiatrist/MonitorClassesPage.dart';
import '../pages/psychiatrist/ProfilePage.dart';
import '../pages/psychiatrist/DualBivariateDashboard.dart';
import '../pages/psychiatrist/ClinicianJoinCodesPage.dart';
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
    NavDestination(label: 'Home', icon: Icons.home_outlined),
    NavDestination(label: 'Codes', icon: Icons.qr_code_2_outlined),
    NavDestination(label: 'Monitor', icon: Icons.monitor_heart_outlined),
    NavDestination(label: 'Dual Chart', icon: Icons.stacked_line_chart),
    NavDestination(label: 'Meds', icon: Icons.list_alt_outlined),
    NavDestination(label: 'Export', icon: Icons.picture_as_pdf_outlined),
    NavDestination(label: 'Profile', icon: Icons.person_outline_rounded),
  ];

  @override
  State<ClinicianShell> createState() => _ClinicianShellState();
}

class _ClinicianShellState extends State<ClinicianShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index =
        widget.initialIndex.clamp(0, ClinicianShell.destinations.length - 1);
  }

  void _go(int i) => setState(() => _index = i);

  void _signOut() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AuthGate()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mobile = curamindUseBottomNav(context);
    final pages = [
      ClinicianHomePage(
        displayName: widget.displayName,
        onNavigate: _go,
      ),
      const ClinicianJoinCodesPage(embedded: true),
      const MonitorClassesPage(embedded: true),
      const DualBivariateDashboard(embedded: true),
      MedicationManagementPage(embedded: true, active: _index == 4),
      const ExportClinicalReportPage(embedded: true),
      ProfilePage(
        name: widget.displayName,
        role: 'Psychiatrist',
        embedded: true,
        onSignedOut: _signOut,
      ),
    ];

    return Scaffold(
      backgroundColor: CuramindColors.mist,
      appBar: CuramindAppHeader(
        destinations: ClinicianShell.destinations,
        selectedIndex: _index,
        onDestinationSelected: _go,
        userLabel: 'Clinic',
        showNav: !mobile,
        profileIndex: ClinicianShell.destinations.length - 1,
      ),
      body: IndexedStack(index: _index, children: pages),
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
