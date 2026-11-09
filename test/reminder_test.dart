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

  group('streakWarningTimes', () {
    const int eightPm = 20 * 60;

    test('seri yoksa uyarı kurulmaz', () {
      expect(
        streakWarningTimes(
          now: DateTime(2026, 11, 5, 9),
          streak: 0,
          goalReachedToday: false,
          reminderMinutes: eightPm,
        ),
        isEmpty,
      );
    });

    test('hedef tutturulmadıysa yalnızca bugün 22:00 için kurulur', () {
      final List<(int, DateTime)> times = streakWarningTimes(
        now: DateTime(2026, 11, 5, 9),
        streak: 4,
        goalReachedToday: false,
        reminderMinutes: eightPm,
      );

      expect(times, <(int, DateTime)>[(0, DateTime(2026, 11, 5, 22))]);
    });

    test('hedef tutturulduysa yalnızca yarın için kurulur', () {
      final List<(int, DateTime)> times = streakWarningTimes(
        now: DateTime(2026, 11, 5, 9),
        streak: 4,
        goalReachedToday: true,
        reminderMinutes: eightPm,
      );

      expect(times, <(int, DateTime)>[(1, DateTime(2026, 11, 6, 22))]);
    });

    test('bugünün uyarı saati geçtiyse bugün için kurulmaz', () {
      expect(
        streakWarningTimes(
          now: DateTime(2026, 11, 5, 23),
          streak: 4,
          goalReachedToday: false,
          reminderMinutes: eightPm,
        ),
        isEmpty,
      );
    });

    test('günlük hatırlatma uyarıya 60 dakikadan yakınsa atlanır', () {
      expect(
        streakWarningTimes(
          now: DateTime(2026, 11, 5, 9),
          streak: 4,
          goalReachedToday: false,
          reminderMinutes: 21 * 60 + 30,
        ),
        isEmpty,
      );
    });
  });

  group('greetingMessage', () {
    test('sabah mesajı seriyi ve hedefi söyler', () {
      final (String title, String body) =
          greetingMessage(morning: true, streak: 5, goal: 10);

      expect(title, 'Good morning!');
      expect(body, contains('5-day streak'));
      expect(body, contains('10 quiz questions'));
    });

    test('öğlen mesajı seri yoksa seri başlatmayı önerir', () {
      final (String title, String body) =
          greetingMessage(morning: false, streak: 0, goal: 20);

      expect(title, 'Good afternoon!');
      expect(body, contains('starts your streak'));
      expect(body, contains('20 questions'));
    });

    test('selamlama saatleri 07:00 ve 12:00', () {
      expect(morningGreetingMinutes, 7 * 60);
      expect(noonGreetingMinutes, 12 * 60);
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
