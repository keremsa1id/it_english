import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:it_english/services/progress_service.dart';
import 'package:it_english/services/reminder_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('reminderTimes', () {
    const int eightPm = 20 * 60;

    test('saat geçmediyse bugünden başlayarak her gün aynı saatte kurulur', () {
      final List<(int, DateTime)> times = reminderTimes(
        now: DateTime(2026, 11, 5, 9),
        minutes: eightPm,
        goalReachedToday: false,
      );

      expect(times, hasLength(ReminderService.daysAhead));
      expect(times.first, (0, DateTime(2026, 11, 5, 20)));
      expect(times[1], (1, DateTime(2026, 11, 6, 20)));
    });

    test('hedef bugün tutturulduysa bugünkü bildirim atlanır', () {
      final List<(int, DateTime)> times = reminderTimes(
        now: DateTime(2026, 11, 5, 9),
        minutes: eightPm,
        goalReachedToday: true,
      );

      expect(times.first, (1, DateTime(2026, 11, 6, 20)));
      expect(times, hasLength(ReminderService.daysAhead - 1));
    });

    test('bugünün saati geçtiyse yarından başlar', () {
      final List<(int, DateTime)> times = reminderTimes(
        now: DateTime(2026, 11, 5, 21),
        minutes: eightPm,
        goalReachedToday: false,
      );

      expect(times.first.$1, 1);
    });

    test('ay sonunda tarih doğru ilerler', () {
      final List<(int, DateTime)> times = reminderTimes(
        now: DateTime(2026, 11, 30, 9),
        minutes: 7 * 60 + 30,
        goalReachedToday: true,
      );

      expect(times.first, (1, DateTime(2026, 12, 1, 7, 30)));
    });
  });

  group('hatırlatma ayarları', () {
    test('varsayılan olarak kapalı ve saat 20:00', () async {
      final ProgressService progress = ProgressService.forTest();
      await progress.load();

      expect(progress.reminderEnabled, isFalse);
      expect(progress.reminderMinutes, ProgressService.defaultReminderMinutes);
    });

    test('ayarlar kaydedilir ve geri okunur', () async {
      final ProgressService first = ProgressService.forTest();
      await first.setReminder(enabled: true, minutes: 8 * 60 + 15);

      final ProgressService second = ProgressService.forTest();
      await second.load();

      expect(second.reminderEnabled, isTrue);
      expect(second.reminderMinutes, 8 * 60 + 15);
    });

    test('yalnızca verilen ayar değişir', () async {
      final ProgressService progress = ProgressService.forTest();
      await progress.setReminder(enabled: true);
      await progress.setReminder(minutes: 9 * 60);

      expect(progress.reminderEnabled, isTrue);
      expect(progress.reminderMinutes, 9 * 60);
    });

    test('geçersiz saat reddedilir', () async {
      final ProgressService progress = ProgressService.forTest();

      await expectLater(
        progress.setReminder(minutes: 24 * 60),
        throwsRangeError,
      );
    });
  });
}
