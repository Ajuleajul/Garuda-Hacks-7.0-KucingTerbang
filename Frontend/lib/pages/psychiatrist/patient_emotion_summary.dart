import 'dart:math' as math;

import '../../services/diary_service.dart';
import '../../services/link_service.dart';

class PatientEmotionSummary {
  PatientEmotionSummary({
    required this.member,
    required this.entries,
  });

  final GroupMember member;
  final List<DiaryEntryModel> entries;

  List<DiaryEntryModel> get dbtEntries =>
      entries.where((e) => e.kind == DiaryEntryKind.dbtCard).toList();

  List<DiaryEntryModel> get recentDbt {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return dbtEntries.where((e) => e.createdAt.isAfter(cutoff)).toList();
  }

  double? get avgMood7d {
    final list = recentDbt.where((e) => e.mood > 0).map((e) => e.mood);
    if (list.isEmpty) return null;
    return list.reduce((a, b) => a + b) / list.length;
  }

  double? get avgAffect7d {
    final list = recentDbt
        .where((e) => e.affectIntensity > 0)
        .map((e) => e.affectIntensity);
    if (list.isEmpty) return null;
    return list.reduce((a, b) => a + b) / list.length;
  }

  int? get peakUrge7d {
    if (recentDbt.isEmpty) return null;
    return recentDbt
        .map((e) => math.max(e.urgeNssi, e.urgeSubstance))
        .reduce(math.max);
  }

  List<double> get moodSpark {
    final byDay = <String, List<int>>{};
    for (final e in recentDbt) {
      if (e.mood <= 0) continue;
      final d = e.createdAt.toLocal();
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      byDay.putIfAbsent(key, () => []).add(e.mood);
    }
    final keys = byDay.keys.toList()..sort();
    return keys.map((k) {
      final vals = byDay[k]!;
      return vals.reduce((a, b) => a + b) / vals.length;
    }).toList();
  }

  DateTime? get lastEntryAt =>
      entries.isEmpty ? null : entries.first.createdAt;

  bool get highUrgeAlert => (peakUrge7d ?? 0) >= 7;

  bool get lowMoodAlert {
    final m = avgMood7d;
    return m != null && m <= 3.5;
  }

  bool get inactiveAlert {
    final last = lastEntryAt;
    if (last == null) return member.diaryEntries == 0;
    return DateTime.now().difference(last).inDays >= 3;
  }

  bool get hasAlert =>
      highUrgeAlert || lowMoodAlert || (!member.monitoringOn);

  Map<String, int> get topEmotions {
    final counts = <String, int>{};
    for (final e in recentDbt) {
      for (final emotion in e.emotions) {
        final key = emotion.trim();
        if (key.isEmpty) continue;
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries.take(4));
  }
}
