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
  List<JoinGroup> _groups = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final groups = await LinkService.instance.listMyGroups();
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = RefreshIndicator(
      onRefresh: _load,
      color: CuramindColors.sageDeep,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        children: [
          Text(
            'Emotion monitor',
            style: GoogleFonts.fraunces(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: CuramindColors.ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pick a care group to review mood, urges, and diary trends for linked patients.',
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: CuramindColors.inkMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: CircularProgressIndicator(color: CuramindColors.sageDeep),
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: CuramindColors.inkMuted),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          else if (_groups.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CuramindColors.mistBlue.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'No care groups yet. Create a group under Groups, invite patients, then monitor them here.',
                style: GoogleFonts.outfit(
                  color: CuramindColors.inkMuted,
                  height: 1.4,
                ),
              ),
            )
          else
            ..._groups.map(
              (g) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _GroupMonitorCard(group: g),
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
        title: Text(
          'Monitor',
          style: GoogleFonts.outfit(color: CuramindColors.ink),
        ),
        backgroundColor: CuramindColors.mist,
        elevation: 0,
        iconTheme: const IconThemeData(color: CuramindColors.ink),
      ),
      body: SafeArea(child: content),
    );
  }
}

class _GroupMonitorCard extends StatelessWidget {
  const _GroupMonitorCard({required this.group});

  final JoinGroup group;

  @override
  Widget build(BuildContext context) {
    final names = group.membersPreview.map((m) => m.patientName).toList();
    final preview = names.isEmpty
        ? 'No patients linked yet'
        : group.memberCount > names.length
            ? '${names.join(', ')} +${group.memberCount - names.length} more'
            : names.join(', ');

    return Material(
      color: CuramindColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PatientMonitoringDashboard(group: group),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(color: CuramindColors.mistBlue),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: CuramindColors.mistBlue.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.monitor_heart_outlined,
                  color: CuramindColors.ocean,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: CuramindColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${group.memberCount} patient'
                      '${group.memberCount == 1 ? '' : 's'}'
                      ' · ${group.isActive && !group.isExpired ? 'Invite active' : 'Invite closed'}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CuramindColors.sageDeep,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: CuramindColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: CuramindColors.inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
