import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/api_config.dart';

enum MedDoseStatus { due, taken, missed }

class LinkedPatient {
  const LinkedPatient({
    required this.patientId,
    required this.patientName,
    required this.monitoringOn,
    this.groupCode,
    this.groupName,
  });

  final String patientId;
  final String patientName;
  final bool monitoringOn;
  final String? groupCode;
  final String? groupName;

  factory LinkedPatient.fromJson(Map<String, dynamic> json) {
    return LinkedPatient(
      patientId: (json['patient_id'] ?? '').toString(),
      patientName: (json['patient_name'] ?? 'Patient').toString(),
      monitoringOn: json['monitoring_on'] == true,
      groupCode: json['group_code']?.toString(),
      groupName: json['group_name']?.toString(),
    );
  }
}

class MedicationModel {
  const MedicationModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.psychiatristId,
    required this.name,
    required this.dosageAndFreq,
    required this.isActive,
    required this.createdAt,
    required this.todayStatus,
    this.todayLoggedAt,
  });

  final String id;
  final String patientId;
  final String patientName;
  final String psychiatristId;
  final String name;
  final String dosageAndFreq;
  final bool isActive;
  final DateTime createdAt;
  final MedDoseStatus todayStatus;
  final DateTime? todayLoggedAt;

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    final raw = (json['today_status'] ?? '').toString().toUpperCase();
    final status = switch (raw) {
      'TAKEN' => MedDoseStatus.taken,
      'MISSED' => MedDoseStatus.missed,
      _ => MedDoseStatus.due,
    };
    return MedicationModel(
      id: (json['id'] ?? '').toString(),
      patientId: (json['patient_id'] ?? '').toString(),
      patientName: (json['patient_name'] ?? 'Patient').toString(),
      psychiatristId: (json['psychiatrist_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      dosageAndFreq: (json['dosage_and_freq'] ?? '').toString(),
      isActive: json['is_active'] != false,
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
      todayStatus: status,
      todayLoggedAt: DateTime.tryParse(
        (json['today_logged_at'] ?? '').toString(),
      ),
    );
  }
}

class MedDayStats {
  const MedDayStats({
    required this.active,
    required this.due,
    required this.taken,
    required this.missed,
    required this.adherencePct,
  });

  final int active;
  final int due;
  final int taken;
  final int missed;
  final int adherencePct;
}

class MedDayBreakdown {
  const MedDayBreakdown({
    required this.dayKey,
    required this.taken,
    required this.missed,
  });

  final String dayKey;
  final int taken;
  final int missed;

  factory MedDayBreakdown.fromJson(Map<String, dynamic> json) {
    return MedDayBreakdown(
      dayKey: (json['day_key'] ?? '').toString(),
      taken: (json['taken'] as num?)?.toInt() ?? 0,
      missed: (json['missed'] as num?)?.toInt() ?? 0,
    );
  }
}

class MedPeriodStats {
  const MedPeriodStats({
    required this.days,
    required this.activeMeds,
    required this.taken,
    required this.missed,
    required this.logged,
    required this.adherencePct,
    this.byDay = const [],
  });

  final int days;
  final int activeMeds;
  final int taken;
  final int missed;
  final int logged;
  final int adherencePct;
  final List<MedDayBreakdown> byDay;

  factory MedPeriodStats.fromJson(Map<String, dynamic> json) {
    return MedPeriodStats(
      days: (json['days'] as num?)?.toInt() ?? 7,
      activeMeds: (json['active_meds'] as num?)?.toInt() ?? 0,
      taken: (json['taken'] as num?)?.toInt() ?? 0,
      missed: (json['missed'] as num?)?.toInt() ?? 0,
      logged: (json['logged'] as num?)?.toInt() ?? 0,
      adherencePct: (json['adherence_pct'] as num?)?.toInt() ?? 0,
      byDay: ((json['by_day'] as List?) ?? const [])
          .map((e) => MedDayBreakdown.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class PatientMedsBundle {
  const PatientMedsBundle({
    required this.medications,
    required this.today,
    required this.period,
    required this.linked,
    this.clinicianName,
    this.groupName,
  });

  final List<MedicationModel> medications;
  final MedDayStats today;
  final MedPeriodStats period;
  final bool linked;
  final String? clinicianName;
  final String? groupName;
}

class MedicationFailure implements Exception {
  MedicationFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class MedicationService {
  MedicationService._();
  static final MedicationService instance = MedicationService._();

  String? get _uid => Supabase.instance.client.auth.currentUser?.id;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on MedicationFailure {
      rethrow;
    } catch (_) {
      throw MedicationFailure(
        'Cannot reach medication service at ${ApiConfig.baseUrl}.',
      );
    }
  }

  Map<String, dynamic> _decode(http.Response res) {
    final body = jsonDecode(res.body);
    if (body is Map<String, dynamic>) return body;
    return <String, dynamic>{};
  }

  Future<MedPeriodStats> loadMyStats({int days = 7}) async {
    final uid = _uid;
    if (uid == null) throw MedicationFailure('Sign in required.');

    return _guard(() async {
      final res = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/meds/patient/$uid/stats?days=$days',
            ),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        final body = _decode(res);
        throw MedicationFailure(
          (body['error'] ?? 'Failed to load medication stats.').toString(),
        );
      }
      return MedPeriodStats.fromJson(_decode(res));
    });
  }

  Future<PatientMedsBundle> loadMyMeds() async {
    final uid = _uid;
    if (uid == null) throw MedicationFailure('Sign in required.');

    return _guard(() async {
      final todayRes = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/meds/patient/$uid'))
          .timeout(const Duration(seconds: 8));
      if (todayRes.statusCode != 200) {
        final body = _decode(todayRes);
        throw MedicationFailure(
          (body['error'] ?? 'Failed to load medications.').toString(),
        );
      }
      final todayBody = _decode(todayRes);
      final stats = Map<String, dynamic>.from(
        (todayBody['stats'] as Map?) ?? const {},
      );
      final meds = ((todayBody['medications'] as List?) ?? const [])
          .map((e) => MedicationModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      MedPeriodStats period = const MedPeriodStats(
        days: 7,
        activeMeds: 0,
        taken: 0,
        missed: 0,
        logged: 0,
        adherencePct: 0,
      );
      try {
        period = await loadMyStats(days: 7);
      } catch (_) {}

      return PatientMedsBundle(
        medications: meds,
        today: MedDayStats(
          active: (stats['active'] as num?)?.toInt() ?? meds.length,
          due: (stats['due'] as num?)?.toInt() ?? 0,
          taken: (stats['taken'] as num?)?.toInt() ?? 0,
          missed: (stats['missed'] as num?)?.toInt() ?? 0,
          adherencePct: (stats['adherence_pct'] as num?)?.toInt() ?? 0,
        ),
        period: period,
        linked: todayBody['linked'] == true,
        clinicianName: todayBody['clinician_name']?.toString(),
        groupName: todayBody['group_name']?.toString(),
      );
    });
  }

  Future<MedicationModel> markTaken(String medId) =>
      _log(medId, status: 'TAKEN');

  Future<MedicationModel> markMissed(String medId) =>
      _log(medId, status: 'MISSED');

  Future<MedicationModel> _log(String medId, {required String status}) async {
    final uid = _uid;
    if (uid == null) throw MedicationFailure('Sign in required.');

    return _guard(() async {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/meds/$medId/log'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'patient_id': uid, 'status': status}),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        final body = _decode(res);
        throw MedicationFailure(
          (body['error'] ?? 'Failed to log medication.').toString(),
        );
      }
      final body = _decode(res);
      return MedicationModel.fromJson(
        Map<String, dynamic>.from(body['medication'] as Map),
      );
    });
  }

  Future<MedicationModel> clearTodayLog(String medId) async {
    final uid = _uid;
    if (uid == null) throw MedicationFailure('Sign in required.');

    return _guard(() async {
      final res = await http
          .delete(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/meds/$medId/log?patient_id=$uid',
            ),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        final body = _decode(res);
        throw MedicationFailure(
          (body['error'] ?? 'Failed to clear medication log.').toString(),
        );
      }
      final body = _decode(res);
      return MedicationModel.fromJson(
        Map<String, dynamic>.from(body['medication'] as Map),
      );
    });
  }

  Future<List<LinkedPatient>> loadLinkedPatients() async {
    final uid = _uid;
    if (uid == null) throw MedicationFailure('Sign in required.');

    return _guard(() async {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/meds/clinician/$uid/patients'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        final body = _decode(res);
        throw MedicationFailure(
          (body['error'] ?? 'Failed to load linked patients.').toString(),
        );
      }
      final body = _decode(res);
      return ((body['patients'] as List?) ?? const [])
          .map((e) => LinkedPatient.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    });
  }

  Future<List<MedicationModel>> loadClinicianMeds() async {
    final uid = _uid;
    if (uid == null) throw MedicationFailure('Sign in required.');

    return _guard(() async {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/meds/clinician/$uid'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        final body = _decode(res);
        throw MedicationFailure(
          (body['error'] ?? 'Failed to load prescriptions.').toString(),
        );
      }
      final body = _decode(res);
      return ((body['medications'] as List?) ?? const [])
          .map((e) => MedicationModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    });
  }

  Future<MedicationModel> prescribe({
    required String patientId,
    required String patientName,
    required String name,
    required String dosageAndFreq,
  }) async {
    final uid = _uid;
    if (uid == null) throw MedicationFailure('Sign in required.');

    return _guard(() async {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/meds'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'psychiatrist_id': uid,
              'patient_id': patientId,
              'patient_name': patientName,
              'name': name,
              'dosage_and_freq': dosageAndFreq,
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 201 && res.statusCode != 200) {
        final body = _decode(res);
        throw MedicationFailure(
          (body['error'] ?? 'Failed to prescribe medication.').toString(),
        );
      }
      final body = _decode(res);
      return MedicationModel.fromJson(
        Map<String, dynamic>.from(body['medication'] as Map),
      );
    });
  }

  Future<MedicationModel> updateMedication({
    required String medId,
    String? name,
    String? dosageAndFreq,
    bool? isActive,
  }) async {
    return _guard(() async {
      final res = await http
          .patch(
            Uri.parse('${ApiConfig.baseUrl}/api/meds/$medId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              if (name != null) 'name': name,
              if (dosageAndFreq != null) 'dosage_and_freq': dosageAndFreq,
              if (isActive != null) 'is_active': isActive,
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        final body = _decode(res);
        throw MedicationFailure(
          (body['error'] ?? 'Failed to update medication.').toString(),
        );
      }
      final body = _decode(res);
      return MedicationModel.fromJson(
        Map<String, dynamic>.from(body['medication'] as Map),
      );
    });
  }
}
