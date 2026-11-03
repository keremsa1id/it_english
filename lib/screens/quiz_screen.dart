import 'package:flutter/material.dart';

import '../models/term.dart';
import '../services/quiz_generator.dart';
import '../services/term_repository.dart';
import '../services/tts_service.dart';
import '../utils/sentence_parts.dart';
import '../widgets/category_style.dart';
import '../widgets/message_view.dart';

/// Boşluk doldurma oyunu.
///
/// Her soruda bir örnek cümle, terimin yerinde boşlukla gösterilir; alttaki
/// 4 terimden doğrusu seçilir. Yanlış seçenek kırmızı olur ve tekrar
/// denenebilir. Doğru seçilince boşluk dolar, cümle sesli okunur ve
/// "Next" butonu çıkar. İlk denemede bilinen sorular puan sayılır.
class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    this.repository = const TermRepository(),
    this.questionCount = 10,
    this.title = 'Quiz',
  });

  final TermRepository repository;
  final int questionCount;
  final String title;

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
    );
    _currentIndex = 0;
    _score = 0;
    _solved = false;
    _finished = false;
    _wrongPicks.clear();
  }

  void _onOptionTap(Term option) {
    if (_solved || _wrongPicks.contains(option)) {
      return;
    }
    final QuizQuestion question = _questions[_currentIndex];

    if (!identical(option, question.answer)) {
      setState(() => _wrongPicks.add(option));
      return;
    }

    setState(() {
      _solved = true;
      if (_wrongPicks.isEmpty) {
        _score++;
      }
    });
    TtsService.instance.speak(question.answer.exampleSentence);
  }

  void _goToNextQuestion() {
    TtsService.instance.stop();
    setState(() {
      if (_currentIndex >= _questions.length - 1) {
        _finished = true;
        return;
      }
      _currentIndex++;
      _solved = false;
      _wrongPicks.clear();
    });
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
              return const MessageView(
                icon: Icons.inbox_rounded,
                message: 'There are not enough words for a quiz.',
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
            'Choose the word that completes the sentence.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _BlankSentenceCard(
              term: question.answer,
              solved: _solved,
            ),
          ),
          const SizedBox(height: 16),
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

/// Terimin yerinde boşluk olan cümle kartı. [solved] true olunca boşluk
/// doğru terimle yeşil olarak dolar.
class _BlankSentenceCard extends StatelessWidget {
  const _BlankSentenceCard({required this.term, required this.solved});

  static const Color _correctColor = Color(0xFF2E7D32);

  final Term term;
  final bool solved;

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
                child: Text.rich(
                  TextSpan(
                    children: <TextSpan>[
                      for (final SentencePart part
                          in splitSentence(term.exampleSentence, term.term))
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
              ),
            ),
          );
        },
      ),
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
  static const Color _wrongColor = Color(0xFFC62828);

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
