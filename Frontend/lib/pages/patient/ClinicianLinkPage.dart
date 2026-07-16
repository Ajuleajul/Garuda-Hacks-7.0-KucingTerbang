import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/link_service.dart';
import '../../theme/curamind_theme.dart';

enum ClinicianLinkStatus { none, active }

class ClinicianLinkPage extends StatefulWidget {
  const ClinicianLinkPage({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  State<ClinicianLinkPage> createState() => _ClinicianLinkPageState();
}

class _ClinicianLinkPageState extends State<ClinicianLinkPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  ClinicianLinkStatus _status = ClinicianLinkStatus.none;
  PatientCareLink? _link;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final link = await LinkService.instance.getMyPatientLink();
    if (!mounted) return;
    setState(() {
      _link = link;
      _status =
          link == null ? ClinicianLinkStatus.none : ClinicianLinkStatus.active;
      _loading = false;
    });
  }

  Future<void> _submitCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final link =
          await LinkService.instance.joinWithCode(_codeController.text);
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _link = link;
        _status = ClinicianLinkStatus.active;
        _codeController.clear();
      });
      _toast('Linked with ${link.clinicianName}.');
    } on LinkFailure catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _toast(e.message, error: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _toast(e.toString(), error: true);
    }
  }

  Future<void> _unlink() async {
    setState(() => _submitting = true);
    await LinkService.instance.disconnect();
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _link = null;
      _status = ClinicianLinkStatus.none;
    });
    _toast('Disconnected from clinician.');
  }

  Future<void> _toggleMonitoring(bool on) async {
    setState(() {
      _link = _link?.copyWith(monitoringOn: on);
    });
    await LinkService.instance.setMonitoring(on);
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
    final content = _loading
        ? const Center(
            child: CircularProgressIndicator(color: CuramindColors.sageDeep),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!widget.embedded) ...[
                      Text(
                        'Clinician Link',
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
                      'Connect with your psychiatrist using their join code. '
                      'You can only be linked to one clinician at a time.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        height: 1.45,
                        color: CuramindColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _StatusCard(
                      status: _status,
                      monitoringOn: _link?.monitoringOn ?? false,
                    ),
                    const SizedBox(height: 18),
                    if (_status == ClinicianLinkStatus.none)
                      _InviteForm(
                        formKey: _formKey,
                        controller: _codeController,
                        submitting: _submitting,
                        onSubmit: _submitCode,
                      )
                    else if (_link != null)
                      _LinkedClinicianCard(
                        link: _link!,
                        submitting: _submitting,
                        onToggleMonitoring: _toggleMonitoring,
                        onUnlink: _unlink,
                      ),
                    const SizedBox(height: 22),
                    const _HowItWorks(),
                  ],
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

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.status,
    required this.monitoringOn,
  });

  final ClinicianLinkStatus status;
  final bool monitoringOn;

  @override
  Widget build(BuildContext context) {
    final (label, detail, color, icon) = switch (status) {
      ClinicianLinkStatus.none => (
          'Not linked',
          'Enter a join code from your psychiatrist to connect.',
          CuramindColors.inkMuted,
          Icons.link_off_rounded,
        ),
      ClinicianLinkStatus.active => (
          monitoringOn ? 'Linked · monitoring on' : 'Linked · monitoring paused',
          monitoringOn
              ? 'Your clinician can review shared diary & adherence.'
              : 'You stay linked, but sharing is paused.',
          CuramindColors.sageDeep,
          Icons.verified_outlined,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CuramindColors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CuramindColors.mistBlue),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: CuramindColors.mistBlue,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: CuramindColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    height: 1.4,
                    color: CuramindColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteForm extends StatelessWidget {
  const _InviteForm({
    required this.formKey,
    required this.controller,
    required this.submitting,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CuramindColors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CuramindColors.mistBlue),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter join code',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CuramindColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ask your psychiatrist for a Curamind group join code.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: CuramindColors.inkMuted,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onSubmit(),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
                LengthLimitingTextInputFormatter(16),
              ],
              decoration: const InputDecoration(
                labelText: 'Join code',
                hintText: 'e.g. CURA-7K2M',
              ),
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.length < 4) return 'Enter a valid join code';
                return null;
              },
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: submitting ? null : onSubmit,
              child: submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: CuramindColors.white,
                      ),
                    )
                  : const Text('Join care group'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkedClinicianCard extends StatelessWidget {
  const _LinkedClinicianCard({
    required this.link,
    required this.submitting,
    required this.onToggleMonitoring,
    required this.onUnlink,
  });

  final PatientCareLink link;
  final bool submitting;
  final ValueChanged<bool> onToggleMonitoring;
  final VoidCallback onUnlink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CuramindColors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CuramindColors.mistBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Linked clinician',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CuramindColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CuramindColors.sageSoft,
                  border: Border.all(color: CuramindColors.sage),
                ),
                child: const Icon(
                  Icons.medical_services_outlined,
                  color: CuramindColors.sageDeep,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      link.clinicianName,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CuramindColors.ink,
                      ),
                    ),
                    if (link.clinicianEmail.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        link.clinicianEmail,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: CuramindColors.inkMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${link.groupName} · ${link.groupCode}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CuramindColors.ocean,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: CuramindColors.mistBlue.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Remote monitoring',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: CuramindColors.ink,
                ),
              ),
              subtitle: Text(
                link.monitoringOn
                    ? 'Provider can view shared diary & adherence'
                    : 'Sharing paused on your side',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: CuramindColors.inkMuted,
                ),
              ),
              value: link.monitoringOn,
              activeThumbColor: CuramindColors.sageDeep,
              onChanged: onToggleMonitoring,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: submitting ? null : onUnlink,
            style: OutlinedButton.styleFrom(
              foregroundColor: CuramindColors.ocean,
              side: const BorderSide(color: CuramindColors.slate),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('1', 'Your psychiatrist creates a join code for a care group'),
      ('2', 'Enter that code here to link (one clinician only)'),
      ('3', 'Toggle monitoring anytime; disconnect to leave the group'),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CuramindColors.mistBlue.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CuramindColors.slate.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How linking works',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: CuramindColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          ...steps.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: CuramindColors.sageDeep,
                    ),
                    child: Text(
                      s.$1,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: CuramindColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.$2,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        height: 1.4,
                        color: CuramindColors.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
