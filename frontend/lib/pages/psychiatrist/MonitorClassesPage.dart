import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/link_service.dart';
import '../../theme/curamind_theme.dart';
import 'PatientMonitoringDashboard.dart';

class MonitorClassesPage extends StatefulWidget {
  const MonitorClassesPage({super.key, this.embedded = false});
  final bool embedded;

  @override
  State<MonitorClassesPage> createState() => _MonitorClassesPageState();
}

class _MonitorClassesPageState extends State<MonitorClassesPage> {
  final List<JoinGroup> _dummyGroups = [
    JoinGroup(
      id: '1',
      code: 'CURA-AXB9',
      name: 'Intensive Outpatient Cohort A',
      psychiatristId: 'psy-1',
      isActive: true,
      memberCount: 5,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    JoinGroup(
      id: '2',
      code: 'CURA-M7T2',
      name: 'DBT Skills Group (Tuesdays)',
      psychiatristId: 'psy-1',
      isActive: true,
      memberCount: 8,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    JoinGroup(
      id: '3',
      code: 'CURA-K9L4',
      name: 'Adolescent Support Group',
      psychiatristId: 'psy-1',
      isActive: true,
      memberCount: 4,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Classes',
            style: GoogleFonts.fraunces(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: CuramindColors.ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select a class to monitor your patients.',
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: CuramindColors.inkMuted,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: _dummyGroups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final group = _dummyGroups[index];
                return _ClassCard(group: group);
              },
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return ColoredBox(color: CuramindColors.mist, child: content);
    }
    return Scaffold(
      backgroundColor: CuramindColors.mist,
      appBar: AppBar(
        title: Text('Classes', style: GoogleFonts.outfit(color: CuramindColors.ink)),
        backgroundColor: CuramindColors.mist,
        elevation: 0,
        iconTheme: const IconThemeData(color: CuramindColors.ink),
      ),
      body: SafeArea(child: content),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final JoinGroup group;

  const _ClassCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CuramindColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const PatientMonitoringDashboard(embedded: false),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: CuramindColors.mistBlue),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: CuramindColors.slate.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: CuramindColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Code: ${group.code} • ${group.memberCount} Patients',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: CuramindColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: CuramindColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}
