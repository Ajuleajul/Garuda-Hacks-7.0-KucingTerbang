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
            limit: 500,
          )
        : const <DiaryEntryModel>[];
    final results = await Future.wait([
      MedicationService.instance.loadPatientPeriodStats(
        member.patientId,
        days: options.days,
      ),
      MedicationService.instance.loadClinicianMeds(),
    ]);
    final medStats = results[0] as MedPeriodStats;
    final allMeds = results[1] as List<MedicationModel>;
    final patientMeds = allMeds
        .where((m) => m.patientId == member.patientId && m.isActive)
        .toList();

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
    final observedDays = daySeries.where((d) => d.hasObservation).toList();

    final moods = dbt.map((e) => e.mood).toList();
    final affects = dbt.map((e) => e.affectIntensity).toList();
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
    final periodStart = cutoff.toLocal();
    final periodEnd = today.toLocal();

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
        margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 36),
        header: (ctx) => _header(
          reportId: reportId,
          generatedAt: generatedAt,
        ),
        footer: (ctx) => _footer(ctx),
        build: (ctx) {
          final widgets = <pw.Widget>[
            _confidentialBanner(),
            pw.SizedBox(height: 12),
            _titleBlock(
              patientName: member.patientName,
              groupName: group.name,
              days: options.days,
              periodStart: periodStart,
              periodEnd: periodEnd,
              email: member.email,
            ),
            pw.SizedBox(height: 12),
          ];

          if (options.includeDemographics) {
            widgets.addAll([
              _sectionTitle('1. Patient identification'),
              _kvTable([
                ['Full name', member.patientName],
                [
                  'Email',
                  member.email?.isNotEmpty == true ? member.email! : '-',
                ],
                ['Care group', group.name],
                ['Invite code', group.code],
                ['Link status', member.status],
                [
                  'Monitoring',
                  member.monitoringOn ? 'Enabled' : 'Disabled',
                ],
                ['Linked since', _fmtDateTime(member.linkedAt)],
                [
                  'Observation window',
                  '${_fmtDate(periodStart)} to ${_fmtDate(periodEnd)} '
                      '(${options.days} days)',
                ],
                [
                  'Clinician',
                  _clinicianEmail.isEmpty
                      ? _clinicianName
                      : '$_clinicianName ? $_clinicianEmail',
                ],
                [
                  'Data captured',
                  '${dbt.length} DBT cards ? ${coping.length} coping ? '
                      '${patientMeds.length} active Rx ? '
                      '${observedDays.length} days with observations',
                ],
              ]),
              pw.SizedBox(height: 12),
            ]);
          }

          if (options.includeExecutiveSummary) {
            widgets.addAll([
              _sectionTitle('2. Executive clinical summary'),
              pw.Paragraph(
                text:
                    'Aggregated EMA diary cards and medication adherence for the selected window. '
                    'Averages use recorded observations only. Empty calendar days are omitted from averages '
                    'and from the observation table below.',
                style: const pw.TextStyle(fontSize: 9, lineSpacing: 1.35),
              ),
              pw.SizedBox(height: 8),
              _metricTable([
                [
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
                  _Metric('Peak urge', peakUrge?.toString() ?? '-', '/10'),
                ],
                [
                  _Metric(
                    'Adherence',
                    medStats.logged == 0 ? '-' : '${medStats.adherencePct}%',
                    'logged doses',
                  ),
                  _Metric('DBT cards', '${dbt.length}', 'in window'),
                  _Metric('Coping logs', '${coping.length}', 'in window'),
                ],
                [
                  _Metric('Active Rx', '${patientMeds.length}', 'medications'),
                  _Metric('High-urge days', '$highUrgeDays', 'urge >= 7'),
                  _Metric('Low-mood days', '$lowMoodDays', 'mood <= 3.5'),
                ],
              ]),
              if ((peakUrge ?? 0) >= 7 ||
                  lowMoodDays > 0 ||
                  !member.monitoringOn)
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 8),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFFFEBEE),
                    border:
                        pw.Border.all(color: PdfColor.fromInt(0xFFC62828)),
                  ),
                  child: pw.Text(
                    [
                      if (!member.monitoringOn)
                        'Monitoring is currently disabled ? diary content may be incomplete.',
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
              pw.SizedBox(height: 12),
            ]);
          }

          if (options.includeMoodAffect ||
              options.includeUrgeRisk ||
              options.includeAdherenceChart) {
            widgets.add(_sectionTitle('3. Daily observation log'));
            widgets.add(
              pw.Text(
                'One row per calendar day that has diary and/or medication activity.',
                style: const pw.TextStyle(fontSize: 8),
              ),
            );
            widgets.add(pw.SizedBox(height: 6));
            widgets.add(
              _combinedDayTable(
                observedDays,
                includeMood: options.includeMoodAffect,
                includeAffect: options.includeMoodAffect,
                includeUrge: options.includeUrgeRisk,
                includeAdherence: options.includeAdherenceChart,
              ),
            );
            widgets.add(pw.SizedBox(height: 10));
            if (options.includeMoodAffect) {
              widgets.add(
                _seriesChart(
                  title: 'Mood trajectory (0-10)',
                  days: observedDays.where((d) => d.mood != null).toList(),
                  valueOf: (d) => d.mood!,
                  color: PdfColor.fromInt(0xFF1F6F8B),
                  maxY: 10,
                ),
              );
              widgets.add(pw.SizedBox(height: 8));
              widgets.add(
                _seriesChart(
                  title: 'Affect intensity (0-10)',
                  days: observedDays.where((d) => d.affect != null).toList(),
                  valueOf: (d) => d.affect!,
                  color: PdfColor.fromInt(0xFF455A64),
                  maxY: 10,
                ),
              );
              widgets.add(pw.SizedBox(height: 8));
            }
            if (options.includeUrgeRisk) {
              widgets.add(
                _seriesChart(
                  title: 'Peak urge (max NSSI / substance, 0-10)',
                  days: observedDays.where((d) => d.urge != null).toList(),
                  valueOf: (d) => d.urge!,
                  color: PdfColor.fromInt(0xFFC62828),
                  maxY: 10,
                ),
              );
              widgets.add(pw.SizedBox(height: 8));
            }
            if (options.includeAdherenceChart) {
              widgets.add(
                _seriesChart(
                  title: 'Daily adherence % (taken / active Rx)',
                  days: observedDays
                      .where((d) => d.adherencePct != null)
                      .toList(),
                  valueOf: (d) => d.adherencePct!,
                  color: PdfColor.fromInt(0xFF2F5D50),
                  maxY: 100,
                ),
              );
            }
            widgets.add(pw.SizedBox(height: 12));
          }

          if (options.includeEmotionTags) {
            widgets.addAll([
              _sectionTitle('4. Emotions, triggers & skills'),
              _tagBlock('Frequent emotions', emotions),
              pw.SizedBox(height: 6),
              _tagBlock('Frequent triggers', triggers),
              pw.SizedBox(height: 6),
              _tagBlock('Skills reported', skills),
              pw.SizedBox(height: 12),
            ]);
          }

          if (options.includeMedications) {
            widgets.add(_sectionTitle('5. Medication profile & today status'));
            widgets.add(pw.SizedBox(height: 6));
            if (patientMeds.isEmpty) {
              widgets.add(
                pw.Text(
                  'No active prescriptions on file for this patient.',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              );
            } else {
              widgets.add(
                pw.TableHelper.fromTextArray(
                  headers: const [
                    'Medication',
                    'Dosage / frequency',
                    'Prescribed',
                    'Today',
                  ],
                  data: patientMeds
                      .map(
                        (m) => [
                          m.name,
                          m.dosageAndFreq,
                          _fmtDate(m.createdAt),
                          switch (m.todayStatus) {
                            MedDoseStatus.taken => 'Taken',
                            MedDoseStatus.missed => 'Missed',
                            MedDoseStatus.due => 'Not logged',
                          },
                        ],
                      )
                      .toList(),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 8,
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
                    3: pw.Alignment.center,
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
                ['Active medications', '${patientMeds.length}'],
                ['Doses taken (period)', '${medStats.taken}'],
                ['Doses missed (period)', '${medStats.missed}'],
                [
                  'Logged adherence',
                  medStats.logged == 0
                      ? 'No doses logged in window'
                      : '${medStats.adherencePct}% of logged doses '
                          '(${medStats.taken} taken / ${medStats.logged} logged)',
                ],
              ]),
            );
            widgets.add(pw.SizedBox(height: 12));
          }

          if (options.includeDiaryLog) {
            widgets.addAll([
              _sectionTitle('6. Full DBT diary card log'),
              if (dbt.isEmpty)
                pw.Text(
                  member.monitoringOn
                      ? 'No DBT diary cards in this period.'
                      : 'Monitoring is off ? diary entries are not available.',
                  style: const pw.TextStyle(fontSize: 9),
                )
              else
                ...dbt.reversed.map(_dbtEntryBlock),
              pw.SizedBox(height: 12),
            ]);
          }

          if (options.includeCopingLog) {
            widgets.addAll([
              _sectionTitle('7. Coping / CBT log'),
              if (coping.isEmpty)
                pw.Text(
                  'No coping entries in this period.',
                  style: const pw.TextStyle(fontSize: 9),
                )
              else
                ...coping.map(_copingEntryBlock),
              pw.SizedBox(height: 12),
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
      moodByDay.putIfAbsent(key, () => []).add(e.mood.toDouble());
      affectByDay
          .putIfAbsent(key, () => [])
          .add(e.affectIntensity.toDouble());
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
      if (logged > 0) {
        if (active > 0) {
          adh = (taken / active) * 100;
        } else {
          adh = (taken / logged) * 100;
        }
      }
      return _DayRow(
        key: key,
        label: '${day.toLocal().month}/${day.toLocal().day}',
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
    required DateTime periodStart,
    required DateTime periodEnd,
    String? email,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          patientName,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        if (email != null && email.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            email,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColor.fromInt(0xFF1F6F8B),
            ),
          ),
        ],
        pw.SizedBox(height: 4),
        pw.Text(
          'Care group: $groupName',
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColor.fromInt(0xFF455A64),
          ),
        ),
        pw.Text(
          'Observation window: ${_fmtDate(periodStart)} ? ${_fmtDate(periodEnd)} ($days days)',
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

  pw.Widget _metricTable(List<List<_Metric>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColor.fromInt(0xFFCFD8DC),
        width: 0.45,
      ),
      children: rows
          .map(
            (row) => pw.TableRow(
              children: row
                  .map(
                    (m) => pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            m.label,
                            style: pw.TextStyle(
                              fontSize: 7.5,
                              color: PdfColor.fromInt(0xFF607D8B),
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.RichText(
                            text: pw.TextSpan(
                              children: [
                                pw.TextSpan(
                                  text: m.value,
                                  style: pw.TextStyle(
                                    fontSize: 13,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColor.fromInt(0xFF263238),
                                  ),
                                ),
                                pw.TextSpan(
                                  text: ' ${m.hint}',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    color: PdfColor.fromInt(0xFF78909C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );
  }

  pw.Widget _combinedDayTable(
    List<_DayRow> rows, {
    required bool includeMood,
    required bool includeAffect,
    required bool includeUrge,
    required bool includeAdherence,
  }) {
    if (rows.isEmpty) {
      return pw.Text(
        'No diary or medication observations in this window.',
        style: const pw.TextStyle(fontSize: 8),
      );
    }

    final headers = <String>['Date'];
    if (includeMood) headers.add('Mood');
    if (includeAffect) headers.add('Affect');
    if (includeUrge) headers.add('Urge');
    if (includeAdherence) headers.addAll(['Adh %', 'Taken', 'Missed']);

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows.map((r) {
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
            r.adherencePct == null ? '-' : r.adherencePct!.toStringAsFixed(0),
          );
          row.add(r.taken + r.missed == 0 ? '-' : '${r.taken}');
          row.add(r.taken + r.missed == 0 ? '-' : '${r.missed}');
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
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.centerLeft,
      border: pw.TableBorder.all(
        color: PdfColor.fromInt(0xFFCFD8DC),
        width: 0.35,
      ),
    );
  }

  pw.Widget _seriesChart({
    required String title,
    required List<_DayRow> days,
    required double Function(_DayRow) valueOf,
    required PdfColor color,
    required double maxY,
  }) {
    if (days.length < 2) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColor.fromInt(0xFFCFD8DC)),
        ),
        child: pw.Text(
          days.isEmpty
              ? '$title ? no data points.'
              : '$title ? need at least 2 points to chart '
                  '(have ${days.first.label}: ${valueOf(days.first).toStringAsFixed(1)}).',
          style: const pw.TextStyle(fontSize: 8),
        ),
      );
    }

    final labels = days.map((d) => d.label).toList();
    final values = days.map(valueOf).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.SizedBox(
          height: 110,
          child: pw.Chart(
            grid: pw.CartesianGrid(
              xAxis: pw.FixedAxis.fromStrings(
                labels,
                marginStart: 4,
                marginEnd: 4,
              ),
              yAxis: pw.FixedAxis(
                [
                  0,
                  maxY / 4,
                  maxY / 2,
                  maxY * 3 / 4,
                  maxY,
                ],
                divisions: true,
              ),
            ),
            datasets: [
              pw.LineDataSet(
                drawPoints: true,
                color: color,
                data: [
                  for (var i = 0; i < values.length; i++)
                    pw.PointChartValue(i.toDouble(), values[i]),
                ],
              ),
            ],
          ),
        ),
      ],
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
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColor.fromInt(0xFFCFD8DC),
          width: 0.45,
        ),
        color: PdfColor.fromInt(0xFFFBFCFC),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _fmtDateTime(e.createdAt),
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'Mood ${e.mood}/10 ? Affect ${e.affectIntensity}/10 ? '
            'Urge NSSI ${e.urgeNssi}/10 ? Substance ${e.urgeSubstance}/10',
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.Text(
            'Emotions: ${e.emotions.isEmpty ? '-' : e.emotions.join(', ')}',
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.Text(
            'Triggers: ${e.triggers.isEmpty ? '-' : e.triggers.join(', ')}',
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.Text(
            'Skills: ${e.skills.isEmpty ? '-' : e.skills.join(', ')}',
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.Text(
            'Notes: ${e.notes.trim().isEmpty ? '-' : e.notes.trim()}',
            style: const pw.TextStyle(fontSize: 8, lineSpacing: 1.25),
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

  bool get hasObservation =>
      mood != null ||
      affect != null ||
      urge != null ||
      adherencePct != null ||
      taken > 0 ||
      missed > 0;
}
