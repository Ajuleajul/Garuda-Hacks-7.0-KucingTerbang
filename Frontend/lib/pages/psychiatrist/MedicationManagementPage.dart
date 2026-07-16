import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../animated_cursor.dart';
import '../../theme/curamind_theme.dart';

class Medication {
  String id;
  String patient;
  String name;
  String dosage;
  String frequency;
  String status;
  double refillProgress;
  int durationDays;
  int refillsRemaining;
  String notes;

  Medication({
    required this.id,
    required this.patient,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.status,
    required this.refillProgress,
    this.durationDays = 30,
    this.refillsRemaining = 0,
    this.notes = '',
  });
}

class MedicationManagementPage extends StatefulWidget {
  const MedicationManagementPage({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  State<MedicationManagementPage> createState() => _MedicationManagementPageState();
}

class _MedicationManagementPageState extends State<MedicationManagementPage> {
  final List<Medication> _activeMeds = [
    Medication(
      id: 'm1',
      patient: 'Alex Johnson',
      name: 'Escitalopram',
      dosage: '10 mg',
      frequency: 'Once Daily',
      status: 'Active',
      refillProgress: 0.6,
    ),
    Medication(
      id: 'm2',
      patient: 'Sarah Williams',
      name: 'Sertraline',
      dosage: '50 mg',
      frequency: 'Twice Daily',
      status: 'Refill Due',
      refillProgress: 0.95,
    ),
    Medication(
      id: 'm3',
      patient: 'Michael Chen',
      name: 'Fluoxetine',
      dosage: '20 mg',
      frequency: 'Once Daily',
      status: 'Active',
      refillProgress: 0.2,
    ),
    Medication(
      id: 'm4',
      patient: 'Emma Davis',
      name: 'Bupropion',
      dosage: '150 mg',
      frequency: 'Once Daily',
      status: 'Monitoring',
      refillProgress: 0.4,
    ),
  ];

  String _searchQuery = '';

  List<Medication> get _filteredMeds {
    if (_searchQuery.isEmpty) return _activeMeds;
    final q = _searchQuery.toLowerCase();
    return _activeMeds.where((m) {
      return m.patient.toLowerCase().contains(q) || m.name.toLowerCase().contains(q);
    }).toList();
  }

  void _deleteMedication(String id) {
    setState(() {
      _activeMeds.removeWhere((m) => m.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Prescription deactivated.'),
        backgroundColor: CuramindColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPrescriptionModal([Medication? existingMed]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _PrescriptionFormModal(
          initialMed: existingMed,
          onSave: (newMed) {
            setState(() {
              if (existingMed != null) {
                final idx = _activeMeds.indexWhere((m) => m.id == existingMed.id);
                if (idx != -1) _activeMeds[idx] = newMed;
              } else {
                _activeMeds.insert(0, newMed);
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(existingMed != null
                    ? 'Prescription updated for ${newMed.patient}'
                    : 'New prescription added for ${newMed.patient}'),
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
    final content = SingleChildScrollView(
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
                        'Manage ongoing patient medications and refill statuses.',
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
                    onPressed: () => _showPrescriptionModal(),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Buat Resep Baru'),
                    style: FilledButton.styleFrom(
                      backgroundColor: CuramindColors.coral,
                      foregroundColor: CuramindColors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
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
                              hintText: 'Search patient or medication...',
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
                ),
                const SizedBox(width: 12),
                CursorHoverRegion(
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.filter_list_rounded, size: 20),
                    label: const Text('Filter'),
                    style: FilledButton.styleFrom(
                      backgroundColor: CuramindColors.white,
                      foregroundColor: CuramindColors.slate,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: CuramindColors.sageSoft),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_filteredMeds.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'Belum ada data obat',
                    style: GoogleFonts.outfit(color: CuramindColors.slate),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredMeds.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _MedicationCard(
                    data: _filteredMeds[index],
                    onEdit: () => _showPrescriptionModal(_filteredMeds[index]),
                    onDelete: () => _deleteMedication(_filteredMeds[index].id),
                  );
                },
              ),
          ],
        ),
    );

    if (widget.embedded) return content;
    
    return Scaffold(
      backgroundColor: CuramindColors.mist,
      body: SafeArea(child: content),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final Medication data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedicationCard({
    required this.data,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isWarning = data.status == 'Refill Due';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CuramindColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isWarning
              ? CuramindColors.danger.withValues(alpha: 0.3)
              : CuramindColors.sageSoft.withValues(alpha: 0.5),
          width: isWarning ? 1.5 : 1.0,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.patient,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: CuramindColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data.name} • ${data.dosage}',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: CuramindColors.slate,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.frequency,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: CuramindColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isWarning
                      ? CuramindColors.danger.withValues(alpha: 0.1)
                      : CuramindColors.sageSoft.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  data.status,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isWarning ? CuramindColors.danger : CuramindColors.sageDeep,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Supply Used',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: CuramindColors.slate,
                ),
              ),
              const Spacer(),
              Text(
                '${(data.refillProgress * 100).toInt()}%',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isWarning ? CuramindColors.danger : CuramindColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: data.refillProgress,
              minHeight: 8,
              backgroundColor: CuramindColors.mistBlue,
              valueColor: AlwaysStoppedAnimation<Color>(
                isWarning ? CuramindColors.danger : CuramindColors.sage,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CursorHoverRegion(
                child: TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Adjust Dose'),
                ),
              ),
              const SizedBox(width: 8),
              CursorHoverRegion(
                child: FilledButton.icon(
                  onPressed: onDelete,
                  style: FilledButton.styleFrom(
                    backgroundColor: CuramindColors.danger,
                  ),
                  icon: const Icon(Icons.block_rounded, size: 18),
                  label: const Text('Nonaktifkan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrescriptionFormModal extends StatefulWidget {
  final Medication? initialMed;
  final ValueChanged<Medication> onSave;

  const _PrescriptionFormModal({this.initialMed, required this.onSave});

  @override
  State<_PrescriptionFormModal> createState() => _PrescriptionFormModalState();
}

class _PrescriptionFormModalState extends State<_PrescriptionFormModal> {
  final _formKey = GlobalKey<FormState>();

  String _selectedPatient = 'Alex Johnson';
  String _selectedFrequency = 'Once Daily';

  final List<String> _patients = [
    'Alex Johnson',
    'Sarah Williams',
    'Michael Chen',
    'Emma Davis'
  ];

  final List<String> _frequencies = [
    'Once Daily',
    'Twice Daily',
    'Three Times Daily',
    'As Needed (PRN)'
  ];

  final _medNameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _durationController = TextEditingController();
  final _refillsController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialMed != null) {
      final med = widget.initialMed!;
      if (_patients.contains(med.patient)) {
        _selectedPatient = med.patient;
      }
      if (_frequencies.contains(med.frequency)) {
        _selectedFrequency = med.frequency;
      }
      _medNameController.text = med.name;
      // parse dosage
      _dosageController.text = med.dosage.replaceAll(RegExp(r'[^0-9.]'), '');
      _durationController.text = med.durationDays.toString();
      _refillsController.text = med.refillsRemaining.toString();
      _notesController.text = med.notes;
    }
  }

  @override
  void dispose() {
    _medNameController.dispose();
    _dosageController.dispose();
    _durationController.dispose();
    _refillsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    
    final newMed = Medication(
      id: widget.initialMed?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      patient: _selectedPatient,
      name: _medNameController.text,
      dosage: '${_dosageController.text} mg',
      frequency: _selectedFrequency,
      status: widget.initialMed?.status ?? 'Active',
      refillProgress: widget.initialMed?.refillProgress ?? 0.0,
      durationDays: int.tryParse(_durationController.text) ?? 30,
      refillsRemaining: int.tryParse(_refillsController.text) ?? 0,
      notes: _notesController.text,
    );

    widget.onSave(newMed);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
                  widget.initialMed == null ? 'Buat Resep Baru' : 'Edit Resep',
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
              'Select Patient',
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
              child: CursorHoverRegion(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPatient,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: CuramindColors.slate),
                    dropdownColor: CuramindColors.white,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: CuramindColors.ink,
                    ),
                    items: _patients.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() => _selectedPatient = newValue);
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _medNameController,
              decoration: const InputDecoration(
                labelText: 'Medication Name',
                hintText: 'e.g., Escitalopram',
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dosageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Dosage (mg)',
                      hintText: 'e.g., 10',
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        decoration: BoxDecoration(
                          color: CuramindColors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: CuramindColors.mistBlue),
                        ),
                        child: CursorHoverRegion(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedFrequency,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down, color: CuramindColors.slate),
                              dropdownColor: CuramindColors.white,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: CuramindColors.ink,
                              ),
                              items: _frequencies.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  setState(() => _selectedFrequency = newValue);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Duration (days)',
                      hintText: '30',
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _refillsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Refills',
                      hintText: '0',
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Clinical Notes & Instructions',
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
                    : Text(widget.initialMed == null ? 'Submit Prescription' : 'Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
