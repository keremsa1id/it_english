import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'progress_service.dart';

/// Önümüzdeki [days] gün için hatırlatma zamanları: (bugünden kaç gün
/// sonra, cihazın yerel saatiyle zaman).
///
/// Saati geçmiş günler ve hedefin zaten tutturulduğu bugün atlanır.
List<(int, DateTime)> reminderTimes({
  required DateTime now,
  required int minutes,
  required bool goalReachedToday,
  int days = ReminderService.daysAhead,
}) {
  final List<(int, DateTime)> times = <(int, DateTime)>[];
  for (int day = 0; day < days; day++) {
    final DateTime at = DateTime(
      now.year,
      now.month,
      now.day + day,
      minutes ~/ 60,
      minutes % 60,
    );
    if (at.isAfter(now) && !(day == 0 && goalReachedToday)) {
      times.add((day, at));
    }
  }
  return times;
}

/// Günlük hedef hatırlatma bildirimleri (yalnızca Android).
///
/// Tekrarlayan tek bir bildirim yerine önümüzdeki [daysAhead] günün her
/// biri için ayrı bildirim kurulur; böylece hedef tutturulan günün
/// bildirimi iptal edilebilir. Uygulama her açıldığında ve ilerleme
/// değiştiğinde plan yenilenir.
///
/// Uygulama genelinde tek bir örnek kullanılır: `ReminderService.instance`.
class ReminderService {
  ReminderService._();

  static final ReminderService instance = ReminderService._();

  /// Kaç gün ilerisine bildirim kurulacağı.
  static const int daysAhead = 14;
  static const int _firstId = 1000;

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_reminder',
      'Daily reminder',
      channelDescription: 'Reminds you to reach your daily goal.',
    ),
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _started = false;

  /// Son kurulan planın özeti; değişmediyse yeniden kurulmaz.
  String? _plannedFor;

  /// Bildirimler bu platformda destekleniyor mu (web'de uygulama kapalıyken
  /// bildirim gönderilemez).
  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Bildirim altyapısını hazırlar, planı kurar ve ilerlemeyi dinlemeye
  /// başlar.
  Future<void> start() async {
    if (!isSupported || _started) {
      return;
    }
    _started = true;
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      await reschedule();
      ProgressService.instance.addListener(_onProgressChanged);
    } catch (error) {
      debugPrint('ReminderService.start hatası: $error');
    }
  }

  /// Android 13+ için bildirim izni ister; verildiyse true.
  Future<bool> requestPermission() async {
    if (!isSupported) {
      return false;
    }
    try {
      final AndroidFlutterLocalNotificationsPlugin? android =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? true;
    } catch (error) {
      debugPrint('Bildirim izni istenemedi: $error');
      return false;
    }
  }

  void _onProgressChanged() {
    final ProgressService progress = ProgressService.instance;
    // Yalnızca planı etkileyen bilgiler değişince yeniden kur.
    final String plan = '${progress.reminderEnabled}|${progress.reminderMinutes}'
        '|${progress.goalReachedToday}|${progress.today}';
    if (plan != _plannedFor) {
      reschedule();
    }
  }

  /// Bildirim planını ayarlara ve bugünkü ilerlemeye göre yeniden kurar.
  Future<void> reschedule() async {
    if (!isSupported) {
      return;
    }
    final ProgressService progress = ProgressService.instance;
    _plannedFor = '${progress.reminderEnabled}|${progress.reminderMinutes}'
        '|${progress.goalReachedToday}|${progress.today}';
    try {
      for (int i = 0; i < daysAhead; i++) {
        await _plugin.cancel(id: _firstId + i);
      }
      if (!progress.reminderEnabled) {
        return;
      }
      for (final (int day, DateTime at) in reminderTimes(
        now: DateTime.now(),
        minutes: progress.reminderMinutes,
        goalReachedToday: progress.goalReachedToday,
      )) {
        final (String title, String body) = _message(progress, isToday: day == 0);
        await _plugin.zonedSchedule(
          id: _firstId + day,
          // Cihazın yerel saati UTC'deki aynı ana çevrilir; saat dilimi
          // adını bilmeye gerek kalmaz.
          scheduledDate: tz.TZDateTime.from(at, tz.UTC),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: title,
          body: body,
        );
      }
    } catch (error) {
      debugPrint('Hatırlatmalar kurulamadı: $error');
    }
  }

  /// Bildirim metni. Bugünkü bildirimde kalan soru sayısı yazılır; sonraki
  /// günler için genel bir hatırlatma kullanılır.
  static (String, String) _message(
    ProgressService progress, {
    required bool isToday,
  }) {
    final int streak = progress.streak;
    final String title = streak > 1
        ? "Don't break your $streak-day streak!"
        : 'Time for some English';
    if (!isToday) {
      return (title, 'A few quiz questions keep your daily goal on track.');
    }
    final int left = progress.dailyGoal - progress.todayCount;
    return (
      title,
      left == 1
          ? '1 question left to reach your daily goal.'
          : '$left questions left to reach your daily goal.',
    );
  }
}
