import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../animated_cursor.dart';
import '../../theme/curamind_theme.dart';

class ExportClinicalReportPage extends StatefulWidget {
  const ExportClinicalReportPage({super.key});

  @override
  State<ExportClinicalReportPage> createState() =>
      _ExportClinicalReportPageState();
}

class _ExportClinicalReportPageState extends State<ExportClinicalReportPage> {
  String _selectedPatient = 'Alex Johnson';
  String _selectedRange = 'Last 30 Days';

  final List<String> _patients = [
    'Alex Johnson',
    'Sarah Williams',
    'Michael Chen',
    'Emma Davis'
  ];

  final List<String> _ranges = [
    'Last 7 Days',
    'Last 30 Days',
    'Last 3 Months',
    'Year to Date',
    'All Time'
  ];

  bool _includeMood = true;
  bool _includeAdherence = true;
  bool _includeNotes = true;

  bool _isGenerating = false;

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _isGenerating = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report generated for $_selectedPatient'),
        backgroundColor: CuramindColors.sageDeep,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OPEN',
          textColor: CuramindColors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Export Clinical Report',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: CuramindColors.ink,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Generate EMR-compatible longitudinal reports for patients.',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: CuramindColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  'Patient Selection',
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

                Text(
                  'Date Range',
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
                        value: _selectedRange,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: CuramindColors.slate),
                        dropdownColor: CuramindColors.white,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: CuramindColors.ink,
                        ),
                        items: _ranges.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() => _selectedRange = newValue);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Included Data',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CuramindColors.slate,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: CuramindColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: CuramindColors.mistBlue),
                  ),
                  child: Column(
                    children: [
                      CursorHoverRegion(
                        child: CheckboxListTile(
                          value: _includeMood,
                          onChanged: (v) => setState(() => _includeMood = v ?? true),
                          title: Text(
                            'Mood & Emotional Logs',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                          ),
                          activeColor: CuramindColors.sageDeep,
                          checkColor: CuramindColors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      const Divider(height: 1, color: CuramindColors.mistBlue),
                      CursorHoverRegion(
                        child: CheckboxListTile(
                          value: _includeAdherence,
                          onChanged: (v) => setState(() => _includeAdherence = v ?? true),
                          title: Text(
                            'Medication Adherence History',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                          ),
                          activeColor: CuramindColors.sageDeep,
                          checkColor: CuramindColors.white,
                        ),
                      ),
                      const Divider(height: 1, color: CuramindColors.mistBlue),
                      CursorHoverRegion(
                        child: CheckboxListTile(
                          value: _includeNotes,
                          onChanged: (v) => setState(() => _includeNotes = v ?? true),
                          title: Text(
                            'Clinical Notes & Observations',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                          ),
                          activeColor: CuramindColors.sageDeep,
                          checkColor: CuramindColors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                CursorHoverRegion(
                  child: FilledButton.icon(
                    onPressed: _isGenerating ? null : _generateReport,
                    icon: _isGenerating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: CuramindColors.white,
                            ),
                          )
                        : const Icon(Icons.picture_as_pdf_rounded),
                    label: Text(_isGenerating ? 'Generating...' : 'Generate PDF Report'),
                    style: FilledButton.styleFrom(
                      backgroundColor: CuramindColors.sageDeep,
                      minimumSize: const Size.fromHeight(56),
                      textStyle: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                CursorHoverRegion(
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.cloud_upload_rounded),
                    label: const Text('Export directly to EMR'),
                    style: TextButton.styleFrom(
                      foregroundColor: CuramindColors.ocean,
                      textStyle: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }
}
