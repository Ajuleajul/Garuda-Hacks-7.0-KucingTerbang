import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/curamind_theme.dart';

enum ClinicianLinkStatus { none, pending, active }

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
  String? _clinicianName;
  String? _clinicianEmail;
  String? _linkedCode;
  bool _submitting = false;
  bool _monitoringOn = true;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    final code = _codeController.text.trim().toUpperCase();
    setState(() {
      _submitting = false;
      _linkedCode = code;
      _status = ClinicianLinkStatus.pending;
      _clinicianName = 'Dr. Mira Santoso';
      _clinicianEmail = 'mira.santoso@clinic.demo';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: CuramindColors.sageDeep,
        content: Text(
          'Invite sent. Waiting for clinician confirmation.',
          style: GoogleFonts.outfit(color: CuramindColors.white),
        ),
      ),
    );
  }

  Future<void> _simulateActivate() async {
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _status = ClinicianLinkStatus.active;
      _monitoringOn = true;
    });
  }

  void _unlink() {
    setState(() {
      _status = ClinicianLinkStatus.none;
      _clinicianName = null;
      _clinicianEmail = null;
      _linkedCode = null;
      _monitoringOn = false;
      _codeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
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
                'Connect with your psychiatrist for remote monitoring and shared care.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  height: 1.45,
                  color: CuramindColors.inkMuted,
                ),
              ),
              const SizedBox(height: 22),
              _StatusCard(status: _status, monitoringOn: _monitoringOn),
              const SizedBox(height: 18),
              if (_status == ClinicianLinkStatus.none) ...[
                _InviteForm(
                  formKey: _formKey,
                  controller: _codeController,
                  submitting: _submitting,
                  onSubmit: _submitCode,
                ),
              ] else ...[
                _LinkedClinicianCard(
                  status: _status,
                  name: _clinicianName ?? 'Clinician',
                  email: _clinicianEmail ?? '',
                  code: _linkedCode ?? '',
                  monitoringOn: _monitoringOn,
                  onToggleMonitoring: (v) => setState(() => _monitoringOn = v),
                  onActivateDemo: _status == ClinicianLinkStatus.pending
                      ? _simulateActivate
                      : null,
                  onUnlink: _unlink,
                  submitting: _submitting,
                ),
              ],
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
          'No clinician connection yet. Enter an invite code to start.',
          CuramindColors.inkMuted,
          Icons.link_off_rounded,
        ),
      ClinicianLinkStatus.pending => (
          'Pending confirmation',
          'Invite submitted. Your clinician still needs to accept.',
          CuramindColors.slate,
          Icons.hourglass_top_rounded,
        ),
      ClinicianLinkStatus.active => (
          monitoringOn ? 'Monitoring active' : 'Linked · monitoring paused',
          monitoringOn
              ? 'Remote monitoring is on. Diary and med logs can be shared.'
              : 'You are linked, but remote monitoring is currently off.',
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
            decoration: BoxDecoration(
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
              'Enter invite code',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CuramindColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ask your psychiatrist for a Curamind invite code.',
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
                LengthLimitingTextInputFormatter(12),
              ],
              decoration: const InputDecoration(
                labelText: 'Invite code',
                hintText: 'e.g. CURA-7K2M',
              ),
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.length < 4) {
                  return 'Enter a valid invite code';
                }
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
                  : const Text('Request link'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkedClinicianCard extends StatelessWidget {
  const _LinkedClinicianCard({
    required this.status,
    required this.name,
    required this.email,
    required this.code,
    required this.monitoringOn,
    required this.onToggleMonitoring,
    required this.onUnlink,
    required this.submitting,
    this.onActivateDemo,
  });

  final ClinicianLinkStatus status;
  final String name;
  final String email;
  final String code;
  final bool monitoringOn;
  final ValueChanged<bool> onToggleMonitoring;
  final VoidCallback onUnlink;
  final bool submitting;
  final VoidCallback? onActivateDemo;

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
                      name,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CuramindColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: CuramindColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Code · $code',
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
          if (status == ClinicianLinkStatus.active) ...[
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
                  monitoringOn
                      ? 'Provider can view shared diary & adherence'
                      : 'Sharing paused on your side',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: CuramindColors.inkMuted,
                  ),
                ),
                value: monitoringOn,
                activeThumbColor: CuramindColors.sageDeep,
                onChanged: onToggleMonitoring,
              ),
            ),
          ],
          if (onActivateDemo != null) ...[
            const SizedBox(height: 14),
            FilledButton(
              onPressed: submitting ? null : onActivateDemo,
              child: submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: CuramindColors.white,
                      ),
                    )
                  : const Text('Simulate clinician accept'),
            ),
          ],
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
      ('1', 'Get an invite code from your psychiatrist'),
      ('2', 'Submit the code here to request a link'),
      ('3', 'Once accepted, remote monitoring can stay active'),
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
          Text(
            'Demo only for now — invite codes are not validated against the server yet.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              height: 1.4,
              color: CuramindColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
