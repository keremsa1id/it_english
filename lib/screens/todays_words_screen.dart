import 'package:flutter/material.dart';

import '../services/daily_words.dart';
import '../services/progress_service.dart';
import 'study_list_screen.dart';

/// Günün 10 kelimesi: önce seçilir (bugün daha önce seçildiyse aynısı
/// gelir), sonra Words kartları ve quiz ile çalışılır.
class TodaysWordsScreen extends StatefulWidget {
  const TodaysWordsScreen({super.key});

  @override
  State<TodaysWordsScreen> createState() => _TodaysWordsScreenState();
}

class _TodaysWordsScreenState extends State<TodaysWordsScreen> {
  late final Future<List<String>> _wordsFuture =
      DailyWordsService.instance.ensureToday();

  static const String _emptyMessage =
      'There are no words for today yet. Open a section first.';

  static String _describe(ProgressService progress) {
    final List<String> keys = progress.todayWordKeys;
    if (keys.isEmpty) {
      return _emptyMessage;
    }
    final int learned = progress.learnedAmong(keys);
    return '${keys.length} words picked for today ($learned learned). '
        'New words come first. A new set arrives tomorrow.';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _wordsFuture,
      builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: const Text("Today's Words"), centerTitle: true),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        return StudyListScreen(
          title: "Today's Words",
          include: DailyWordsService.instance.isTodayWord,
          description: _describe,
          emptyMessage: _emptyMessage,
          wordsSubtitle: "Study today's words",
          quizSubtitle: "Practice today's words",
        );
      },
    );
  }
}
