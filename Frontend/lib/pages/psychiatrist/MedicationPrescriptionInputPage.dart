import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../animated_cursor.dart';
import '../../theme/curamind_theme.dart';

class MedicationPrescriptionInputPage extends StatefulWidget {
  const MedicationPrescriptionInputPage({super.key});

  @override
  State<MedicationPrescriptionInputPage> createState() =>
      _MedicationPrescriptionInputPageState();
}

class _MedicationPrescriptionInputPageState
    extends State<MedicationPrescriptionInputPage> {
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

  bool _isSubmitting = false;

  Future<void> _submitPrescription() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;
    
    setState(() => _isSubmitting = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Prescription sent to pharmacy for $_selectedPatient'),
        backgroundColor: CuramindColors.sageDeep,
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    _formKey.currentState!.reset();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Write Prescription',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: CuramindColors.ink,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create and assign a new medication plan for a patient.',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: CuramindColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
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
                          icon: const Icon(Icons.keyboard_arrow_down,
                              color: CuramindColors.slate),
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
                  const SizedBox(height: 24),

                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Medication Name',
                      hintText: 'e.g., Escitalopram',
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Dosage (mg)',
                            hintText: 'e.g., 10',
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 2),
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
                                    icon: const Icon(Icons.keyboard_arrow_down,
                                        color: CuramindColors.slate),
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
                                        setState(
                                            () => _selectedFrequency = newValue);
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
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Duration (days)',
                            hintText: '30',
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Refills',
                            hintText: '0',
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  TextFormField(
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Clinical Notes & Instructions',
                      hintText: 'Take with food...',
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  CursorHoverRegion(
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submitPrescription,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: CuramindColors.white,
                              ),
                            )
                          : const Text('Submit Prescription'),
                    ),
                  ),
                ],
              ),
            ),
        ),
    );
  }
}
