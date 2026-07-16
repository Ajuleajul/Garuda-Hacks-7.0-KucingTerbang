import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'medication_service.dart';

class ReminderTime {
  const ReminderTime({required this.hour, required this.minute});

  final int hour;
  final int minute;

  String get label {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Map<String, dynamic> toJson() => {'hour': hour, 'minute': minute};

  factory ReminderTime.fromJson(Map<String, dynamic> json) {
    return ReminderTime(
      hour: (json['hour'] as num?)?.toInt().clamp(0, 23) ?? 8,
      minute: (json['minute'] as num?)?.toInt().clamp(0, 59) ?? 0,
    );
  }
}

class ReminderSettings {
  const ReminderSettings({
    required this.masterEnabled,
    required this.diaryEnabled,
    required this.diaryTime,
    required this.medsEnabled,
    required this.medTimes,
  });

  final bool masterEnabled;
  final bool diaryEnabled;
  final ReminderTime diaryTime;
  final bool medsEnabled;
  final List<ReminderTime> medTimes;

  static const defaults = ReminderSettings(
    masterEnabled: false,
    diaryEnabled: true,
    diaryTime: ReminderTime(hour: 20, minute: 0),
    medsEnabled: true,
    medTimes: [
      ReminderTime(hour: 8, minute: 0),
      ReminderTime(hour: 20, minute: 0),
    ],
  );

  ReminderSettings copyWith({
    bool? masterEnabled,
    bool? diaryEnabled,
    ReminderTime? diaryTime,
    bool? medsEnabled,
    List<ReminderTime>? medTimes,
  }) {
    return ReminderSettings(
      masterEnabled: masterEnabled ?? this.masterEnabled,
      diaryEnabled: diaryEnabled ?? this.diaryEnabled,
      diaryTime: diaryTime ?? this.diaryTime,
      medsEnabled: medsEnabled ?? this.medsEnabled,
      medTimes: medTimes ?? this.medTimes,
    );
  }

  Map<String, dynamic> toJson() => {
        'master_enabled': masterEnabled,
        'diary_enabled': diaryEnabled,
        'diary_time': diaryTime.toJson(),
        'meds_enabled': medsEnabled,
        'med_times': medTimes.map((t) => t.toJson()).toList(),
      };

  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    final times = ((json['med_times'] as List?) ?? const [])
        .map((e) => ReminderTime.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return ReminderSettings(
      masterEnabled: json['master_enabled'] == true,
      diaryEnabled: json['diary_enabled'] != false,
      diaryTime: json['diary_time'] is Map
          ? ReminderTime.fromJson(
              Map<String, dynamic>.from(json['diary_time'] as Map),
            )
          : ReminderSettings.defaults.diaryTime,
      medsEnabled: json['meds_enabled'] != false,
      medTimes: times.isEmpty ? ReminderSettings.defaults.medTimes : times,
    );
  }
}

class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  static const _prefsKey = 'curamind_reminder_settings_v1';
  static const _channelId = 'curamind_reminders';
  static const _diaryId = 1001;
  static const _medIdBase = 2000;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;
  Timer? _webTicker;
  final Set<String> _webFiredKeys = {};

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const mac = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: android,
      iOS: ios,
      macOS: mac,
    );

    await _plugin.initialize(settings: initSettings);
    _ready = true;

    final settings = await loadSettings();
    if (settings.masterEnabled) {
      await reschedule(settings);
    }
  }

  Future<ReminderSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return ReminderSettings.defaults;
    try {
      return ReminderSettings.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return ReminderSettings.defaults;
    }
  }

  Future<void> saveSettings(ReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(settings.toJson()));
    await reschedule(settings);
  }

  Future<bool> areNotificationsAllowed() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.areNotificationsEnabled() ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final opts = await ios?.checkPermissions();
      return opts?.isEnabled ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      final mac = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      final opts = await mac?.checkPermissions();
      return opts?.isEnabled ?? false;
    }
    return true;
  }

  Future<bool> requestPermission() async {
    await init();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          'Curamind reminders',
          description: 'Diary and medication reminders',
          importance: Importance.high,
        ),
      );
      return granted ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      final mac = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      return await mac?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    if (kIsWeb) {
      try {
        await _plugin.show(
          id: 0,
          title: 'Curamind',
          body: 'Notifications enabled',
          notificationDetails: const NotificationDetails(),
        );
        return true;
      } catch (_) {
        return false;
      }
    }
    return true;
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
    _webTicker?.cancel();
    _webTicker = null;
    _webFiredKeys.clear();
  }

  Future<void> reschedule(ReminderSettings settings) async {
    await init();
    await _plugin.cancelAll();
    _webTicker?.cancel();
    _webTicker = null;
    _webFiredKeys.clear();

    if (!settings.masterEnabled) return;

    final medNames = await _activeMedNames();

    if (kIsWeb) {
      _startWebStyleTicker(settings, medNames);
      return;
    }

    if (settings.diaryEnabled) {
      await _scheduleDaily(
        id: _diaryId,
        time: settings.diaryTime,
        title: 'Diary reminder',
        body: 'Take a minute to log today’s mood and skills.',
      );
    }

    if (settings.medsEnabled && medNames.isNotEmpty) {
      for (var i = 0; i < settings.medTimes.length; i++) {
        final time = settings.medTimes[i];
        await _scheduleDaily(
          id: _medIdBase + i,
          time: time,
          title: 'Medication reminder',
          body: 'Time for: ${medNames.join(', ')}',
        );
      }
    }
  }

  Future<List<String>> _activeMedNames() async {
    try {
      final bundle = await MedicationService.instance.loadMyMeds();
      return bundle.medications.map((m) => m.name).toList();
    } catch (_) {
      return const [];
    }
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Curamind reminders',
        channelDescription: 'Diary and medication reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );
  }

  Future<void> _scheduleDaily({
    required int id,
    required ReminderTime time,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    try {
      final when = _nextInstance(time);
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Schedule reminder $id failed: $e');
      }
    }
  }

  tz.TZDateTime _nextInstance(ReminderTime time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  void _startWebStyleTicker(
    ReminderSettings settings,
    List<String> medNames,
  ) {
    _webTicker = Timer.periodic(const Duration(seconds: 30), (_) async {
      final now = DateTime.now();
      final dayKey =
          '${now.year}-${now.month}-${now.day}-${now.hour}-${now.minute}';

      if (settings.diaryEnabled &&
          now.hour == settings.diaryTime.hour &&
          now.minute == settings.diaryTime.minute) {
        final key = 'diary-$dayKey';
        if (_webFiredKeys.add(key)) {
          await _showNow(
            id: _diaryId,
            title: 'Diary reminder',
            body: 'Take a minute to log today’s mood and skills.',
          );
        }
      }

      if (settings.medsEnabled && medNames.isNotEmpty) {
        for (var i = 0; i < settings.medTimes.length; i++) {
          final t = settings.medTimes[i];
          if (now.hour == t.hour && now.minute == t.minute) {
            final key = 'med-$i-$dayKey';
            if (_webFiredKeys.add(key)) {
              await _showNow(
                id: _medIdBase + i,
                title: 'Medication reminder',
                body: 'Time for: ${medNames.join(', ')}',
              );
            }
          }
        }
      }
    });
  }

  Future<void> _showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _details(),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Show notification failed: $e');
    }
  }
}
