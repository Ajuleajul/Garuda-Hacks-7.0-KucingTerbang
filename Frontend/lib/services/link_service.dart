import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/api_config.dart';

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

String _asString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString();
}

class JoinGroup {
  const JoinGroup({
    required this.id,
    required this.code,
    required this.name,
    required this.psychiatristId,
    required this.isActive,
    required this.memberCount,
    required this.createdAt,
    this.expiresAt,
    this.psychiatristName,
    this.psychiatristEmail,
    this.membersPreview = const [],
  });

  final String id;
  final String code;
  final String name;
  final String psychiatristId;
  final String? psychiatristName;
  final String? psychiatristEmail;
  final bool isActive;
  final int memberCount;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final List<GroupMemberPreview> membersPreview;

  bool get isExpired =>
      expiresAt != null && !expiresAt!.isAfter(DateTime.now());

  bool get canJoin => isActive && !isExpired;

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'psychiatrist_id': psychiatristId,
        'psychiatrist_name': psychiatristName,
        'psychiatrist_email': psychiatristEmail,
        'is_active': isActive,
        'member_count': memberCount,
        'created_at': createdAt.toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
        'members_preview': membersPreview.map((m) => m.toJson()).toList(),
      };

  factory JoinGroup.fromJson(Map<String, dynamic> json) {
    final previewRaw = json['members_preview'] as List? ?? const [];
    return JoinGroup(
      id: _asString(json['id']),
      code: _asString(json['code']).toUpperCase(),
      name: _asString(json['name'], 'Care group'),
      psychiatristId: _asString(json['psychiatrist_id']),
      psychiatristName: json['psychiatrist_name']?.toString(),
      psychiatristEmail: json['psychiatrist_email']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      expiresAt: _parseDate(json['expires_at']),
      membersPreview: previewRaw
          .map(
            (e) => GroupMemberPreview.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }

  JoinGroup copyWith({
    bool? isActive,
    int? memberCount,
    String? name,
    String? code,
    DateTime? expiresAt,
    bool clearExpiresAt = false,
    List<GroupMemberPreview>? membersPreview,
  }) {
    return JoinGroup(
      id: id,
      code: code ?? this.code,
      name: name ?? this.name,
      psychiatristId: psychiatristId,
      psychiatristName: psychiatristName,
      psychiatristEmail: psychiatristEmail,
      isActive: isActive ?? this.isActive,
      memberCount: memberCount ?? this.memberCount,
      createdAt: createdAt,
      expiresAt: clearExpiresAt ? null : (expiresAt ?? this.expiresAt),
      membersPreview: membersPreview ?? this.membersPreview,
    );
  }
}

class GroupMemberPreview {
  const GroupMemberPreview({
    required this.patientId,
    required this.patientName,
  });

  final String patientId;
  final String patientName;

  Map<String, dynamic> toJson() => {
        'patient_id': patientId,
        'patient_name': patientName,
      };

  factory GroupMemberPreview.fromJson(Map<String, dynamic> json) {
    return GroupMemberPreview(
      patientId: _asString(json['patient_id']),
      patientName: _asString(json['patient_name'], 'Patient'),
    );
  }
}

class GroupMember {
  const GroupMember({
    required this.linkId,
    required this.patientId,
    required this.patientName,
    required this.monitoringOn,
    required this.status,
    required this.linkedAt,
    required this.diaryEntries,
    required this.activeMedsCount,
    required this.medications,
    this.email,
  });

  final String linkId;
  final String patientId;
  final String patientName;
  final String? email;
  final bool monitoringOn;
  final String status;
  final DateTime linkedAt;
  final int diaryEntries;
  final int activeMedsCount;
  final List<GroupMemberMed> medications;

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    final medsRaw = json['medications'] as List? ?? const [];
    return GroupMember(
      linkId: _asString(json['link_id']),
      patientId: _asString(json['patient_id']),
      patientName: _asString(json['patient_name'], 'Patient'),
      email: json['email']?.toString(),
      monitoringOn: json['monitoring_on'] == true,
      status: _asString(json['status'], 'ACTIVE'),
      linkedAt: _parseDate(json['linked_at']) ?? DateTime.now(),
      diaryEntries: (json['diary_entries'] as num?)?.toInt() ?? 0,
      activeMedsCount: (json['active_meds_count'] as num?)?.toInt() ?? 0,
      medications: medsRaw
          .map(
            (e) => GroupMemberMed.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }

  GroupMember copyWith({bool? monitoringOn}) {
    return GroupMember(
      linkId: linkId,
      patientId: patientId,
      patientName: patientName,
      email: email,
      monitoringOn: monitoringOn ?? this.monitoringOn,
      status: status,
      linkedAt: linkedAt,
      diaryEntries: diaryEntries,
      activeMedsCount: activeMedsCount,
      medications: medications,
    );
  }
}

class GroupMemberMed {
  const GroupMemberMed({
    required this.id,
    required this.name,
    required this.dosageAndFreq,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String dosageAndFreq;
  final bool isActive;
  final DateTime createdAt;

  factory GroupMemberMed.fromJson(Map<String, dynamic> json) {
    return GroupMemberMed(
      id: _asString(json['id']),
      name: _asString(json['name']),
      dosageAndFreq: _asString(json['dosage_and_freq']),
      isActive: json['is_active'] != false,
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
    );
  }
}

class PatientCareLink {
  const PatientCareLink({
    required this.id,
    required this.patientId,
    required this.psychiatristId,
    required this.groupCode,
    required this.groupName,
    required this.clinicianName,
    required this.clinicianEmail,
    required this.monitoringOn,
    required this.linkedAt,
  });

  final String id;
  final String patientId;
  final String psychiatristId;
  final String groupCode;
  final String groupName;
  final String clinicianName;
  final String clinicianEmail;
  final bool monitoringOn;
  final DateTime linkedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'psychiatrist_id': psychiatristId,
        'group_code': groupCode,
        'group_name': groupName,
        'clinician_name': clinicianName,
        'clinician_email': clinicianEmail,
        'monitoring_on': monitoringOn,
        'linked_at': linkedAt.toIso8601String(),
      };

  factory PatientCareLink.fromJson(Map<String, dynamic> json) {
    final psych = json['psychiatrist'];
    final psychMap = psych is Map ? Map<String, dynamic>.from(psych) : null;
    return PatientCareLink(
      id: _asString(json['id']),
      patientId: _asString(json['patient_id']),
      psychiatristId: _asString(
        json['psychiatrist_id'] ?? psychMap?['id'],
      ),
      groupCode: _asString(json['group_code']).toUpperCase(),
      groupName: _asString(json['group_name'], 'Care group'),
      clinicianName: _asString(
        json['clinician_name'] ?? psychMap?['full_name'],
        'Clinician',
      ),
      clinicianEmail: _asString(
        json['clinician_email'] ?? psychMap?['email'],
      ),
      monitoringOn: json['monitoring_on'] as bool? ?? true,
      linkedAt: _parseDate(json['linked_at']) ?? DateTime.now(),
    );
  }

  PatientCareLink copyWith({bool? monitoringOn}) {
    return PatientCareLink(
      id: id,
      patientId: patientId,
      psychiatristId: psychiatristId,
      groupCode: groupCode,
      groupName: groupName,
      clinicianName: clinicianName,
      clinicianEmail: clinicianEmail,
      monitoringOn: monitoringOn ?? this.monitoringOn,
      linkedAt: linkedAt,
    );
  }
}

class LinkFailure implements Exception {
  LinkFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class CreateGroupResult {
  const CreateGroupResult({
    required this.group,
    required this.syncedToServer,
  });
  final JoinGroup group;
  final bool syncedToServer;
}

class LinkService {
  LinkService._();
  static final LinkService instance = LinkService._();

  static const _storeKey = 'curamind_care_link_store_v1';

  String? get _uid => Supabase.instance.client.auth.currentUser?.id;

  User? get _user => Supabase.instance.client.auth.currentUser;

  String get _displayName {
    final meta = _user?.userMetadata ?? {};
    final name = meta['full_name'] as String?;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    return _user?.email ?? 'User';
  }

  String get _email => _user?.email ?? '';

  Future<Map<String, dynamic>> _readStore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storeKey);
    if (raw == null || raw.isEmpty) {
      return {'groups': <dynamic>[], 'links': <String, dynamic>{}};
    }
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> _writeStore(Map<String, dynamic> store) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storeKey, jsonEncode(store));
  }

  String _newCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = DateTime.now().microsecondsSinceEpoch;
    final a = chars[r % chars.length];
    final b = chars[(r ~/ 7) % chars.length];
    final c = chars[(r ~/ 13) % chars.length];
    final d = chars[(r ~/ 29) % chars.length];
    final e = chars[(r ~/ 37) % chars.length];
    final f = chars[(r ~/ 41) % chars.length];
    return 'CURA-$a$b$c$d$e$f';
  }

  Future<void> _upsertLocalGroup(JoinGroup group) async {
    final store = await _readStore();
    final groups = (store['groups'] as List? ?? [])
        .map((e) => JoinGroup.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final i =
        groups.indexWhere((g) => g.id == group.id || g.code == group.code);
    if (i >= 0) {
      groups[i] = group;
    } else {
      groups.insert(0, group);
    }
    store['groups'] = groups.map((g) => g.toJson()).toList();
    await _writeStore(store);
  }

  Future<void> _saveLocalPatientLink(PatientCareLink link) async {
    final store = await _readStore();
    final links = Map<String, dynamic>.from(store['links'] as Map? ?? {});
    links[link.patientId] = link.toJson();
    store['links'] = links;
    await _writeStore(store);
  }

  Future<bool> pingHealth() async {
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/health'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<CreateGroupResult> createGroup({
    String? name,
    int? expiresInMinutes,
    bool allowOffline = true,
  }) async {
    final uid = _uid;
    if (uid == null) throw LinkFailure('Sign in required.');

    DateTime? expiresAt;
    if (expiresInMinutes != null && expiresInMinutes > 0) {
      expiresAt = DateTime.now().add(Duration(minutes: expiresInMinutes));
    }

    Object? lastError;
    try {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/link/groups'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'psychiatrist_id': uid,
              'psychiatrist_name': _displayName,
              'psychiatrist_email': _email,
              'name': name?.trim().isNotEmpty == true
                  ? name!.trim()
                  : 'Care group',
              'expires_in_minutes': expiresInMinutes,
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 201 || res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final group = JoinGroup.fromJson(
          Map<String, dynamic>.from(body['group'] as Map),
        );
        await _upsertLocalGroup(group);
        return CreateGroupResult(group: group, syncedToServer: true);
      }
      lastError = 'HTTP ${res.statusCode}: ${res.body}';
    } catch (e) {
      lastError = e;
    }

    if (!allowOffline) {
      throw LinkFailure(
        'Cannot reach Backend at ${ApiConfig.baseUrl}. '
        'Start the API, then for a physical phone set API_BASE_URL '
        'in Frontend/.env to your PC LAN IP (e.g. http://192.168.0.5:3000). '
        '($lastError)',
      );
    }

    final store = await _readStore();
    final groups = (store['groups'] as List? ?? [])
        .map((e) => JoinGroup.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    var code = _newCode();
    while (groups.any((g) => g.code == code)) {
      code = _newCode();
    }

    final group = JoinGroup(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      code: code,
      name: (name?.trim().isNotEmpty == true) ? name!.trim() : 'Care group',
      psychiatristId: uid,
      psychiatristName: _displayName,
      psychiatristEmail: _email,
      isActive: true,
      memberCount: 0,
      createdAt: DateTime.now(),
      expiresAt: expiresAt,
    );
    groups.insert(0, group);
    store['groups'] = groups.map((g) => g.toJson()).toList();
    await _writeStore(store);
    return CreateGroupResult(group: group, syncedToServer: false);
  }

  Future<List<JoinGroup>> listMyGroups() async {
    final uid = _uid;
    if (uid == null) return [];

    final store = await _readStore();
    final existing = (store['groups'] as List? ?? [])
        .map((e) => JoinGroup.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final localMine =
        existing.where((g) => g.psychiatristId == uid).toList();

    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/link/groups/$uid'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final remote = (body['groups'] as List? ?? [])
            .map((e) => JoinGroup.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        final others =
            existing.where((g) => g.psychiatristId != uid).toList();
        store['groups'] = [...remote, ...others].map((g) => g.toJson()).toList();
        await _writeStore(store);
        return remote;
      }
    } catch (_) {}

    return localMine.where((g) => !g.id.startsWith('local-')).toList();
  }

  Future<List<GroupMember>> listGroupMembers(String groupId) async {
    final uid = _uid;
    if (uid == null) throw LinkFailure('Sign in required.');

    if (groupId.startsWith('local-')) return const [];

    try {
      final res = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/link/groups/$groupId/members'
              '?psychiatrist_id=$uid',
            ),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final members = (body['members'] as List? ?? [])
            .map(
              (e) => GroupMember.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
        return members;
      }
      if (res.statusCode == 404) return const [];
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw LinkFailure(
        (body['error'] as String?) ?? 'Failed to load members.',
      );
    } on LinkFailure {
      rethrow;
    } catch (_) {
      throw LinkFailure(
        'Cannot reach Backend at ${ApiConfig.baseUrl} to load members.',
      );
    }
  }

  Future<JoinGroup> setGroupActive(String groupId, bool active) async {
    final store = await _readStore();
    final groups = (store['groups'] as List? ?? [])
        .map((e) => JoinGroup.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final i = groups.indexWhere((g) => g.id == groupId);
    if (i < 0) throw LinkFailure('Group not found.');

    groups[i] = groups[i].copyWith(isActive: active);
    store['groups'] = groups.map((g) => g.toJson()).toList();
    await _writeStore(store);
    final local = groups[i];

    if (!groupId.startsWith('local-')) {
      try {
        final res = await http
            .patch(
              Uri.parse('${ApiConfig.baseUrl}/api/link/groups/$groupId'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'is_active': active,
                'psychiatrist_id': _uid,
              }),
            )
            .timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body) as Map<String, dynamic>;
          final remote = JoinGroup.fromJson(
            Map<String, dynamic>.from(body['group'] as Map),
          );
          await _upsertLocalGroup(remote);
          return remote;
        }
      } catch (_) {}
    }

    return local;
  }

  Future<JoinGroup> renameGroup(String groupId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw LinkFailure('Group name is required.');

    final store = await _readStore();
    final groups = (store['groups'] as List? ?? [])
        .map((e) => JoinGroup.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final i = groups.indexWhere((g) => g.id == groupId);
    if (i < 0) throw LinkFailure('Group not found.');

    groups[i] = groups[i].copyWith(
      name: trimmed.length > 80 ? trimmed.substring(0, 80) : trimmed,
    );
    store['groups'] = groups.map((g) => g.toJson()).toList();
    await _writeStore(store);
    final local = groups[i];

    if (groupId.startsWith('local-')) return local;

    try {
      final res = await http
          .patch(
            Uri.parse('${ApiConfig.baseUrl}/api/link/groups/$groupId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': trimmed,
              'psychiatrist_id': _uid,
            }),
          )
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final remote = JoinGroup.fromJson(
          Map<String, dynamic>.from(body['group'] as Map),
        );
        await _upsertLocalGroup(remote);
        return remote;
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw LinkFailure(
        (body['error'] as String?) ?? 'Failed to rename group.',
      );
    } on LinkFailure {
      rethrow;
    } catch (_) {
      throw LinkFailure(
        'Cannot reach Backend at ${ApiConfig.baseUrl} to rename group.',
      );
    }
  }

  Future<JoinGroup> regenerateGroupCode({
    required String groupId,
    int? expiresInMinutes,
  }) async {
    final uid = _uid;
    if (uid == null) throw LinkFailure('Sign in required.');

    DateTime? expiresAt;
    if (expiresInMinutes != null && expiresInMinutes > 0) {
      expiresAt = DateTime.now().add(Duration(minutes: expiresInMinutes));
    }

    if (groupId.startsWith('local-')) {
      final store = await _readStore();
      final groups = (store['groups'] as List? ?? [])
          .map((e) => JoinGroup.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final i = groups.indexWhere((g) => g.id == groupId);
      if (i < 0) throw LinkFailure('Group not found.');
      var code = _newCode();
      while (groups.any((g) => g.code == code && g.id != groupId)) {
        code = _newCode();
      }
      groups[i] = groups[i].copyWith(
        code: code,
        expiresAt: expiresAt,
        isActive: true,
        clearExpiresAt: expiresInMinutes == null || expiresInMinutes <= 0,
      );
      store['groups'] = groups.map((g) => g.toJson()).toList();
      await _writeStore(store);
      return groups[i];
    }

    try {
      final res = await http
          .post(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/link/groups/$groupId/regenerate',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'psychiatrist_id': uid,
              'expires_in_minutes': expiresInMinutes,
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final remote = JoinGroup.fromJson(
          Map<String, dynamic>.from(body['group'] as Map),
        );
        await _upsertLocalGroup(remote);
        return remote;
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw LinkFailure(
        (body['error'] as String?) ?? 'Failed to regenerate code.',
      );
    } on LinkFailure {
      rethrow;
    } catch (_) {
      throw LinkFailure(
        'Cannot reach Backend at ${ApiConfig.baseUrl} to regenerate code.',
      );
    }
  }

  Future<void> deleteGroup(String groupId) async {
    final uid = _uid;
    if (uid == null) throw LinkFailure('Sign in required.');

    if (!groupId.startsWith('local-')) {
      try {
        final res = await http
            .delete(
              Uri.parse(
                '${ApiConfig.baseUrl}/api/link/groups/$groupId?psychiatrist_id=$uid',
              ),
            )
            .timeout(const Duration(seconds: 8));
        if (res.statusCode != 200 && res.statusCode != 404) {
          final body = jsonDecode(res.body) as Map<String, dynamic>;
          throw LinkFailure(
            (body['error'] as String?) ?? 'Failed to delete join code.',
          );
        }
      } on LinkFailure {
        rethrow;
      } catch (_) {
        throw LinkFailure(
          'Cannot reach Backend at ${ApiConfig.baseUrl} to delete join code.',
        );
      }
    }

    final store = await _readStore();
    final groups = (store['groups'] as List? ?? [])
        .map((e) => JoinGroup.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final i = groups.indexWhere((g) => g.id == groupId);
    if (i >= 0) {
      groups.removeAt(i);
      store['groups'] = groups.map((g) => g.toJson()).toList();
      await _writeStore(store);
    }
  }

  Future<PatientCareLink?> getMyPatientLink() async {
    final uid = _uid;
    if (uid == null) return null;

    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/link/patient/$uid'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final linkJson = body['link'];
        if (linkJson != null) {
          final link = PatientCareLink.fromJson(
            Map<String, dynamic>.from(linkJson as Map)..['patient_id'] = uid,
          );
          await _saveLocalPatientLink(link);
          return link;
        }
        await _clearLocalPatientLink(uid);
        return null;
      }
    } catch (_) {}

    final store = await _readStore();
    final links = Map<String, dynamic>.from(store['links'] as Map? ?? {});
    final raw = links[uid];
    if (raw == null) return null;
    return PatientCareLink.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<void> _clearLocalPatientLink(String uid) async {
    final store = await _readStore();
    final links = Map<String, dynamic>.from(store['links'] as Map? ?? {});
    links.remove(uid);
    store['links'] = links;
    await _writeStore(store);
  }

  Future<PatientCareLink> joinWithCode(String code) async {
    final uid = _uid;
    if (uid == null) throw LinkFailure('Sign in required.');

    final upper = code.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
    if (upper.length < 4) throw LinkFailure('Enter a valid join code.');

    try {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/link/join'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'patient_id': uid,
              'patient_name': _displayName,
              'code': upper,
            }),
          )
          .timeout(const Duration(seconds: 8));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        final link = PatientCareLink.fromJson(
          Map<String, dynamic>.from(body['link'] as Map)..['patient_id'] = uid,
        );
        await _saveLocalPatientLink(link);
        return link;
      }
      if (res.statusCode == 409) {
        throw LinkFailure(
          body['error'] as String? ??
              'You are already linked to a psychiatrist. Disconnect first.',
        );
      }
      throw LinkFailure(
        (body['error'] as String?) ??
            'Invalid or inactive join code. '
                'Use a code created while Backend is online '
                '(API: ${ApiConfig.baseUrl}).',
      );
    } on LinkFailure {
      rethrow;
    } catch (_) {
      throw LinkFailure(
        'Cannot reach Backend at ${ApiConfig.baseUrl}. '
        'Start the API so Meds can sync with your care group.',
      );
    }
  }

  Future<PatientCareLink> setMonitoring(bool on, {String? patientId}) async {
    final targetId = patientId ?? _uid;
    if (targetId == null) throw LinkFailure('Sign in required.');

    try {
      final res = await http
          .patch(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/link/patient/$targetId/monitoring',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'monitoring_on': on}),
          )
          .timeout(const Duration(seconds: 8));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) {
        throw LinkFailure(
          (body['error'] as String?) ?? 'Failed to update monitoring.',
        );
      }

      final linkJson = body['link'];
      if (linkJson is! Map) {
        throw LinkFailure('Invalid monitoring response from server.');
      }

      final link = PatientCareLink.fromJson(
        Map<String, dynamic>.from(linkJson)..['patient_id'] = targetId,
      );

      if (targetId == _uid) {
        await _saveLocalPatientLink(link);
      }

      return link;
    } on LinkFailure {
      rethrow;
    } catch (_) {
      throw LinkFailure(
        'Cannot reach Backend at ${ApiConfig.baseUrl}. '
        'Start the API to update monitoring.',
      );
    }
  }

  Future<void> disconnect() async {
    final uid = _uid;
    if (uid == null) return;

    var serverOk = false;
    try {
      final res = await http
          .delete(Uri.parse('${ApiConfig.baseUrl}/api/link/patient/$uid'))
          .timeout(const Duration(seconds: 8));
      serverOk = res.statusCode == 200 || res.statusCode == 404;
    } catch (_) {}

    if (!serverOk) {
      throw LinkFailure(
        'Cannot disconnect right now. Check Backend and try again.',
      );
    }

    final store = await _readStore();
    final links = Map<String, dynamic>.from(store['links'] as Map? ?? {});
    links.remove(uid);
    store['links'] = links;
    await _writeStore(store);

    try {
      await listMyGroups();
    } catch (_) {}
  }
}
