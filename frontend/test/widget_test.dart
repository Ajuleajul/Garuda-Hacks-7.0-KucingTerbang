import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/pages/patient/ClinicianLinkPage.dart';
import 'package:frontend/pages/patient/HomePage.dart';
import 'package:frontend/pages/psychiatrist/ClinicianJoinCodesPage.dart';
import 'package:frontend/pages/psychiatrist/DualBivariateDashboard.dart';
import 'package:frontend/pages/psychiatrist/ExportClinicalReportPage.dart';
import 'package:frontend/pages/psychiatrist/HomePage.dart';
import 'package:frontend/pages/psychiatrist/MedicationManagementPage.dart';
import 'package:frontend/pages/psychiatrist/MonitorClassesPage.dart';
import 'package:frontend/theme/curamind_theme.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: buildCuramindTheme(),
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('Curamind theme renders brand shell', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCuramindTheme(),
        home: const Scaffold(body: Center(child: Text('Curamind'))),
      ),
    );
    expect(find.text('Curamind'), findsOneWidget);
  });

  testWidgets('Clinician pages mount idle without network', (tester) async {
    final pages = <Widget>[
      ClinicianHomePage(
        displayName: 'Dr Test',
        onNavigate: (_) {},
        active: false,
      ),
      const ClinicianJoinCodesPage(embedded: true, active: false),
      const MonitorClassesPage(embedded: true, active: false),
      const DualBivariateDashboard(embedded: true, active: false),
      const MedicationManagementPage(embedded: true, active: false),
      const ExportClinicalReportPage(embedded: true, active: false),
    ];

    for (final page in pages) {
      await tester.pumpWidget(_wrap(page));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Patient home and link mount idle without network', (
    tester,
  ) async {
    final pages = <Widget>[
      PatientHomePage(
        displayName: 'Patient Test',
        onNavigate: (_) {},
        active: false,
      ),
      const ClinicianLinkPage(embedded: true, active: false),
    ];

    for (final page in pages) {
      await tester.pumpWidget(_wrap(page));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });
}
