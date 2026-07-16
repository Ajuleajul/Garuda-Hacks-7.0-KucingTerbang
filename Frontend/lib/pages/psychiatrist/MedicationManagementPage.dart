import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../animated_cursor.dart';
import '../../theme/curamind_theme.dart';

class MedicationManagementPage extends StatelessWidget {
  const MedicationManagementPage({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> activeMeds = [
      {
        'patient': 'Alex Johnson',
        'medication': 'Escitalopram',
        'dosage': '10 mg',
        'frequency': 'Once Daily',
        'status': 'Active',
        'refillProgress': 0.6,
      },
      {
        'patient': 'Sarah Williams',
        'medication': 'Sertraline',
        'dosage': '50 mg',
        'frequency': 'Twice Daily',
        'status': 'Refill Due',
        'refillProgress': 0.95,
      },
      {
        'patient': 'Michael Chen',
        'medication': 'Fluoxetine',
        'dosage': '20 mg',
        'frequency': 'Once Daily',
        'status': 'Active',
        'refillProgress': 0.2,
      },
      {
        'patient': 'Emma Davis',
        'medication': 'Bupropion',
        'dosage': '150 mg',
        'frequency': 'Once Daily',
        'status': 'Monitoring',
        'refillProgress': 0.4,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activeMeds.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _MedicationCard(data: activeMeds[index]);
            },
          ),
        ],
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _MedicationCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final bool isWarning = data['status'] == 'Refill Due';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CuramindColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isWarning ? CuramindColors.danger.withValues(alpha: 0.3) : CuramindColors.sageSoft.withValues(alpha: 0.5),
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
                      data['patient'],
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: CuramindColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data['medication']} • ${data['dosage']}',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: CuramindColors.slate,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data['frequency'],
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
                  color: isWarning ? CuramindColors.danger.withValues(alpha: 0.1) : CuramindColors.sageSoft.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  data['status'],
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
                '${(data['refillProgress'] * 100).toInt()}%',
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
              value: data['refillProgress'],
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
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Adjust Dose'),
                ),
              ),
              const SizedBox(width: 8),
              CursorHoverRegion(
                child: FilledButton.icon(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: isWarning ? CuramindColors.danger : CuramindColors.sageDeep,
                  ),
                  icon: const Icon(Icons.autorenew_rounded, size: 18),
                  label: const Text('Refill'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
