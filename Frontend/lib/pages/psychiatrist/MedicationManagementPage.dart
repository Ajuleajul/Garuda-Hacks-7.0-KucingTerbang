import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../animated_cursor.dart';
import '../../services/medication_service.dart';
import '../../theme/curamind_theme.dart';

class MedicationManagementPage extends StatefulWidget {
  const MedicationManagementPage({
    super.key,
    this.embedded = false,
    this.active = true,
  });

  final bool embedded;
  final bool active;

  @override
  State<MedicationManagementPage> createState() =>
      _MedicationManagementPageState();
}

class _MedicationManagementPageState extends State<MedicationManagementPage> {
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  String? _selectedPatientId;
  List<MedicationModel> _meds = const [];
  List<LinkedPatient> _patients = const [];

  @override
  void initState() {
    super.initState();
    if (widget.active) _load();
  }

  @override
  void didUpdateWidget(covariant MedicationManagementPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        MedicationService.instance.loadClinicianMeds(),
        MedicationService.instance.loadLinkedPatients(),
      ]);
      if (!mounted) return;
      setState(() {
        _meds = results[0] as List<MedicationModel>;
        _patients = results[1] as List<LinkedPatient>;
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

  String? _groupNameFor(String patientId) {
    for (final p in _patients) {
      if (p.patientId == patientId) {
        final name = p.groupName?.trim();
        if (name != null && name.isNotEmpty) return name;
      }
    }
    return null;
  }

  List<MedicationModel> get _filteredMeds {
    var active = _meds.where((m) => m.isActive).toList();
    if (_selectedPatientId != null) {
      active = active
          .where((m) => m.patientId == _selectedPatientId)
          .toList();
    }
    if (_searchQuery.isEmpty) return active;
    final q = _searchQuery.toLowerCase();
    return active.where((m) {
      final group = _groupNameFor(m.patientId)?.toLowerCase() ?? '';
      return m.patientName.toLowerCase().contains(q) ||
          m.name.toLowerCase().contains(q) ||
          group.contains(q);
    }).toList();
  }

  Future<void> _deactivate(MedicationModel med) async {
    try {
      await MedicationService.instance.updateMedication(
        medId: med.id,
        isActive: false,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Prescription deactivated.'),
          backgroundColor: CuramindColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: CuramindColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPrescriptionModal({
    MedicationModel? existing,
    String? preselectedPatientId,
  }) {
    if (_patients.isEmpty && existing == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'No linked patients yet. Create a join code and have a patient join first.',
          ),
          backgroundColor: CuramindColors.slate,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _PrescriptionFormModal(
          patients: _patients,
          initialMed: existing,
          preselectedPatientId: preselectedPatientId,
          onSaved: () async {
            await _load();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  existing != null
                      ? 'Prescription updated'
                      : 'Prescription sent to patient',
                ),
                backgroundColor: CuramindColors.sageDeep,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = RefreshIndicator(
      onRefresh: _load,
      color: CuramindColors.sageDeep,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Prescriptions',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: CuramindColors.ink,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Prescribe to patients linked via your care group.',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          color: CuramindColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                CursorHoverRegion(
                  child: FilledButton.icon(
                    onPressed: _loading
                        ? null
                        : () => _showPrescriptionModal(),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('New prescription'),
                    style: FilledButton.styleFrom(
                      backgroundColor: CuramindColors.coral,
                      foregroundColor: CuramindColors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: CuramindColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: CuramindColors.sageSoft),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: CuramindColors.slate),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search patient, group, or medication...',
                        hintStyle: GoogleFonts.outfit(
                          color: CuramindColors.inkMuted,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Linked patients',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: CuramindColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap a card to prescribe. Tap again to clear filter.',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: CuramindColors.inkMuted,
              ),
            ),
            if (_patients.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 108,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _patients.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final p = _patients[i];
                    final selected = _selectedPatientId == p.patientId;
                    final groupLabel =
                        (p.groupName?.trim().isNotEmpty == true)
                            ? p.groupName!.trim()
                            : 'Care group';
                    final medCount = _meds
                        .where((m) => m.isActive && m.patientId == p.patientId)
                        .length;
                    return CursorHoverRegion(
                      child: _PatientTile(
                        patientName: p.patientName,
                        groupName: groupLabel,
                        medCount: medCount,
                        selected: selected,
                        onTap: () {
                          setState(() {
                            _selectedPatientId =
                                selected ? null : p.patientId;
                          });
                          if (!selected) {
                            _showPrescriptionModal(
                              preselectedPatientId: p.patientId,
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
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
            else if (_filteredMeds.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    _patients.isEmpty
                        ? 'No linked patients on the server. Create a join code while Backend is online, then have the patient join again (disconnect first if they joined offline).'
                        : _selectedPatientId != null
                            ? 'No prescriptions for this patient yet. Use the card above to prescribe.'
                            : 'No active prescriptions. Tap a patient card to prescribe.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: CuramindColors.slate),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredMeds.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final med = _filteredMeds[index];
                  return _MedicationCard(
                    data: med,
                    groupName: _groupNameFor(med.patientId),
                    onTap: () => _showPrescriptionModal(existing: med),
                    onDelete: () => _deactivate(med),
                  );
                },
              ),
          ],
        ),
      ),
    );

    if (widget.embedded) return content;

    return Scaffold(
      backgroundColor: CuramindColors.mist,
      body: SafeArea(child: content),
    );
  }
}

class _PatientTile extends StatelessWidget {
  const _PatientTile({
    required this.patientName,
    required this.groupName,
    required this.medCount,
    required this.selected,
    required this.onTap,
  });

  final String patientName;
  final String groupName;
  final int medCount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? CuramindColors.sageDeep : CuramindColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 168,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? CuramindColors.sageDeep
                  : CuramindColors.mistBlue,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 18,
                    color: selected
                        ? CuramindColors.white
                        : CuramindColors.sageDeep,
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: selected
                          ? CuramindColors.white.withValues(alpha: 0.18)
                          : CuramindColors.mistBlue,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '$medCount med${medCount == 1 ? '' : 's'}',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? CuramindColors.white
                            : CuramindColors.ocean,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                patientName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selected ? CuramindColors.white : CuramindColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                groupName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: selected
                      ? CuramindColors.white.withValues(alpha: 0.85)
                      : CuramindColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final MedicationModel data;
  final String? groupName;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MedicationCard({
    required this.data,
    required this.groupName,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CuramindColors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: CuramindColors.sageSoft.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: CuramindColors.slate.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.patientName,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: CuramindColors.ink,
                          ),
                        ),
                        if (groupName != null && groupName!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            groupName!,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: CuramindColors.ocean,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          data.name,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: CuramindColors.slate,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data.dosageAndFreq,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: CuramindColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: CuramindColors.sageSoft.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Active',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CuramindColors.sageDeep,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Tap to edit',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: CuramindColors.inkMuted,
                    ),
                  ),
                  const Spacer(),
                  CursorHoverRegion(
                    child: FilledButton.icon(
                      onPressed: onDelete,
                      style: FilledButton.styleFrom(
                        backgroundColor: CuramindColors.danger,
                      ),
                      icon: const Icon(Icons.block_rounded, size: 18),
                      label: const Text('Deactivate'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrescriptionFormModal extends StatefulWidget {
  final List<LinkedPatient> patients;
  final MedicationModel? initialMed;
  final String? preselectedPatientId;
  final Future<void> Function() onSaved;

  const _PrescriptionFormModal({
    required this.patients,
    this.initialMed,
    this.preselectedPatientId,
    required this.onSaved,
  });

  @override
  State<_PrescriptionFormModal> createState() =>
      _PrescriptionFormModalState();
}

class _PrescriptionFormModalState extends State<_PrescriptionFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _medNameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedPatientId;
  String _selectedFrequency = 'Once daily';
  bool _isSubmitting = false;

  final _frequencies = const [
    'Once daily',
    'Twice daily',
    'Three times daily',
    'As needed (PRN)',
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMed;
    if (initial != null) {
      _selectedPatientId = initial.patientId;
      _medNameController.text = initial.name;
      final parts = initial.dosageAndFreq.split('·');
      _dosageController.text = parts.isNotEmpty ? parts.first.trim() : '';
      if (parts.length > 1) {
        final freq = parts.sublist(1).join('·').trim();
        if (_frequencies.contains(freq)) _selectedFrequency = freq;
        if (parts.length > 2) {
          _notesController.text = parts.sublist(2).join('·').trim();
        }
      }
    } else if (widget.preselectedPatientId != null &&
        widget.patients.any((p) => p.patientId == widget.preselectedPatientId)) {
      _selectedPatientId = widget.preselectedPatientId;
    } else if (widget.patients.isNotEmpty) {
      _selectedPatientId = widget.patients.first.patientId;
    }
  }

  @override
  void dispose() {
    _medNameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final patientId = _selectedPatientId;
    if (patientId == null || patientId.isEmpty) return;

    LinkedPatient? patient;
    for (final p in widget.patients) {
      if (p.patientId == patientId) {
        patient = p;
        break;
      }
    }
    final patientName =
        patient?.patientName ?? widget.initialMed?.patientName ?? 'Patient';

    final dosage = _dosageController.text.trim();
    final notes = _notesController.text.trim();
    final dosageAndFreq = [
      dosage,
      _selectedFrequency,
      if (notes.isNotEmpty) notes,
    ].join(' · ');

    setState(() => _isSubmitting = true);
    try {
      if (widget.initialMed != null) {
        await MedicationService.instance.updateMedication(
          medId: widget.initialMed!.id,
          name: _medNameController.text.trim(),
          dosageAndFreq: dosageAndFreq,
        );
      } else {
        await MedicationService.instance.prescribe(
          patientId: patientId,
          patientName: patientName,
          name: _medNameController.text.trim(),
          dosageAndFreq: dosageAndFreq,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      await widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: CuramindColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientItems = <DropdownMenuItem<String>>[
      ...widget.patients.map(
        (p) {
          final group = p.groupName?.trim();
          final label = (group != null && group.isNotEmpty)
              ? '${p.patientName} · $group'
              : p.patientName;
          return DropdownMenuItem(
            value: p.patientId,
            child: Text(label),
          );
        },
      ),
      if (widget.initialMed != null &&
          !widget.patients
              .any((p) => p.patientId == widget.initialMed!.patientId))
        DropdownMenuItem(
          value: widget.initialMed!.patientId,
          child: Text(widget.initialMed!.patientName),
        ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: CuramindColors.mist,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.initialMed == null
                      ? 'New prescription'
                      : 'Edit prescription',
                  style: GoogleFonts.fraunces(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: CuramindColors.ink,
                  ),
                ),
                CursorHoverRegion(
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Patient',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CuramindColors.slate,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: CuramindColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: CuramindColors.mistBlue),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPatientId,
                  isExpanded: true,
                  hint: const Text('Select linked patient'),
                  items: patientItems,
                  onChanged: widget.initialMed != null
                      ? null
                      : (v) => setState(() => _selectedPatientId = v),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _medNameController,
              decoration: const InputDecoration(
                labelText: 'Medication name',
                hintText: 'e.g., Escitalopram',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dosageController,
                    decoration: const InputDecoration(
                      labelText: 'Dosage',
                      hintText: 'e.g., 10 mg',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: CuramindColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: CuramindColors.mistBlue),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedFrequency,
                        isExpanded: true,
                        items: _frequencies
                            .map(
                              (f) => DropdownMenuItem(
                                value: f,
                                child: Text(f),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _selectedFrequency = v);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Instructions (optional)',
                hintText: 'Take with food...',
              ),
            ),
            const SizedBox(height: 24),
            CursorHoverRegion(
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: CuramindColors.sageDeep,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: CuramindColors.white,
                        ),
                      )
                    : Text(
                        widget.initialMed == null
                            ? 'Submit prescription'
                            : 'Save changes',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
