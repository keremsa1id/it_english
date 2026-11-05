import 'package:flutter/widgets.dart';

import '../services/progress_service.dart';

/// Ekran açık kaldığı süreyi istatistiklere "çalışma süresi" olarak ekler.
///
/// Quiz ve oyun ekranlarının State sınıfına eklenir: ekran açılınca saymaya
/// başlar, kapanınca süreyi [ProgressService.addStudyTime] ile kaydeder.
mixin StudyTimer<T extends StatefulWidget> on State<T> {
  final Stopwatch _studyStopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _studyStopwatch.start();
  }

  @override
  void dispose() {
    _studyStopwatch.stop();
    ProgressService.instance.addStudyTime(_studyStopwatch.elapsed);
    super.dispose();
  }
}
