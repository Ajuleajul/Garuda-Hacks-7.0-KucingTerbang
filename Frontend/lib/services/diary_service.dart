import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/api_config.dart';

enum DiaryEntryKind { dbtCard, coping }

class DiaryEntryModel {
  const DiaryEntryModel({
    required this.id,
    required this.kind,
    required this.createdAt,
    required this.mood,
    required this.affectIntensity,
    required this.urgeNssi,
    required this.urgeSubstance,
    required this.emotions,
    required this.triggers,
    required this.skills,
    required this.notes,
    required this.situation,
    required this.thoughts,
    required this.behavior,
    required this.outcome,
  });

  final String id;
  final DiaryEntryKind kind;
  final DateTime createdAt;
  final int mood;
  final int affectIntensity;
  final int urgeNssi;
  final int urgeSubstance;
  final List<String> emotions;
  final List<String> triggers;
  final List<String> skills;
  final String notes;
  final String situation;
  final String thoughts;
  final String behavior;
  final String outcome;

  factory DiaryEntryModel.fromJson(Map<String, dynamic> json) {
    return DiaryEntryModel(
      id: (json['id'] ?? '').toString(),
      kind: (json['kind'] ?? '').toString().toUpperCase() == 'COPING'
          ? DiaryEntryKind.coping
          : DiaryEntryKind.dbtCard,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
      mood: (json['mood'] as num?)?.toInt() ?? 0,
      affectIntensity: (json['affect_intensity'] as num?)?.toInt() ?? 0,
      urgeNssi: (json['urge_nssi'] as num?)?.toInt() ?? 0,
      urgeSubstance: (json['urge_substance'] as num?)?.toInt() ?? 0,
      emotions: ((json['emotions'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      triggers: ((json['triggers'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      skills: ((json['skills'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      notes: (json['notes'] ?? '').toString(),
      situation: (json['situation'] ?? '').toString(),
      thoughts: (json['thoughts'] ?? '').toString(),
      behavior: (json['behavior'] ?? '').toString(),
      outcome: (json['outcome'] ?? '').toString(),
    );
  }
}

class DiaryFailure implements Exception {
  DiaryFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class DiaryService {
  DiaryService._();
  static final DiaryService instance = DiaryService._();

  String? get _uid => Supabase.instance.client.auth.currentUser?.id;

  Future<List<DiaryEntryModel>> loadMyEntries() async {
    final uid = _uid;
    if (uid == null) throw DiaryFailure('Sign in required.');

    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/diary/patient/$uid'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        throw DiaryFailure(
          (body['error'] ?? 'Failed to load diary entries.').toString(),
        );
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return ((body['entries'] as List?) ?? const [])
          .map((e) => DiaryEntryModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      if (e is DiaryFailure) rethrow;
      throw DiaryFailure(
        'Cannot reach diary service at ${ApiConfig.baseUrl}.',
      );
    }
  }

  Future<List<DiaryEntryModel>> loadClinicianPatientEntries(
    String patientId, {
    int limit = 90,
  }) async {
    final uid = _uid;
    if (uid == null) throw DiaryFailure('Sign in required.');

    try {
      final res = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/diary/clinician/$uid/patient/$patientId'
              '?limit=$limit',
            ),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        throw DiaryFailure(
          (body['error'] ?? 'Failed to load patient diary.').toString(),
        );
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return ((body['entries'] as List?) ?? const [])
          .map((e) => DiaryEntryModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      if (e is DiaryFailure) rethrow;
      throw DiaryFailure(
        'Cannot reach diary service at ${ApiConfig.baseUrl}.',
      );
    }
  }

  Future<DiaryEntryModel> saveDbtCard({
    required int mood,
    required int affectIntensity,
    required int urgeNssi,
    required int urgeSubstance,
    required List<String> emotions,
    required List<String> triggers,
    required List<String> skills,
    required String notes,
  }) async {
    return _saveEntry({
      'kind': 'DBT_CARD',
      'mood': mood,
      'affect_intensity': affectIntensity,
      'urge_nssi': urgeNssi,
      'urge_substance': urgeSubstance,
      'emotions': emotions,
      'triggers': triggers,
      'skills': skills,
      'notes': notes,
    });
  }

  Future<DiaryEntryModel> saveCoping({
    required String situation,
    required String thoughts,
    required String behavior,
    required String outcome,
  }) async {
    return _saveEntry({
      'kind': 'COPING',
      'situation': situation,
      'thoughts': thoughts,
      'behavior': behavior,
      'outcome': outcome,
    });
  }

  Future<DiaryEntryModel> _saveEntry(Map<String, dynamic> payload) async {
    final uid = _uid;
    if (uid == null) throw DiaryFailure('Sign in required.');

    try {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/diary'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'patient_id': uid, ...payload}),
          )
          .timeout(const Duration(seconds: 8));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 201 && res.statusCode != 200) {
        throw DiaryFailure(
          (body['error'] ?? 'Failed to save diary entry.').toString(),
        );
      }
      return DiaryEntryModel.fromJson(
        Map<String, dynamic>.from(body['entry'] as Map),
      );
    } catch (e) {
      if (e is DiaryFailure) rethrow;
      throw DiaryFailure(
        'Cannot reach diary service at ${ApiConfig.baseUrl}.',
      );
    }
  }
}
