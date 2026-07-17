import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/link_service.dart';
import '../../theme/curamind_theme.dart';

String _initialOf(String name) {
  final t = name.trim();
  if (t.isEmpty) return '?';
  return t.substring(0, 1).toUpperCase();
}

class _ExpiryOption {
  const _ExpiryOption({required this.label, required this.minutes});
  final String label;
  final int? minutes;
}

const _expiryOptions = <_ExpiryOption>[
  _ExpiryOption(label: '15 min', minutes: 15),
  _ExpiryOption(label: '1 hour', minutes: 60),
  _ExpiryOption(label: '24 hours', minutes: 1440),
  _ExpiryOption(label: '7 days', minutes: 10080),
  _ExpiryOption(label: 'Never', minutes: null),
];

String _formatExpiry(DateTime at) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = at.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '${months[local.month - 1]} ${local.day} · $hh:$mm';
}

class ClinicianJoinCodesPage extends StatefulWidget {
  const ClinicianJoinCodesPage({
    super.key,
    this.embedded = false,
    this.active = true,
  });

  final bool embedded;
  final bool active;

  @override
  State<ClinicianJoinCodesPage> createState() => _ClinicianJoinCodesPageState();
}

class _ClinicianJoinCodesPageState extends State<ClinicianJoinCodesPage> {
  final GlobalKey<_GroupsListScreenState> _listKey =
      GlobalKey<_GroupsListScreenState>();

  @override
  void didUpdateWidget(covariant ClinicianJoinCodesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _listKey.currentState?.refreshFromParent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => _GroupsListScreen(
            key: _listKey,
            embedded: widget.embedded,
            active: widget.active,
          ),
        );
      },
    );

    if (widget.embedded) {
      return ColoredBox(color: CuramindColors.mist, child: nav);
    }
    return Scaffold(
      backgroundColor: CuramindColors.mist,
      body: SafeArea(child: nav),
    );
  }
}

class _GroupsListScreen extends StatefulWidget {
  const _GroupsListScreen({
    super.key,
    required this.embedded,
    required this.active,
  });

  final bool embedded;
  final bool active;

  @override
  State<_GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends State<_GroupsListScreen> {
  List<JoinGroup> _groups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.active) _refresh();
  }

  @override
  void didUpdateWidget(covariant _GroupsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _refresh();
    }
  }

  void refreshFromParent() {
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final groups = await LinkService.instance.listMyGroups();
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast(e.toString(), error: true);
    }
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            error ? CuramindColors.danger : CuramindColors.sageDeep,
        content: Text(
          msg,
          style: GoogleFonts.outfit(color: CuramindColors.white),
        ),
      ),
    );
  }

  Future<void> _createGroup() async {
    final name = await _promptName(title: 'New care group');
    if (name == null || !mounted) return;
    try {
      final result = await LinkService.instance.createGroup(
        name: name,
        expiresInMinutes: null,
        allowOffline: false,
      );
      if (!mounted) return;
      setState(() {
        _groups = [
          result.group,
          ..._groups.where((g) => g.id != result.group.id),
        ];
      });
      await Navigator.of(context).push<_GroupHubResult>(
        MaterialPageRoute(
          builder: (_) => _GroupHubScreen(group: result.group),
        ),
      );
      await _refresh();
    } on LinkFailure catch (e) {
      _toast(e.message, error: true);
    }
  }

  Future<String?> _promptName({
    required String title,
    String initial = '',
  }) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Group name',
            hintText: 'e.g. Morning clinic',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: CuramindColors.sageDeep,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty) return null;
    return result;
  }

  Future<void> _openHub(JoinGroup group) async {
    await Navigator.of(context).push<_GroupHubResult>(
      MaterialPageRoute(
        builder: (_) => _GroupHubScreen(group: group),
      ),
    );
    await _refresh();
  }

  Future<void> _rename(JoinGroup group) async {
    final name = await _promptName(
      title: 'Rename group',
      initial: group.name,
    );
    if (name == null || !mounted) return;
    try {
      final updated = await LinkService.instance.renameGroup(group.id, name);
      if (!mounted) return;
      setState(() {
        _groups = _groups.map((g) => g.id == updated.id ? updated : g).toList();
      });
      _toast('Renamed to ${updated.name}');
    } on LinkFailure catch (e) {
      _toast(e.message, error: true);
    }
  }

  Future<void> _delete(JoinGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete group?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '“${group.name}” will stop accepting new joins. '
          'Patients already linked stay connected.',
          style: GoogleFonts.outfit(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: CuramindColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await LinkService.instance.deleteGroup(group.id);
      if (!mounted) return;
      setState(() {
        _groups = _groups.where((g) => g.id != group.id).toList();
      });
      _toast('Deleted ${group.name}');
    } on LinkFailure catch (e) {
      _toast(e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: CuramindColors.sageDeep,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!widget.embedded) ...[
                  Text(
                    'Care groups',
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: CuramindColors.ink,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create a group, then generate an invite link for patients.',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: CuramindColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                FilledButton.icon(
                  onPressed: _createGroup,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New group'),
                  style: FilledButton.styleFrom(
                    backgroundColor: CuramindColors.sageDeep,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Your groups',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CuramindColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: CuramindColors.sageDeep,
                      ),
                    ),
                  )
                else if (_groups.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CuramindColors.mistBlue.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'No groups yet. Create one, then open Invite link to share a code.',
                      style: GoogleFonts.outfit(
                        color: CuramindColors.inkMuted,
                      ),
                    ),
                  )
                else
                  ..._groups.map(
                    (g) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _GroupListTile(
                        group: g,
                        onOpen: () => _openHub(g),
                        onRename: () => _rename(g),
                        onDelete: () => _delete(g),
                      ),
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

class _GroupHubResult {
  const _GroupHubResult();
}

class _GroupHubScreen extends StatefulWidget {
  const _GroupHubScreen({required this.group});

  final JoinGroup group;

  @override
  State<_GroupHubScreen> createState() => _GroupHubScreenState();
}

class _GroupHubScreenState extends State<_GroupHubScreen> {
  late JoinGroup _group;
  List<GroupMember> _members = const [];
  bool _loadingMembers = true;
  String? _membersError;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _loadingMembers = true;
      _membersError = null;
    });
    try {
      final members =
          await LinkService.instance.listGroupMembers(_group.id);
      if (!mounted) return;
      setState(() {
        _members = members;
        _loadingMembers = false;
        _group = _group.copyWith(memberCount: members.length);
      });
    } on LinkFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _membersError = e.message;
        _loadingMembers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _membersError = e.toString();
        _loadingMembers = false;
      });
    }
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            error ? CuramindColors.danger : CuramindColors.sageDeep,
        content: Text(
          msg,
          style: GoogleFonts.outfit(color: CuramindColors.white),
        ),
      ),
    );
  }

  String get _statusLabel {
    if (_group.isExpired) return 'Invite expired';
    if (!_group.isActive) return 'Invite inactive';
    return 'Invite active';
  }

  Color get _statusColor {
    if (_group.isExpired) return CuramindColors.danger;
    if (!_group.isActive) return CuramindColors.inkMuted;
    return CuramindColors.sageDeep;
  }

  Future<void> _toggle() async {
    try {
      final updated = await LinkService.instance.setGroupActive(
        _group.id,
        !_group.isActive,
      );
      if (!mounted) return;
      setState(() => _group = updated);
    } on LinkFailure catch (e) {
      _toast(e.message, error: true);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete group?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '“${_group.name}” will stop accepting new joins. '
          'Patients already linked stay connected.',
          style: GoogleFonts.outfit(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: CuramindColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await LinkService.instance.deleteGroup(_group.id);
      if (!mounted) return;
      Navigator.of(context).pop(const _GroupHubResult());
    } on LinkFailure catch (e) {
      _toast(e.message, error: true);
    }
  }

  Future<void> _openGenerator() async {
    final updated = await Navigator.of(context).push<JoinGroup>(
      MaterialPageRoute(
        builder: (_) => _LinkGeneratorScreen(group: _group),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _group = updated);
    }
  }

  void _openPatient(GroupMember member) async {
    final updated = await Navigator.of(context).push<GroupMember>(
      MaterialPageRoute(
        builder: (_) => _PatientDetailScreen(
          groupName: _group.name,
          member: member,
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() {
        _members = [
          for (final m in _members)
            if (m.patientId == updated.patientId) updated else m,
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CuramindColors.mist,
      appBar: AppBar(
        backgroundColor: CuramindColors.mist,
        elevation: 0,
        title: Text(
          _group.name,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: CuramindColors.ink,
          ),
        ),
        iconTheme: const IconThemeData(color: CuramindColors.ink),
        actions: [
          IconButton(
            onPressed: _loadMembers,
            tooltip: 'Refresh members',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMembers,
        color: CuramindColors.sageDeep,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CuramindColors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: CuramindColors.mistBlue),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Group',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: CuramindColors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _group.name,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: CuramindColors.ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoChip(
                              icon: Icons.circle,
                              label: _statusLabel,
                              color: _statusColor,
                            ),
                            _InfoChip(
                              icon: Icons.people_outline,
                              label:
                                  '${_members.isNotEmpty ? _members.length : _group.memberCount} member'
                                  '${(_members.isNotEmpty ? _members.length : _group.memberCount) == 1 ? '' : 's'}',
                              color: CuramindColors.ocean,
                            ),
                            if (_group.expiresAt != null)
                              _InfoChip(
                                icon: Icons.timer_outlined,
                                label: _group.isExpired
                                    ? 'Expired ${_formatExpiry(_group.expiresAt!)}'
                                    : 'Expires ${_formatExpiry(_group.expiresAt!)}',
                                color: _group.isExpired
                                    ? CuramindColors.danger
                                    : CuramindColors.inkMuted,
                              )
                            else
                              const _InfoChip(
                                icon: Icons.all_inclusive,
                                label: 'Invite never expires',
                                color: CuramindColors.inkMuted,
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Created ${_formatExpiry(_group.createdAt)}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: CuramindColors.inkMuted,
                          ),
                        ),
                        if (_group.code.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Current code · ${_group.code}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: CuramindColors.slate,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _openGenerator,
                    icon: const Icon(Icons.link_rounded),
                    label: const Text('Invite link'),
                    style: FilledButton.styleFrom(
                      backgroundColor: CuramindColors.ocean,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _toggle,
                    icon: Icon(
                      _group.isActive
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                    ),
                    label: Text(
                      _group.isActive
                          ? 'Deactivate invite'
                          : 'Reactivate invite',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Members',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: CuramindColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap a patient to see full profile details.',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: CuramindColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_loadingMembers)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: CuramindColors.sageDeep,
                        ),
                      ),
                    )
                  else if (_membersError != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: CuramindColors.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _membersError!,
                            style: GoogleFonts.outfit(
                              color: CuramindColors.danger,
                            ),
                          ),
                          TextButton(
                            onPressed: _loadMembers,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else if (_members.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CuramindColors.mistBlue.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'No patients have joined this group yet. Share an invite link to get started.',
                        style: GoogleFonts.outfit(
                          color: CuramindColors.inkMuted,
                          height: 1.4,
                        ),
                      ),
                    )
                  else
                    ..._members.map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _MemberTile(
                          member: m,
                          onTap: () => _openPatient(m),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _delete,
                    style: TextButton.styleFrom(
                      foregroundColor: CuramindColors.danger,
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete group'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.onTap});

  final GroupMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial = _initialOf(member.patientName);
    return Material(
      color: CuramindColors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CuramindColors.mistBlue),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: CuramindColors.sageSoft,
                child: Text(
                  initial,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    color: CuramindColors.sageDeep,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.patientName,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        color: CuramindColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (member.email != null && member.email!.isNotEmpty)
                          member.email!,
                        'Joined ${_formatExpiry(member.linkedAt)}',
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: CuramindColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _MiniStat(
                          label:
                              '${member.activeMedsCount} med${member.activeMedsCount == 1 ? '' : 's'}',
                        ),
                        if (member.monitoringOn)
                          _MiniStat(
                            label: '${member.diaryEntries} diary',
                          ),
                        _MiniStat(
                          label: member.monitoringOn
                              ? 'Monitoring on'
                              : 'Monitoring off',
                        ),
                      ],
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

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: CuramindColors.mistBlue.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: CuramindColors.ocean,
        ),
      ),
    );
  }
}

class _PatientDetailScreen extends StatefulWidget {
  const _PatientDetailScreen({
    required this.groupName,
    required this.member,
  });

  final String groupName;
  final GroupMember member;

  @override
  State<_PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<_PatientDetailScreen> {
  late GroupMember _member;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
  }

  Future<void> _setMonitoring(bool on) async {
    final previous = _member.monitoringOn;
    setState(() {
      _toggling = true;
      _member = _member.copyWith(monitoringOn: on);
    });
    try {
      await LinkService.instance.setMonitoring(
        on,
        patientId: _member.patientId,
      );
      if (!mounted) return;
      setState(() => _toggling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            on ? 'Monitoring turned on.' : 'Monitoring turned off.',
          ),
          backgroundColor: CuramindColors.sageDeep,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _member = _member.copyWith(monitoringOn: previous);
        _toggling = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: CuramindColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = _initialOf(_member.patientName);

    return Scaffold(
      backgroundColor: CuramindColors.mist,
      appBar: AppBar(
        backgroundColor: CuramindColors.mist,
        elevation: 0,
        title: Text(
          'Patient',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: CuramindColors.ink,
          ),
        ),
        iconTheme: const IconThemeData(color: CuramindColors.ink),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(_member),
        ),
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) Navigator.of(context).pop(_member);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: CuramindColors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: CuramindColors.mistBlue),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: CuramindColors.sageSoft,
                          child: Text(
                            initial,
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: CuramindColors.sageDeep,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _member.patientName,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: CuramindColors.ink,
                          ),
                        ),
                        if (_member.email != null &&
                            _member.email!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _member.email!,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: CuramindColors.ocean,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          'In group · ${widget.groupName}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: CuramindColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: CuramindColors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: CuramindColors.mistBlue),
                    ),
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Remote monitoring',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          color: CuramindColors.ink,
                        ),
                      ),
                      subtitle: Text(
                        _member.monitoringOn
                            ? 'Diary sharing is on for this patient'
                            : 'Diary sharing is paused',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: CuramindColors.inkMuted,
                        ),
                      ),
                      value: _member.monitoringOn,
                      activeThumbColor: CuramindColors.sageDeep,
                      onChanged: _toggling ? null : _setMonitoring,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DetailSection(
                    title: 'Link details',
                    children: [
                      _DetailRow(
                        label: 'Status',
                        value: _member.status,
                      ),
                      _DetailRow(
                        label: 'Monitoring',
                        value: _member.monitoringOn ? 'On' : 'Off',
                      ),
                      _DetailRow(
                        label: 'Joined',
                        value: _formatExpiry(_member.linkedAt),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _DetailSection(
                    title: 'Activity',
                    children: [
                      if (_member.monitoringOn)
                        _DetailRow(
                          label: 'Diary entries',
                          value: '${_member.diaryEntries}',
                        ),
                      _DetailRow(
                        label: 'Active prescriptions',
                        value: '${_member.activeMedsCount}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Prescriptions',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: CuramindColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_member.medications.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: CuramindColors.mistBlue.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'No active prescriptions for this patient.',
                        style: GoogleFonts.outfit(
                          color: CuramindColors.inkMuted,
                        ),
                      ),
                    )
                  else
                    ..._member.medications.map(
                      (med) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: CuramindColors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: CuramindColors.mistBlue),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                med.name,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  color: CuramindColors.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                med.dosageAndFreq,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: CuramindColors.slate,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Prescribed ${_formatExpiry(med.createdAt)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: CuramindColors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: CuramindColors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CuramindColors.mistBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: CuramindColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: CuramindColors.inkMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CuramindColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkGeneratorScreen extends StatefulWidget {
  const _LinkGeneratorScreen({required this.group});

  final JoinGroup group;

  @override
  State<_LinkGeneratorScreen> createState() => _LinkGeneratorScreenState();
}

class _LinkGeneratorScreenState extends State<_LinkGeneratorScreen> {
  late JoinGroup _group;
  int? _expiresInMinutes = 1440;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            error ? CuramindColors.danger : CuramindColors.sageDeep,
        content: Text(
          msg,
          style: GoogleFonts.outfit(color: CuramindColors.white),
        ),
      ),
    );
  }

  Future<void> _regenerate() async {
    setState(() => _busy = true);
    try {
      final updated = await LinkService.instance.regenerateGroupCode(
        groupId: _group.id,
        expiresInMinutes: _expiresInMinutes,
      );
      if (!mounted) return;
      setState(() {
        _group = updated;
        _busy = false;
      });
      await Clipboard.setData(ClipboardData(text: updated.code));
      _toast('Code ${updated.code} ready — copied');
    } on LinkFailure catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast(e.message, error: true);
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _group.code));
    _toast('Copied ${_group.code}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CuramindColors.mist,
      appBar: AppBar(
        backgroundColor: CuramindColors.mist,
        elevation: 0,
        title: Text(
          'Link generator',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: CuramindColors.ink,
          ),
        ),
        iconTheme: const IconThemeData(color: CuramindColors.ink),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(_group),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _group.name,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CuramindColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: CuramindColors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: CuramindColors.mistBlue),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Invite code',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: CuramindColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _group.code,
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                          color: _group.isExpired
                              ? CuramindColors.inkMuted
                              : CuramindColors.ocean,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _copy,
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Copy code'),
                      ),
                      if (_group.expiresAt != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _group.isExpired
                              ? 'Expired ${_formatExpiry(_group.expiresAt!)}'
                              : 'Expires ${_formatExpiry(_group.expiresAt!)}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: _group.isExpired
                                ? CuramindColors.danger
                                : CuramindColors.inkMuted,
                          ),
                        ),
                      ] else
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            'Never expires',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: CuramindColors.inkMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Expiry for new code',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CuramindColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _expiryOptions.map((opt) {
                    final selected = _expiresInMinutes == opt.minutes;
                    return ChoiceChip(
                      label: Text(opt.label),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _expiresInMinutes = opt.minutes),
                      selectedColor: CuramindColors.sageSoft,
                      labelStyle: GoogleFonts.outfit(
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        color: CuramindColors.ink,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _busy ? null : _regenerate,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: CuramindColors.white,
                          ),
                        )
                      : const Icon(Icons.autorenew_rounded),
                  label: Text(
                    _busy ? 'Generating…' : 'Generate new code',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: CuramindColors.sageDeep,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Generating a new code invalidates the previous one. '
                  'Patients already linked stay connected.',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    height: 1.4,
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

class _GroupListTile extends StatelessWidget {
  const _GroupListTile({
    required this.group,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
  });

  final JoinGroup group;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  String get _statusLabel {
    if (group.isExpired) return 'Expired';
    if (!group.isActive) return 'Inactive';
    return 'Active';
  }

  Color get _statusColor {
    if (group.isExpired) return CuramindColors.danger;
    if (!group.isActive) return CuramindColors.inkMuted;
    return CuramindColors.sageDeep;
  }

  @override
  Widget build(BuildContext context) {
    final names = group.membersPreview.map((m) => m.patientName).toList();
    final preview = names.isEmpty
        ? 'No members yet'
        : group.memberCount > names.length
            ? '${names.join(', ')} +${group.memberCount - names.length} more'
            : names.join(', ');

    return Material(
      color: CuramindColors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CuramindColors.mistBlue),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: CuramindColors.mistBlue.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.groups_2_outlined,
                  color: CuramindColors.ocean,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        color: CuramindColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_statusLabel · ${group.memberCount} patient'
                      '${group.memberCount == 1 ? '' : 's'}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: _statusColor,
                        fontWeight: FontWeight.w600,
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
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'rename') onRename();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'rename', child: Text('Rename')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
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
