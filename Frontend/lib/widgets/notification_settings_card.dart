import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/reminder_service.dart';
import '../theme/curamind_theme.dart';

class NotificationSettingsCard extends StatefulWidget {
  const NotificationSettingsCard({super.key});

  @override
  State<NotificationSettingsCard> createState() =>
      _NotificationSettingsCardState();
}

class _NotificationSettingsCardState extends State<NotificationSettingsCard> {
  ReminderSettings _settings = ReminderSettings.defaults;
  bool _loading = true;
  bool _busy = false;
  bool? _permissionGranted;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await ReminderService.instance.loadSettings();
    final allowed = await ReminderService.instance.areNotificationsAllowed();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _permissionGranted = allowed;
      _loading = false;
    });
  }

  Future<void> _persist(ReminderSettings next) async {
    setState(() {
      _settings = next;
      _busy = true;
    });
    await ReminderService.instance.saveSettings(next);
    if (!mounted) return;
    setState(() => _busy = false);
  }

  Future<void> _toggleMaster(bool enabled) async {
    if (enabled) {
      final ok = await ReminderService.instance.requestPermission();
      if (!mounted) return;
      setState(() => _permissionGranted = ok);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: CuramindColors.danger,
            content: Text(
              'Notification permission was denied. Enable it in device settings.',
              style: GoogleFonts.outfit(color: CuramindColors.white),
            ),
          ),
        );
        return;
      }
    }
    await _persist(_settings.copyWith(masterEnabled: enabled));
  }

  Future<void> _pickDiaryTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _settings.diaryTime.hour,
        minute: _settings.diaryTime.minute,
      ),
    );
    if (picked == null) return;
    await _persist(
      _settings.copyWith(
        diaryTime: ReminderTime(hour: picked.hour, minute: picked.minute),
      ),
    );
  }

  Future<void> _pickMedTime(int index) async {
    final current = _settings.medTimes[index];
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked == null) return;
    final next = [..._settings.medTimes];
    next[index] = ReminderTime(hour: picked.hour, minute: picked.minute);
    await _persist(_settings.copyWith(medTimes: next));
  }

  Future<void> _addMedTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked == null) return;
    await _persist(
      _settings.copyWith(
        medTimes: [
          ..._settings.medTimes,
          ReminderTime(hour: picked.hour, minute: picked.minute),
        ],
      ),
    );
  }

  Future<void> _removeMedTime(int index) async {
    if (_settings.medTimes.length <= 1) return;
    final next = [..._settings.medTimes]..removeAt(index);
    await _persist(_settings.copyWith(medTimes: next));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CuramindColors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CuramindColors.mistBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Notifications',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CuramindColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Diary and medication alarms. Uses device permission on Chrome, Windows, Android, and iOS.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              height: 1.4,
              color: CuramindColors.inkMuted,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Enable notifications',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: CuramindColors.ink,
              ),
            ),
            subtitle: Text(
              _permissionGranted == false
                  ? 'Permission off — turn on to request access'
                  : 'Ask the device for notification permission',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: CuramindColors.inkMuted,
              ),
            ),
            value: _settings.masterEnabled,
            activeThumbColor: CuramindColors.sageDeep,
            onChanged: _busy ? null : _toggleMaster,
          ),
          if (_settings.masterEnabled) ...[
            const Divider(),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Diary reminder',
                style: GoogleFonts.outfit(color: CuramindColors.ink),
              ),
              value: _settings.diaryEnabled,
              activeThumbColor: CuramindColors.sageDeep,
              onChanged: _busy
                  ? null
                  : (v) => _persist(_settings.copyWith(diaryEnabled: v)),
            ),
            if (_settings.diaryEnabled)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Alarm time',
                  style: GoogleFonts.outfit(color: CuramindColors.ink),
                ),
                trailing: TextButton(
                  onPressed: _busy ? null : _pickDiaryTime,
                  child: Text(_settings.diaryTime.label),
                ),
              ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Medication reminders',
                style: GoogleFonts.outfit(color: CuramindColors.ink),
              ),
              subtitle: Text(
                'Only fires when you have active prescriptions',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: CuramindColors.inkMuted,
                ),
              ),
              value: _settings.medsEnabled,
              activeThumbColor: CuramindColors.sageDeep,
              onChanged: _busy
                  ? null
                  : (v) => _persist(_settings.copyWith(medsEnabled: v)),
            ),
            if (_settings.medsEnabled) ...[
              ...List.generate(_settings.medTimes.length, (i) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Dose time ${i + 1}',
                    style: GoogleFonts.outfit(color: CuramindColors.ink),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: _busy ? null : () => _pickMedTime(i),
                        child: Text(_settings.medTimes[i].label),
                      ),
                      if (_settings.medTimes.length > 1)
                        IconButton(
                          onPressed: _busy ? null : () => _removeMedTime(i),
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                    ],
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _busy ? null : _addMedTime,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add dose time'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
