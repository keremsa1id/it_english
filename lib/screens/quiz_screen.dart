import 'package:flutter/material.dart';

import '../models/quiz_mode.dart';
import '../models/term.dart';
import '../services/progress_service.dart';
import '../services/quiz_generator.dart';
import '../services/term_repository.dart';
import '../services/tts_service.dart';
import '../utils/answer_check.dart';
import '../utils/sentence_parts.dart';
import '../widgets/category_style.dart';
import '../widgets/message_view.dart';

/// Quiz ekranı; soru biçimi [mode]'a göre değişir (bkz. [QuizMode]).
///
/// Şıklı türlerde alttaki 4 terimden doğrusu seçilir; yanlış seçenek
/// işaretlenir ve tekrar denenebilir. Yazma türünde terim yazılır; yanlışta
/// uyarı çıkar, istenirse cevap gösterilir. Doğru cevaptan sonra boşluk
/// dolar, cümle (ya da terim) sesli okunur ve "Next" butonu çıkar. İlk
/// denemede bilinen sorular puan sayılır.
class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    this.repository = const TermRepository(),
    this.questionCount = 10,
    this.title = 'Quiz',
    this.mode = QuizMode.fillBlank,
    this.quizId,
    this.askOnly,
    this.emptyMessage = 'There are not enough words for a quiz.',
  });

  final TermRepository repository;
  final int questionCount;
  final String title;
  final QuizMode mode;

  /// Verilirse tur sonunda skor bu anahtarla kaydedilir.
  final String? quizId;

  /// Verilirse yalnızca bunu sağlayan kelimeler sorulur; her turun başında
  /// yeniden uygulanır (bkz. [QuizGenerator.generate]).
  final bool Function(Term term)? askOnly;

  /// Sorulacak kelime yoksa gösterilen mesaj.
  final String emptyMessage;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final QuizGenerator _generator = QuizGenerator();
  late Future<List<Term>> _termsFuture;

  List<QuizQuestion> _questions = const <QuizQuestion>[];
  int _currentIndex = 0;
  int _score = 0;
  bool _solved = false;
  bool _finished = false;
  final Set<Term> _wrongPicks = <Term>{};

  /// Yazma quiz'inde mevcut soruya yanlış cevap verildi mi.
  bool _typedWrong = false;

  @override
  void initState() {
    super.initState();
    _termsFuture = _loadTerms();
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  Future<List<Term>> _loadTerms() async {
    final List<Term> terms = await widget.repository.loadTerms();
    _startRound(terms);
    return terms;
  }

  void _retry() {
    setState(() => _termsFuture = _loadTerms());
  }

  /// Yeni bir tur başlatır. setState içinde çağrılabilir.
  void _startRound(List<Term> terms) {
    TtsService.instance.stop();
    _questions = _generator.generate(
      terms,
      questionCount: widget.questionCount,
      askOnly: widget.askOnly,
      requireBlank: widget.mode.needsBlank,
    );
    _currentIndex = 0;
    _score = 0;
    _solved = false;
    _finished = false;
    _wrongPicks.clear();
    _typedWrong = false;
    // İlk soru ekrana gelince okunsun.
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakPrompt());
  }

  /// Dinleme quiz'inde mevcut sorunun kelimesini okur; diğer türlerde
  /// bir şey yapmaz.
  void _speakPrompt() {
    if (!mounted ||
        widget.mode != QuizMode.listening ||
        _finished ||
        _questions.isEmpty) {
      return;
    }
    TtsService.instance.speak(_questions[_currentIndex].answer.term);
  }

  void _onOptionTap(Term option) {
    if (_solved || _wrongPicks.contains(option)) {
      return;
    }
    final QuizQuestion question = _questions[_currentIndex];

    if (!identical(option, question.answer)) {
      // Yanlış bilinen kelime öğrenilmiş sayılmaz, Review destesine girer.
      ProgressService.instance.recordAnswer(question.answer, correct: false);
      setState(() => _wrongPicks.add(option));
      return;
    }

    _markSolved(question, firstTry: _wrongPicks.isEmpty);
  }

  /// Yazma quiz'inde gönderilen cevabı kontrol eder.
  void _onTypedAnswer(String input) {
    if (_solved || input.trim().isEmpty) {
      return;
    }
    final QuizQuestion question = _questions[_currentIndex];

    if (!isCorrectAnswer(input, question.answer.term)) {
      if (!_typedWrong) {
        ProgressService.instance.recordAnswer(question.answer, correct: false);
      }
      setState(() => _typedWrong = true);
      return;
    }

    _markSolved(question, firstTry: !_typedWrong);
  }

  /// Yazma quiz'inde cevabı gösterir; soru yanlış bilinmiş sayılır.
  void _revealAnswer() {
    if (_solved) {
      return;
    }
    final QuizQuestion question = _questions[_currentIndex];
    if (!_typedWrong) {
      ProgressService.instance.recordAnswer(question.answer, correct: false);
    }
    _typedWrong = true;
    _markSolved(question, firstTry: false);
  }

  /// Soruyu çözülmüş yapar. [firstTry] ise puan verilir ve kelime öğrenilmiş
  /// sayılır. Ardından cümle (ya da terim) sesli okunur.
  void _markSolved(QuizQuestion question, {required bool firstTry}) {
    if (firstTry) {
      ProgressService.instance.recordAnswer(question.answer, correct: true);
    }
    ProgressService.instance.recordPractice().then(_celebrateGoal);
    setState(() {
      _solved = true;
      if (firstTry) {
        _score++;
      }
    });
    TtsService.instance.speak(
      widget.mode.needsBlank
          ? question.answer.exampleSentence
          : question.answer.term,
    );
  }

  /// Günlük hedef bu soruyla tutturulduysa kısa bir kutlama gösterir.
  void _celebrateGoal(bool reachedNow) {
    if (!reachedNow || !mounted) {
      return;
    }
    final int streak = ProgressService.instance.streak;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Daily goal reached! '
          '$streak-day streak ${streak > 1 ? '— keep it going!' : '— great start!'}',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _goToNextQuestion() {
    TtsService.instance.stop();
    final String? quizId = widget.quizId;
    if (quizId != null && _currentIndex >= _questions.length - 1) {
      ProgressService.instance.recordQuiz(quizId, _score, _questions.length);
    }
    setState(() {
      if (_currentIndex >= _questions.length - 1) {
        _finished = true;
        return;
      }
      _currentIndex++;
      _solved = false;
      _wrongPicks.clear();
      _typedWrong = false;
    });
    _speakPrompt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), centerTitle: true),
      body: SafeArea(
        child: FutureBuilder<List<Term>>(
          future: _termsFuture,
          builder: (BuildContext context, AsyncSnapshot<List<Term>> snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              final Object? error = snapshot.error;
              return MessageView(
                icon: Icons.error_outline_rounded,
                message: error is TermRepositoryException
                    ? error.message
                    : 'Could not load the quiz.',
                buttonLabel: 'Try again',
                onPressed: _retry,
              );
            }

            final List<Term> terms = snapshot.data ?? const <Term>[];
            if (_questions.isEmpty) {
              return MessageView(
                icon: Icons.inbox_rounded,
                message: widget.emptyMessage,
              );
            }

            return Center(
              child: ConstrainedBox(
                // Geniş ekranlarda içerik aşırı uzamasın.
                constraints: const BoxConstraints(maxWidth: 640),
                child: _finished
                    ? _ResultView(
                        score: _score,
                        total: _questions.length,
                        onPlayAgain: () => setState(() => _startRound(terms)),
                        onHome: () => Navigator.of(context).pop(),
                      )
                    : _buildQuestion(context),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuestion(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final QuizQuestion question = _questions[_currentIndex];
    final bool isLast = _currentIndex >= _questions.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // İlerleme: kaçıncı soru olduğu.
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / _questions.length,
                    minHeight: 10,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_currentIndex + 1} / ${_questions.length}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${widget.mode.subtitle}.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: switch (widget.mode) {
              QuizMode.fillBlank => _BlankTextCard(
                  term: question.answer,
                  text: question.answer.exampleSentence,
                  solved: _solved,
                ),
              // Tanımda terimin kendisi geçiyorsa cevabı ele vermesin diye
              // o kısım da boşluk olarak gösterilir.
              QuizMode.definition => _BlankTextCard(
                  term: question.answer,
                  text: question.answer.definition,
                  solved: _solved,
                  label: 'DEFINITION',
                ),
              QuizMode.listening => _ListeningCard(
                  term: question.answer,
                  solved: _solved,
                  onListen: _speakPrompt,
                ),
              QuizMode.typing => _BlankTextCard(
                  term: question.answer,
                  text: question.answer.exampleSentence,
                  solved: _solved,
                  hint: question.answer.turkish.isEmpty
                      ? null
                      : 'Turkish: ${question.answer.turkish}',
                ),
            },
          ),
          const SizedBox(height: 16),
          if (widget.mode.isTyped)
            _TypingAnswer(
              // Soru değişince yazılan metin sıfırlansın.
              key: ValueKey<int>(_currentIndex),
              solved: _solved,
              wrong: _typedWrong,
              onSubmit: _onTypedAnswer,
              onReveal: _revealAnswer,
            )
          else
            for (final Term option in question.options) ...[
              _OptionButton(
                // Soru değişince buton durumu (animasyon) sıfırlansın.
                key: ValueKey<String>('$_currentIndex-${option.term}'),
                label: option.term,
                state: _stateOf(question, option),
                onPressed: () => _onOptionTap(option),
              ),
              const SizedBox(height: 10),
            ],
          // Yer hep ayrılı kalsın ki doğru cevapta düzen zıplamasın.
          const SizedBox(height: 6),
          SizedBox(
            height: 56,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _solved ? 1.0 : 0.0,
              child: FilledButton.icon(
                onPressed: _solved ? _goToNextQuestion : null,
                icon: Icon(
                  isLast ? Icons.flag_rounded : Icons.arrow_forward_rounded,
                ),
                label: Text(isLast ? 'See results' : 'Next'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _OptionState _stateOf(QuizQuestion question, Term option) {
    if (_wrongPicks.contains(option)) {
      return _OptionState.wrong;
    }
    if (_solved && identical(option, question.answer)) {
      return _OptionState.correct;
    }
    if (_solved) {
      return _OptionState.faded;
    }
    return _OptionState.normal;
  }
}

/// [text] metnini terimin geçtiği yerler boşluk olacak şekilde gösteren kart
/// (örnek cümle ya da tanım). [solved] true olunca boşluk doğru terimle
/// yeşil olarak dolar. [label] verilirse metnin üstünde küçük başlık,
/// [hint] verilirse altında ipucu olur.
class _BlankTextCard extends StatelessWidget {
  const _BlankTextCard({
    required this.term,
    required this.text,
    required this.solved,
    this.label,
    this.hint,
  });

  static const Color _correctColor = Color(0xFF2E7D32);

  final Term term;
  final String text;
  final bool solved;
  final String? label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CategoryStyle style = CategoryStyle.of(term.category);
    final TextStyle baseStyle = theme.textTheme.headlineSmall!.copyWith(
      fontSize: 26,
      height: 1.5,
      color: theme.colorScheme.onSurface,
    );
    final TextStyle blankStyle = baseStyle.copyWith(
      fontWeight: FontWeight.bold,
      color: solved ? _correctColor : theme.colorScheme.primary,
      backgroundColor: solved
          ? _correctColor.withValues(alpha: 0.12)
          : theme.colorScheme.primary.withValues(alpha: 0.08),
    );

    return Container(
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: style.color.withValues(alpha: 0.6), width: 2),
      ),
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (label != null) ...[
                      Text(
                        label!,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text.rich(
                      TextSpan(
                        children: <TextSpan>[
                          for (final SentencePart part
                              in splitSentence(text, term.term))
                            if (part.isTerm)
                              TextSpan(
                                text: solved ? part.text : ' ________ ',
                                style: blankStyle,
                              )
                            else
                              TextSpan(text: part.text, style: baseStyle),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (hint != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        hint!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Dinleme sorusunun kartı: kelime yazılmaz, büyük hoparlör butonuyla
/// tekrar dinlenir. [solved] true olunca kelime ve Türkçesi görünür.
class _ListeningCard extends StatelessWidget {
  const _ListeningCard({
    required this.term,
    required this.solved,
    required this.onListen,
  });

  static const Color _correctColor = Color(0xFF2E7D32);

  final Term term;
  final bool solved;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CategoryStyle style = CategoryStyle.of(term.category);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: style.color.withValues(alpha: 0.6), width: 2),
      ),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filled(
                onPressed: onListen,
                tooltip: 'Listen again',
                iconSize: 56,
                padding: const EdgeInsets.all(24),
                style: IconButton.styleFrom(
                  backgroundColor: style.color,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.volume_up_rounded),
              ),
              const SizedBox(height: 16),
              if (solved) ...[
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    term.term,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _correctColor,
                    ),
                  ),
                ),
                if (term.turkish.isNotEmpty)
                  Text(
                    term.turkish,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ] else
                Text(
                  'Tap to listen again',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Yazma quiz'inin cevap alanı: metin kutusu, "Check" ve "Show answer".
/// Yanlış cevapta kutunun altında uyarı çıkar.
class _TypingAnswer extends StatefulWidget {
  const _TypingAnswer({
    super.key,
    required this.solved,
    required this.wrong,
    required this.onSubmit,
    required this.onReveal,
  });

  final bool solved;
  final bool wrong;
  final ValueChanged<String> onSubmit;
  final VoidCallback onReveal;

  @override
  State<_TypingAnswer> createState() => _TypingAnswerState();
}

class _TypingAnswerState extends State<_TypingAnswer> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          enabled: !widget.solved,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
          style: const TextStyle(fontSize: 20),
          onSubmitted: widget.onSubmit,
          decoration: InputDecoration(
            hintText: 'Type the missing word',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            errorText: widget.wrong && !widget.solved
                ? 'Not quite. Try again or show the answer.'
                : null,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.solved ? null : widget.onReveal,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Show answer'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: widget.solved
                    ? null
                    : () => widget.onSubmit(_controller.text),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Check'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

enum _OptionState { normal, wrong, correct, faded }

/// Tek bir seçenek butonu. Duruma göre renk, simge ve saydamlık değişir.
class _OptionButton extends StatelessWidget {
  const _OptionButton({
    super.key,
    required this.label,
    required this.state,
    required this.onPressed,
  });

  static const Color _correctColor = Color(0xFF2E7D32);
  // Temanın kırmızı butonlarıyla karışmasın diye yanlış şık turuncu-amber.
  static const Color _wrongColor = Color(0xFFFFA726);

  final String label;
  final _OptionState state;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color color = switch (state) {
      _OptionState.correct => _correctColor,
      _OptionState.wrong => _wrongColor,
      _ => colors.primary,
    };
    final IconData? icon = switch (state) {
      _OptionState.correct => Icons.check_circle_rounded,
      _OptionState.wrong => Icons.cancel_rounded,
      _ => null,
    };

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: state == _OptionState.faded ? 0.4 : 1.0,
      child: SizedBox(
        height: 56,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            backgroundColor: state == _OptionState.normal ||
                    state == _OptionState.faded
                ? null
                : color.withValues(alpha: 0.1),
            side: BorderSide(
              color: color,
              width: state == _OptionState.normal ? 1.5 : 2.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 28),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: state == _OptionState.wrong
                      ? const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          decorationColor: _wrongColor,
                          decorationThickness: 2,
                        )
                      : null,
                ),
              ),
              SizedBox(width: 28, child: icon == null ? null : Icon(icon)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tur sonunda gösterilen sonuç ekranı.
class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.score,
    required this.total,
    required this.onPlayAgain,
    required this.onHome,
  });

  final int score;
  final int total;
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;

  String get _message {
    final double ratio = total == 0 ? 0 : score / total;
    if (ratio >= 0.9) {
      return 'Excellent!';
    }
    if (ratio >= 0.6) {
      return 'Good job!';
    }
    return 'Keep practicing!';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int percent = total == 0 ? 0 : (score * 100 / total).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.emoji_events_rounded,
            size: 96,
            color: percent >= 60
                ? const Color(0xFFFFB300)
                : theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            _message,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$score / $total correct on the first try ($percent%)',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: onPlayAgain,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Play again'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onHome,
            icon: const Icon(Icons.home_rounded),
            label: const Text('Home'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
          ),
        ],
      ),
    );
  }
}
