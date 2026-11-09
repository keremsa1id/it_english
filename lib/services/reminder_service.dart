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

/// Sabah ve öğlen selamlama bildirimlerinin saatleri (07:00 ve 12:00).
const int morningGreetingMinutes = 7 * 60;
const int noonGreetingMinutes = 12 * 60;

/// Selamlama bildirimi metni: (başlık, gövde). [streak] sürmekte olan seri,
/// [goal] günlük hedef soru sayısı. Metin sayıları kurulum anında sabitlenir;
/// bu yüzden bugünkü ilerleme yerine yalnızca hedef ve seri anlatılır.
(String, String) greetingMessage({
  required bool morning,
  required int streak,
  required int goal,
}) {
  if (morning) {
    return (
      'Good morning!',
      streak > 0
          ? 'Your $streak-day streak is on. Finish $goal quiz questions today '
              'to keep it going.'
          : 'A new day to learn. Finish $goal quiz questions today to start '
              'a streak.',
    );
  }
  return (
    'Good afternoon!',
    streak > 0
        ? "Half the day is gone. $goal questions keep your $streak-day streak "
            'alive.'
        : 'Half the day is gone. A quick quiz of $goal questions starts your '
            'streak.',
  );
}

/// Seri uyarısı bildirimlerinin gün içindeki saati (22:00, gece yarısına
/// 2 saat kala).
const int streakWarningMinutes = 22 * 60;

/// Seri bozulmak üzereyken gönderilecek uyarıların zamanları: (bugünden kaç
/// gün sonra, zaman). Her uyarı gece yarısına [streakWarningMinutes] kadar
/// kala gelir.
///
/// Yalnızca korunacak bir seri varsa kurulur:
/// * Bugün: hedef henüz tutturulmadıysa ve seri sürüyorsa.
/// * Yarın: hedef bugün tutturulduysa (seri yarın da devam edebilir).
/// Daha ilerisi için kurulmaz; bugün hedef kaçırılırsa seri zaten biter.
/// Günlük hatırlatma uyarıya 60 dakikadan yakınsa uyarı atlanır.
List<(int, DateTime)> streakWarningTimes({
  required DateTime now,
  required int streak,
  required bool goalReachedToday,
  required int reminderMinutes,
}) {
  if (streak <= 0 ||
      (reminderMinutes - streakWarningMinutes).abs() < 60) {
    return const <(int, DateTime)>[];
  }
  final List<(int, DateTime)> times = <(int, DateTime)>[];
  for (int day = 0; day < 2; day++) {
    if (day == 0 && goalReachedToday) {
      continue;
    }
    if (day == 1 && !goalReachedToday) {
      continue;
    }
    final DateTime at = DateTime(
      now.year,
      now.month,
      now.day + day,
      streakWarningMinutes ~/ 60,
      streakWarningMinutes % 60,
    );
    if (at.isAfter(now)) {
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
  static const int _warningFirstId = 1100;
  static const int _morningFirstId = 1200;
  static const int _noonFirstId = 1300;

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_reminder',
      'Daily reminder',
      channelDescription: 'Reminds you to reach your daily goal.',
    ),
  );

  static const NotificationDetails _warningDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'streak_warning',
      'Streak warning',
      channelDescription: 'Warns you when your streak is about to end.',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  static const NotificationDetails _greetingDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_greeting',
      'Morning and noon messages',
      channelDescription: 'Good morning and good afternoon messages with '
          'your goal and streak.',
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
        '|${progress.goalReachedToday}|${progress.today}|${progress.streak}|${progress.dailyGoal}';
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
        '|${progress.goalReachedToday}|${progress.today}|${progress.streak}|${progress.dailyGoal}';
    try {
      for (int i = 0; i < daysAhead; i++) {
        await _plugin.cancel(id: _firstId + i);
      }
      for (int i = 0; i < 2; i++) {
        await _plugin.cancel(id: _warningFirstId + i);
      }
      for (int i = 0; i < daysAhead; i++) {
        await _plugin.cancel(id: _morningFirstId + i);
        await _plugin.cancel(id: _noonFirstId + i);
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
      for (final (bool morning, int firstId, int minutes) in <(bool, int, int)>[
        (true, _morningFirstId, morningGreetingMinutes),
        (false, _noonFirstId, noonGreetingMinutes),
      ]) {
        // Günlük hatırlatmaya çok yakınsa iki bildirim üst üste gelmesin.
        if ((progress.reminderMinutes - minutes).abs() < 60) {
          continue;
        }
        for (final (int day, DateTime at) in reminderTimes(
          now: DateTime.now(),
          minutes: minutes,
          goalReachedToday: progress.goalReachedToday,
        )) {
          // Seri yalnızca bugün ve (hedef bugün tutturulduysa) yarın için
          // sürüyor sayılır.
          final int streak =
              day == 0 || (day == 1 && progress.goalReachedToday)
                  ? progress.streak
                  : 0;
          final (String title, String body) = greetingMessage(
            morning: morning,
            streak: streak,
            goal: progress.dailyGoal,
          );
          await _plugin.zonedSchedule(
            id: firstId + day,
            scheduledDate: tz.TZDateTime.from(at, tz.UTC),
            notificationDetails: _greetingDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            title: title,
            body: body,
          );
        }
      }
      for (final (int day, DateTime at) in streakWarningTimes(
        now: DateTime.now(),
        streak: progress.streak,
        goalReachedToday: progress.goalReachedToday,
        reminderMinutes: progress.reminderMinutes,
      )) {
        final int hours = (24 * 60 - streakWarningMinutes) ~/ 60;
        await _plugin.zonedSchedule(
          id: _warningFirstId + day,
          scheduledDate: tz.TZDateTime.from(at, tz.UTC),
          notificationDetails: _warningDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: 'Your ${progress.streak}-day streak ends in $hours hours!',
          body: 'Finish your daily goal before midnight to keep it alive.',
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
