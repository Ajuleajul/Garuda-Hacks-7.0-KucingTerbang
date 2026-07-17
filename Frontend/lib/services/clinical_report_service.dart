import 'dart:math' as math;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'diary_service.dart';
import 'link_service.dart';
import 'medication_service.dart';

class ClinicalReportOptions {
  const ClinicalReportOptions({
    this.includeDemographics = true,
    this.includeExecutiveSummary = true,
    this.includeMoodAffect = true,
    this.includeUrgeRisk = true,
    this.includeEmotionTags = true,
    this.includeMedications = true,
    this.includeAdherenceChart = true,
    this.includeDiaryLog = true,
    this.includeCopingLog = true,
    this.days = 30,
  });

  final bool includeDemographics;
  final bool includeExecutiveSummary;
  final bool includeMoodAffect;
  final bool includeUrgeRisk;
  final bool includeEmotionTags;
  final bool includeMedications;
  final bool includeAdherenceChart;
  final bool includeDiaryLog;
  final bool includeCopingLog;
  final int days;
}

class ClinicalReportService {
  ClinicalReportService._();
  static final ClinicalReportService instance = ClinicalReportService._();

  pw.Font? _fontRegular;
  pw.Font? _fontBold;

  Future<void> _ensureFonts() async {
    if (_fontRegular != null && _fontBold != null) return;

    try {
      _fontRegular = await PdfGoogleFonts.notoSansRegular();
      _fontBold = await PdfGoogleFonts.notoSansBold();
      return;
    } catch (_) {}

    try {
      final regular =
          await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      final bold = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
      if (regular.lengthInBytes < 1000 || bold.lengthInBytes < 1000) {
        throw StateError('Font assets are empty');
      }
      _fontRegular = pw.Font.ttf(regular);
      _fontBold = pw.Font.ttf(bold);
    } catch (e) {
      _fontRegular = null;
      _fontBold = null;
      throw StateError(
        'Unable to load PDF fonts. Fully stop the app and run flutter run again (hot reload will not pick up fonts). $e',
      );
    }
  }

  String get _clinicianName {
    final user = Supabase.instance.client.auth.currentUser;
    final meta = user?.userMetadata ?? {};
    final name = meta['full_name'] as String?;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    return user?.email ?? 'Clinician';
  }

  String get _clinicianEmail =>
      Supabase.instance.client.auth.currentUser?.email ?? '';

  Future<Uint8List> buildPdf({
    required JoinGroup group,
    required GroupMember member,
    required ClinicalReportOptions options,
  }) async {
    await _ensureFonts();
    final font = _fontRegular!;
    final fontBold = _fontBold!;

    final diary = member.monitoringOn
        ? await DiaryService.instance.loadClinicianPatientEntries(
            member.patientId,
            limit: 200,
          )
        : const <DiaryEntryModel>[];
    final medStats = await MedicationService.instance.loadPatientPeriodStats(
      member.patientId,
      days: options.days,
    );

    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final cutoff = today.subtract(Duration(days: options.days - 1));

    final inRange = diary.where((e) {
      final d = DateTime.utc(
        e.createdAt.toUtc().year,
        e.createdAt.toUtc().month,
        e.createdAt.toUtc().day,
      );
      return !d.isBefore(cutoff) && !d.isAfter(today);
    }).toList();

    final dbt = inRange
        .where((e) => e.kind == DiaryEntryKind.dbtCard)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final coping = inRange
        .where((e) => e.kind == DiaryEntryKind.coping)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final daySeries = _buildDaySeries(
      days: options.days,
      today: today,
      dbt: dbt,
      medStats: medStats,
    );

    final moods = dbt.where((e) => e.mood > 0).map((e) => e.mood).toList();
    final affects =
        dbt.where((e) => e.affectIntensity > 0).map((e) => e.affectIntensity);
    final avgMood = moods.isEmpty
        ? null
        : moods.reduce((a, b) => a + b) / moods.length;
    final avgAffect = affects.isEmpty
        ? null
        : affects.reduce((a, b) => a + b) / affects.length;
    final peakUrge = dbt.isEmpty
        ? null
        : dbt
            .map((e) => math.max(e.urgeNssi, e.urgeSubstance))
            .reduce(math.max);
    final highUrgeDays = daySeries.where((d) => (d.urge ?? 0) >= 7).length;
    final lowMoodDays = daySeries.where((d) => (d.mood ?? 11) <= 3.5).length;

    final emotions = _countTags(dbt.expand((e) => e.emotions));
    final triggers = _countTags(dbt.expand((e) => e.triggers));
    final skills = _countTags(dbt.expand((e) => e.skills));

    final reportId =
        'CM-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final generatedAt = DateTime.now();

    final doc = pw.Document(
      title: 'Curamind Clinical Report - ${member.patientName}',
      author: _clinicianName,
      subject: 'Longitudinal psychiatric monitoring report',
      creator: 'Curamind',
    );

    final base = pw.ThemeData.withFont(
      base: font,
      bold: fontBold,
      italic: font,
      boldItalic: fontBold,
    );

    doc.addPage(
      pw.MultiPage(
        theme: base,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 40),
        header: (ctx) => _header(
          reportId: reportId,
          generatedAt: generatedAt,
        ),
        footer: (ctx) => _footer(ctx),
        build: (ctx) {
          final widgets = <pw.Widget>[
            _confidentialBanner(),
            pw.SizedBox(height: 14),
            _titleBlock(
              patientName: member.patientName,
              groupName: group.name,
              days: options.days,
            ),
            pw.SizedBox(height: 16),
          ];

          if (options.includeDemographics) {
            widgets.addAll([
              _sectionTitle('1. Patient identification'),
              _kvTable([
                ['Full name', member.patientName],
                ['Email', member.email?.isNotEmpty == true ? member.email! : '-'],
                ['Patient ID', member.patientId],
                ['Care group', group.name],
                ['Group invite code', group.code],
                ['Link status', member.status],
                [
                  'Monitoring',
                  member.monitoringOn ? 'Enabled' : 'Disabled',
                ],
                ['Linked at', _fmtDateTime(member.linkedAt)],
                ['Report period', 'Last ${options.days} days'],
                ['Clinician', '$_clinicianName ($_clinicianEmail)'],
              ]),
              pw.SizedBox(height: 14),
            ]);
          }

          if (options.includeExecutiveSummary) {
            widgets.addAll([
              _sectionTitle('2. Executive clinical summary'),
              pw.Paragraph(
                text:
                    'This report aggregates ecological momentary assessment (EMA) diary cards '
                    'and medication adherence logs for the selected period. Metrics are derived '
                    'only from recorded observations; missing days are omitted from averages.',
                style: const pw.TextStyle(fontSize: 9, lineSpacing: 1.3),
              ),
              pw.SizedBox(height: 8),
              _metricGrid([
                _Metric(
                  'Avg mood',
                  avgMood == null ? '-' : avgMood.toStringAsFixed(1),
                  '/10',
                ),
                _Metric(
                  'Avg affect',
                  avgAffect == null ? '-' : avgAffect.toStringAsFixed(1),
                  '/10',
                ),
                _Metric(
                  'Peak urge',
                  peakUrge?.toString() ?? '-',
                  '/10',
                ),
                _Metric(
                  'Adherence',
                  medStats.logged == 0
                      ? '-'
                      : '${medStats.adherencePct}%',
                  'period',
                ),
                _Metric('DBT cards', '${dbt.length}', 'in range'),
                _Metric('Coping logs', '${coping.length}', 'in range'),
                _Metric('Active Rx', '${medStats.activeMeds}', 'meds'),
                _Metric('High-urge days', '$highUrgeDays', 'urge >= 7'),
                _Metric('Low-mood days', '$lowMoodDays', 'mood <= 3.5'),
              ]),
              if ((peakUrge ?? 0) >= 7 || lowMoodDays > 0 || !member.monitoringOn)
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 8),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFFFEBEE),
                    border: pw.Border.all(color: PdfColor.fromInt(0xFFC62828)),
                  ),
                  child: pw.Text(
                    [
                      if (!member.monitoringOn)
                        'Monitoring is currently disabled by the patient link setting.',
                      if ((peakUrge ?? 0) >= 7)
                        'Elevated urge intensity detected (peak $peakUrge/10).',
                      if (lowMoodDays > 0)
                        'Low mood recorded on $lowMoodDays day(s).',
                    ].join(' '),
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColor.fromInt(0xFFB71C1C),
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              pw.SizedBox(height: 14),
            ]);
          }

          if (options.includeMoodAffect) {
            widgets.addAll([
              _sectionTitle('3. Mood & affect trajectory'),
              pw.Text(
                'Daily mean mood (0-10) from DBT diary cards.',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 8),
              _lineChart(
                daySeries
                    .where((d) => d.mood != null)
                    .map((d) => d.mood! * 10)
                    .toList(),
                label: 'Mood x10 (aligned to 0-100 scale)',
                color: PdfColor.fromInt(0xFF1F6F8B),
              ),
              pw.SizedBox(height: 8),
              _dayMetricTable(
                daySeries,
                includeMood: true,
                includeAffect: true,
                includeUrge: false,
                includeAdherence: false,
              ),
              pw.SizedBox(height: 14),
            ]);
          }

          if (options.includeUrgeRisk) {
            widgets.addAll([
              _sectionTitle('4. Urge & risk monitoring'),
              pw.Text(
                'Peak daily urge = max(NSSI urge, substance urge) on DBT cards.',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 8),
              _lineChart(
                daySeries
                    .where((d) => d.urge != null)
                    .map((d) => d.urge! * 10)
                    .toList(),
                label: 'Peak urge x10',
                color: PdfColor.fromInt(0xFFC62828),
              ),
              pw.SizedBox(height: 8),
              _dayMetricTable(
                daySeries,
                includeMood: false,
                includeAffect: false,
                includeUrge: true,
                includeAdherence: false,
              ),
              pw.SizedBox(height: 14),
            ]);
          }

          if (options.includeEmotionTags) {
            widgets.addAll([
              _sectionTitle('5. Emotions, triggers & skills'),
              _tagBlock('Frequent emotions', emotions),
              pw.SizedBox(height: 6),
              _tagBlock('Frequent triggers', triggers),
              pw.SizedBox(height: 6),
              _tagBlock('Skills reported', skills),
              pw.SizedBox(height: 14),
            ]);
          }

          if (options.includeMedications || options.includeAdherenceChart) {
            widgets.add(_sectionTitle('6. Medication profile & adherence'));
            if (options.includeMedications) {
              widgets.add(pw.SizedBox(height: 6));
              if (member.medications.isEmpty) {
                widgets.add(
                  pw.Text(
                    'No active prescriptions on file for this patient.',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                );
              } else {
                widgets.add(
                  pw.TableHelper.fromTextArray(
                    headers: const ['Medication', 'Dosage / frequency', 'Since'],
                    data: member.medications
                        .map(
                          (m) => [
                            m.name,
                            m.dosageAndFreq,
                            _fmtDate(m.createdAt),
                          ],
                        )
                        .toList(),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                      color: PdfColors.white,
                    ),
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFF2F5D50),
                    ),
                    cellStyle: const pw.TextStyle(fontSize: 8),
                    cellAlignments: {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.centerLeft,
                      2: pw.Alignment.centerLeft,
                    },
                    border: pw.TableBorder.all(
                      color: PdfColor.fromInt(0xFFCFD8DC),
                      width: 0.4,
                    ),
                  ),
                );
              }
              widgets.add(pw.SizedBox(height: 8));
              widgets.add(
                _kvTable([
                  ['Active medications', '${medStats.activeMeds}'],
                  ['Doses taken (period)', '${medStats.taken}'],
                  ['Doses missed (period)', '${medStats.missed}'],
                  [
                    'Logged adherence',
                    medStats.logged == 0
                        ? '?'
                        : '${medStats.adherencePct}% of logged doses',
                  ],
                ]),
              );
            }
            if (options.includeAdherenceChart) {
              widgets.add(pw.SizedBox(height: 8));
              widgets.add(
                pw.Text(
                  'Daily adherence % = taken / active prescriptions (or taken / logged if no active Rx count).',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              );
              widgets.add(pw.SizedBox(height: 6));
              widgets.add(
                _lineChart(
                  daySeries
                      .where((d) => d.adherencePct != null)
                      .map((d) => d.adherencePct!)
                      .toList(),
                  label: 'Adherence %',
                  color: PdfColor.fromInt(0xFF2F5D50),
                ),
              );
              widgets.add(pw.SizedBox(height: 8));
              widgets.add(
                _dayMetricTable(
                  daySeries,
                  includeMood: false,
                  includeAffect: false,
                  includeUrge: false,
                  includeAdherence: true,
                ),
              );
            }
            widgets.add(pw.SizedBox(height: 14));
          }

          if (options.includeDiaryLog) {
            widgets.addAll([
              _sectionTitle('7. DBT diary card log'),
              if (dbt.isEmpty)
                pw.Text(
                  'No DBT diary cards in this period.',
                  style: const pw.TextStyle(fontSize: 9),
                )
              else
                ...dbt.reversed.take(40).map(_dbtEntryBlock),
              if (dbt.length > 40)
                pw.Text(
                  'Showing latest 40 of ${dbt.length} DBT cards.',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              pw.SizedBox(height: 14),
            ]);
          }

          if (options.includeCopingLog) {
            widgets.addAll([
              _sectionTitle('8. Coping / CBT log'),
              if (coping.isEmpty)
                pw.Text(
                  'No coping entries in this period.',
                  style: const pw.TextStyle(fontSize: 9),
                )
              else
                ...coping.take(25).map(_copingEntryBlock),
              if (coping.length > 25)
                pw.Text(
                  'Showing latest 25 of ${coping.length} coping entries.',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              pw.SizedBox(height: 14),
            ]);
          }

          widgets.add(_attestation(generatedAt));
          return widgets;
        },
      ),
    );

    return doc.save();
  }

  Future<String> downloadPdf(Uint8List bytes, String filename) async {
    final name = safePdfName(filename);
    final baseName = name.toLowerCase().endsWith('.pdf')
        ? name.substring(0, name.length - 4)
        : name;
    return FileSaver.instance.saveFile(
      name: baseName,
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  static String safePdfName(String filename) {
    return filename.toLowerCase().endsWith('.pdf') ? filename : '$filename.pdf';
  }

  List<_DayRow> _buildDaySeries({
    required int days,
    required DateTime today,
    required List<DiaryEntryModel> dbt,
    required MedPeriodStats medStats,
  }) {
    final moodByDay = <String, List<double>>{};
    final affectByDay = <String, List<double>>{};
    final urgeByDay = <String, List<double>>{};
    for (final e in dbt) {
      final key = _dayKey(e.createdAt);
      if (e.mood > 0) moodByDay.putIfAbsent(key, () => []).add(e.mood.toDouble());
      if (e.affectIntensity > 0) {
        affectByDay
            .putIfAbsent(key, () => [])
            .add(e.affectIntensity.toDouble());
      }
      urgeByDay
          .putIfAbsent(key, () => [])
          .add(math.max(e.urgeNssi, e.urgeSubstance).toDouble());
    }
    final medByDay = {for (final d in medStats.byDay) d.dayKey: d};
    final active = medStats.activeMeds;

    return List.generate(days, (i) {
      final day = today.subtract(Duration(days: days - 1 - i));
      final key = _dayKey(day);
      final moods = moodByDay[key];
      final affects = affectByDay[key];
      final urges = urgeByDay[key];
      final med = medByDay[key];
      final taken = med?.taken ?? 0;
      final missed = med?.missed ?? 0;
      final logged = taken + missed;
      double? adh;
      if (active > 0) {
        adh = (taken / active) * 100;
      } else if (logged > 0) {
        adh = (taken / logged) * 100;
      }
      return _DayRow(
        key: key,
        label: '${day.month}/${day.day}',
        mood: (moods == null || moods.isEmpty)
            ? null
            : moods.reduce((a, b) => a + b) / moods.length,
        affect: (affects == null || affects.isEmpty)
            ? null
            : affects.reduce((a, b) => a + b) / affects.length,
        urge: (urges == null || urges.isEmpty)
            ? null
            : urges.reduce(math.max),
        adherencePct: adh?.clamp(0, 100),
        taken: taken,
        missed: missed,
      );
    });
  }

  static String _dayKey(DateTime dt) {
    final d = dt.toUtc();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Map<String, int> _countTags(Iterable<String> tags) {
    final counts = <String, int>{};
    for (final t in tags) {
      final k = t.trim();
      if (k.isEmpty) continue;
      counts[k] = (counts[k] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(12));
  }

  String _fmtDate(DateTime d) {
    final l = d.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')}';
  }

  String _fmtDateTime(DateTime d) {
    final l = d.toLocal();
    return '${_fmtDate(d)} '
        '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }

  pw.Widget _header({
    required String reportId,
    required DateTime generatedAt,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'CURAMIND',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF2F5D50),
                letterSpacing: 1.2,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              'CLINICAL MONITORING REPORT',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF455A64),
              ),
            ),
            pw.Spacer(),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Report ID: $reportId',
                  style: const pw.TextStyle(fontSize: 8),
                ),
                pw.Text(
                  'Generated: ${_fmtDateTime(generatedAt)}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Container(height: 1.2, color: PdfColor.fromInt(0xFF2F5D50)),
        pw.SizedBox(height: 8),
      ],
    );
  }

  pw.Widget _footer(pw.Context ctx) {
    return pw.Column(
      children: [
        pw.Container(height: 0.6, color: PdfColor.fromInt(0xFFB0BEC5)),
        pw.SizedBox(height: 6),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                'CONFIDENTIAL - Protected health information. For authorized clinical use only.',
                style: pw.TextStyle(
                  fontSize: 7,
                  color: PdfColor.fromInt(0xFF607D8B),
                ),
              ),
            ),
            pw.Text(
              'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _confidentialBanner() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFE8F0EE),
        border: pw.Border.all(color: PdfColor.fromInt(0xFF2F5D50), width: 0.8),
      ),
      child: pw.Text(
        'PROTECTED HEALTH INFORMATION (PHI) - Do not distribute outside the care team. '
        'This document is generated from Curamind longitudinal monitoring data.',
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromInt(0xFF1B4332),
        ),
      ),
    );
  }

  pw.Widget _titleBlock({
    required String patientName,
    required String groupName,
    required int days,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          patientName,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'Care group: $groupName | Observation window: last $days days',
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColor.fromInt(0xFF455A64),
          ),
        ),
      ],
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.only(bottom: 3),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColor.fromInt(0xFF90A4AE),
            width: 0.6,
          ),
        ),
      ),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 0.6,
          color: PdfColor.fromInt(0xFF263238),
        ),
      ),
    );
  }

  pw.Widget _kvTable(List<List<String>> rows) {
    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(1.1),
        1: const pw.FlexColumnWidth(2.2),
      },
      border: pw.TableBorder.all(
        color: PdfColor.fromInt(0xFFCFD8DC),
        width: 0.4,
      ),
      children: rows
          .map(
            (r) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    r[0],
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF455A64),
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(r[1], style: const pw.TextStyle(fontSize: 8)),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  pw.Widget _metricGrid(List<_Metric> metrics) {
    return pw.Wrap(
      spacing: 6,
      runSpacing: 6,
      children: metrics
          .map(
            (m) => pw.Container(
              width: 110,
              padding: const pw.EdgeInsets.all(7),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColor.fromInt(0xFFCFD8DC),
                  width: 0.5,
                ),
                color: PdfColor.fromInt(0xFFF7FAF9),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    m.label,
                    style: pw.TextStyle(
                      fontSize: 7,
                      color: PdfColor.fromInt(0xFF607D8B),
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    m.value,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(m.hint, style: const pw.TextStyle(fontSize: 7)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  pw.Widget _lineChart(
    List<double> values, {
    required String label,
    required PdfColor color,
  }) {
    if (values.length < 2) {
      return pw.Container(
        height: 70,
        alignment: pw.Alignment.center,
        child: pw.Text(
          'Insufficient points to render chart.',
          style: const pw.TextStyle(fontSize: 8),
        ),
      );
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
        pw.SizedBox(height: 4),
        pw.SizedBox(
          height: 90,
          child: pw.CustomPaint(
            size: const PdfPoint(500, 90),
            painter: (PdfGraphics canvas, PdfPoint size) {
              canvas
                ..setStrokeColor(PdfColor.fromInt(0xFFECEFF1))
                ..setLineWidth(0.5);
              for (var g = 0; g <= 4; g++) {
                final y = size.y * g / 4;
                canvas.drawLine(0, y, size.x, y);
              }
              const minV = 0.0;
              const maxV = 100.0;
              canvas
                ..setStrokeColor(color)
                ..setLineWidth(1.6);
              for (var i = 0; i < values.length; i++) {
                final x = i / (values.length - 1) * size.x;
                final y =
                    size.y - ((values[i] - minV) / (maxV - minV)) * size.y;
                if (i == 0) {
                  canvas.moveTo(x, y);
                } else {
                  canvas.lineTo(x, y);
                }
              }
              canvas.strokePath();
            },
          ),
        ),
      ],
    );
  }

  pw.Widget _dayMetricTable(
    List<_DayRow> rows, {
    required bool includeMood,
    required bool includeAffect,
    required bool includeUrge,
    required bool includeAdherence,
  }) {
    final headers = <String>['Date'];
    if (includeMood) headers.add('Mood');
    if (includeAffect) headers.add('Affect');
    if (includeUrge) headers.add('Peak urge');
    if (includeAdherence) headers.addAll(['Adh %', 'Taken', 'Missed']);

    final dataRows = rows.where((r) {
      if (includeMood && r.mood != null) return true;
      if (includeAffect && r.affect != null) return true;
      if (includeUrge && r.urge != null) return true;
      if (includeAdherence && r.adherencePct != null) return true;
      return false;
    }).toList();

    if (dataRows.isEmpty) {
      return pw.Text(
        'No observations in this section for the selected window.',
        style: const pw.TextStyle(fontSize: 8),
      );
    }

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: dataRows.map((r) {
        final row = <String>[r.label];
        if (includeMood) {
          row.add(r.mood == null ? '-' : r.mood!.toStringAsFixed(1));
        }
        if (includeAffect) {
          row.add(r.affect == null ? '-' : r.affect!.toStringAsFixed(1));
        }
        if (includeUrge) {
          row.add(r.urge == null ? '-' : r.urge!.toStringAsFixed(0));
        }
        if (includeAdherence) {
          row.add(
            r.adherencePct == null
                ? '-'
                : r.adherencePct!.toStringAsFixed(0),
          );
          row.add('${r.taken}');
          row.add('${r.missed}');
        }
        return row;
      }).toList(),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 8,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF455A64),
      ),
      cellStyle: const pw.TextStyle(fontSize: 7.5),
      cellAlignment: pw.Alignment.centerLeft,
      border: pw.TableBorder.all(
        color: PdfColor.fromInt(0xFFCFD8DC),
        width: 0.35,
      ),
    );
  }

  pw.Widget _tagBlock(String title, Map<String, int> counts) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 3),
        if (counts.isEmpty)
          pw.Text('None recorded.', style: const pw.TextStyle(fontSize: 8))
        else
          pw.Text(
            counts.entries.map((e) => '${e.key} (${e.value})').join(' | '),
            style: const pw.TextStyle(fontSize: 8, lineSpacing: 1.3),
          ),
      ],
    );
  }

  pw.Widget _dbtEntryBlock(DiaryEntryModel e) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.all(7),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColor.fromInt(0xFFCFD8DC),
          width: 0.4,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${_fmtDateTime(e.createdAt)} | Mood ${e.mood} | Affect ${e.affectIntensity} | '
            'Urge NSSI ${e.urgeNssi} / Substance ${e.urgeSubstance}',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
          if (e.emotions.isNotEmpty)
            pw.Text(
              'Emotions: ${e.emotions.join(', ')}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          if (e.triggers.isNotEmpty)
            pw.Text(
              'Triggers: ${e.triggers.join(', ')}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          if (e.skills.isNotEmpty)
            pw.Text(
              'Skills: ${e.skills.join(', ')}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          if (e.notes.isNotEmpty)
            pw.Text(
              'Notes: ${e.notes}',
              style: const pw.TextStyle(fontSize: 8),
            ),
        ],
      ),
    );
  }

  pw.Widget _copingEntryBlock(DiaryEntryModel e) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.all(7),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColor.fromInt(0xFFCFD8DC),
          width: 0.4,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _fmtDateTime(e.createdAt),
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
          if (e.situation.isNotEmpty)
            pw.Text(
              'Situation: ${e.situation}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          if (e.thoughts.isNotEmpty)
            pw.Text(
              'Thoughts: ${e.thoughts}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          if (e.behavior.isNotEmpty)
            pw.Text(
              'Behavior: ${e.behavior}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          if (e.outcome.isNotEmpty)
            pw.Text(
              'Outcome: ${e.outcome}',
              style: const pw.TextStyle(fontSize: 8),
            ),
        ],
      ),
    );
  }

  pw.Widget _attestation(DateTime generatedAt) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromInt(0xFF90A4AE), width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CLINICIAN ATTESTATION',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Prepared by: $_clinicianName | $_clinicianEmail\n'
            'Generated via Curamind on ${_fmtDateTime(generatedAt)}.\n'
            'This export reflects system-captured patient self-report and medication logs. '
            'Clinical interpretation remains the responsibility of the treating clinician.',
            style: const pw.TextStyle(fontSize: 8, lineSpacing: 1.3),
          ),
        ],
      ),
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.hint);
  final String label;
  final String value;
  final String hint;
}

class _DayRow {
  const _DayRow({
    required this.key,
    required this.label,
    required this.mood,
    required this.affect,
    required this.urge,
    required this.adherencePct,
    required this.taken,
    required this.missed,
  });

  final String key;
  final String label;
  final double? mood;
  final double? affect;
  final double? urge;
  final double? adherencePct;
  final int taken;
  final int missed;
}
