import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/api_config.dart';
import '../../services/link_service.dart';
import '../../theme/curamind_theme.dart';

class _ExpiryOption {
  const _ExpiryOption({required this.label, required this.minutes});
  final String label;
  /// Null = never expires.
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

/// Psychiatrist: create & manage join codes (1 group = 1 code).
class ClinicianJoinCodesPage extends StatefulWidget {
  const ClinicianJoinCodesPage({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  State<ClinicianJoinCodesPage> createState() => _ClinicianJoinCodesPageState();
}

class _ClinicianJoinCodesPageState extends State<ClinicianJoinCodesPage> {
  final _nameController = TextEditingController();
  List<JoinGroup> _groups = [];
  bool _loading = true;
  bool _creating = false;
  bool? _apiOnline;
  /// Default: 24 hours.
  int? _expiresInMinutes = 1440;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final online = await LinkService.instance.pingHealth();
    try {
      final groups = await LinkService.instance.listMyGroups();
      if (!mounted) return;
      setState(() {
        _apiOnline = online;
        _groups = groups;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _apiOnline = online;
        _loading = false;
      });
      _toast(e.toString(), error: true);
    }
  }

  Future<void> _create() async {
    setState(() => _creating = true);
    try {
      // require server so 2 emulators / 2 windows can share the code
      final result = await LinkService.instance.createGroup(
        name: _nameController.text,
        expiresInMinutes: _expiresInMinutes,
        allowOffline: false,
      );
      if (!mounted) return;
      _nameController.clear();
      setState(() {
        _groups = [
          result.group,
          ..._groups.where((g) => g.id != result.group.id),
        ];
        _creating = false;
        _apiOnline = true;
      });
      await Clipboard.setData(ClipboardData(text: result.group.code));
      _toast('Created ${result.group.code} — copied. Ready for other device.');
    } on LinkFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _apiOnline = false;
      });
      _toast(e.message, error: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      _toast(e.toString(), error: true);
    }
  }

  Future<void> _toggle(JoinGroup group) async {
    try {
      final updated =
          await LinkService.instance.setGroupActive(group.id, !group.isActive);
      if (!mounted) return;
      setState(() {
        _groups = _groups
            .map((g) => g.id == updated.id ? updated : g)
            .toList();
      });
    } on LinkFailure catch (e) {
      _toast(e.message, error: true);
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

  @override
  Widget build(BuildContext context) {
    final content = RefreshIndicator(
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
                    'Join codes',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fraunces(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: CuramindColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  'Each code is one care group. Patients on another device/window '
                  'enter the code to link. Backend must be online for that.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    height: 1.45,
                    color: CuramindColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 12),
                _ApiStatusBanner(online: _apiOnline),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CuramindColors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: CuramindColors.mistBlue),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Create join code',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          color: CuramindColors.ink,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _nameController,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _create(),
                        decoration: const InputDecoration(
                          labelText: 'Group name (optional)',
                          hintText: 'e.g. Morning clinic · DBT cohort',
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Code expires after',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
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
                            onSelected: (_) {
                              setState(() => _expiresInMinutes = opt.minutes);
                            },
                            selectedColor: CuramindColors.sageSoft,
                            labelStyle: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected
                                  ? CuramindColors.sageDeep
                                  : CuramindColors.inkMuted,
                            ),
                            side: BorderSide(
                              color: selected
                                  ? CuramindColors.sage
                                  : CuramindColors.mistBlue,
                            ),
                            backgroundColor: CuramindColors.mist,
                            showCheckmark: false,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _creating ? null : _create,
                        icon: _creating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: CuramindColors.white,
                                ),
                              )
                            : const Icon(Icons.qr_code_2_outlined),
                        label: Text(
                          _creating ? 'Creating…' : 'Generate code',
                        ),
                      ),
                    ],
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
                      'No join codes yet. Generate one to start linking patients.',
                      style: GoogleFonts.outfit(
                        color: CuramindColors.inkMuted,
                      ),
                    ),
                  )
                else
                  ..._groups.map(
                    (g) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _GroupCard(
                        group: g,
                        onCopy: () async {
                          await Clipboard.setData(ClipboardData(text: g.code));
                          _toast('Copied ${g.code}');
                        },
                        onToggle: () => _toggle(g),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.embedded) {
      return ColoredBox(color: CuramindColors.mist, child: content);
    }
    return Scaffold(
      backgroundColor: CuramindColors.mist,
      body: SafeArea(child: content),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.onCopy,
    required this.onToggle,
  });

  final JoinGroup group;
  final VoidCallback onCopy;
  final VoidCallback onToggle;

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

  String get _expiryLabel {
    final at = group.expiresAt;
    if (at == null) return 'Never expires';
    if (group.isExpired) {
      return 'Expired ${_formatExpiry(at)}';
    }
    return 'Expires ${_formatExpiry(at)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CuramindColors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CuramindColors.mistBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
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
                      _statusLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${group.memberCount} patient${group.memberCount == 1 ? '' : 's'}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: CuramindColors.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: CuramindColors.mistBlue.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    group.code,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: group.isExpired
                          ? CuramindColors.inkMuted
                          : CuramindColors.ocean,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onCopy,
                  tooltip: 'Copy',
                  icon: const Icon(Icons.copy_rounded),
                  color: CuramindColors.ocean,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 16,
                color: group.isExpired
                    ? CuramindColors.danger
                    : CuramindColors.inkMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _expiryLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: group.isExpired
                        ? CuramindColors.danger
                        : CuramindColors.inkMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onToggle,
              icon: Icon(
                group.isActive
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
                size: 18,
              ),
              label: Text(
                group.isActive ? 'Deactivate code' : 'Reactivate code',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApiStatusBanner extends StatelessWidget {
  const _ApiStatusBanner({required this.online});

  final bool? online;

  @override
  Widget build(BuildContext context) {
    if (online == null) {
      return const SizedBox.shrink();
    }
    final ok = online!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ok
            ? CuramindColors.sageSoft.withValues(alpha: 0.7)
            : CuramindColors.danger.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ok ? CuramindColors.sage : CuramindColors.danger,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            size: 20,
            color: ok ? CuramindColors.sageDeep : CuramindColors.danger,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ok
                  ? 'Backend online · ${ApiConfig.baseUrl}\n'
                      'Codes sync across Android windows / devices.'
                  : 'Backend offline · ${ApiConfig.baseUrl}\n'
                      'Start API in Backend folder. Android emulator uses '
                      '10.0.2.2; physical phone needs API_BASE_URL=http://192.168.0.5:3000',
              style: GoogleFonts.outfit(
                fontSize: 12,
                height: 1.4,
                color: CuramindColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
