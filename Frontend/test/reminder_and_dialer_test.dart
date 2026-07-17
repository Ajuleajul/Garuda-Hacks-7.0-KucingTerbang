import 'package:flutter_test/flutter_test.dart';

import 'package:curamind/services/reminder_service.dart';
import 'package:curamind/utils/phone_dialer.dart';

void main() {
  group('digitsForDialer', () {
    test('keeps plus and digits only', () {
      expect(digitsForDialer('+62 812-0000 0000'), '+6281200000000');
      expect(digitsForDialer('119'), '119');
      expect(digitsForDialer('112'), '112');
      expect(digitsForDialer(''), '');
    });
  });

  group('ReminderSettings', () {
    test('round-trips json', () {
      const settings = ReminderSettings(
        masterEnabled: true,
        diaryEnabled: true,
        diaryTime: ReminderTime(hour: 21, minute: 30),
        medsEnabled: false,
        medTimes: [ReminderTime(hour: 9, minute: 0)],
      );
      final again = ReminderSettings.fromJson(settings.toJson());
      expect(again.masterEnabled, true);
      expect(again.diaryTime.label, '21:30');
      expect(again.medsEnabled, false);
      expect(again.medTimes.single.label, '09:00');
    });
  });
}
