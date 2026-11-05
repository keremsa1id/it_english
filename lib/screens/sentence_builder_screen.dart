import 'dart:math';

import 'package:flutter/material.dart';

import '../models/term.dart';
import '../services/progress_service.dart';
import '../services/term_repository.dart';
import '../services/tts_service.dart';
import '../widgets/message_view.dart';
import '../widgets/study_timer.dart';

/// Cümledeki tek bir kelime kutucuğu. Aynı kelime cümlede iki kez geçebileceği
/// için kutucuklar sırasıyla ([index]) ayırt edilir.
class _Token {
  const _Token(this.index, this.text);

  final int index;
  final String text;
}

/// Cümle kurma oyunu: örnek cümlenin kelimeleri karışık verilir, doğru
/// sıraya dizilir. İlk denemede doğru kurulan cümleler puan sayılır.
class SentenceBuilderScreen extends StatefulWidget {
  const SentenceBuilderScreen({
    super.key,
    required this.repository,
    this.include,
    this.questionCount = 10,
    this.emptyMessage = 'There are not enough words to play.',
  });

  final TermRepository repository;

  /// Verilirse yalnızca bunu sağlayan kelimelerin cümleleri kullanılır.
  final bool Function(Term term)? include;
  final int questionCount;
  final String emptyMessage;

  @override
  State<SentenceBuilderScreen> createState() => _SentenceBuilderScreenState();
}

class _SentenceBuilderScreenState extends State<SentenceBuilderScreen>
    with StudyTimer<SentenceBuilderScreen> {
  static const Color _correctColor = Color(0xFF2E7D32);
  static const Color _wrongColor = Color(0xFFFFA726);

  final Random _random = Random();
  late Future<List<Term>> _termsFuture;

  List<Term> _questions = const <Term>[];
  int _index = 0;
  int _score = 0;
  List<_Token> _pool = <_Token>[];
  List<_Token> _answer = <_Token>[];
  bool _solved = false;

  /// Son "Check" yanlış çıktı (kutucuk oynatılınca uyarı kalkar).
  bool _wrong = false;

  /// Bu soruda en az bir kez yanlış denendi; puan verilmez.
  bool _hadMistake = false;
  bool _finished = false;

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
    final List<Term> terms = (await widget.repository.loadTerms())
        .where((Term t) => widget.include?.call(t) ?? true)
        .toList();
    _startRound(terms);
    return terms;
  }

  void _startRound(List<Term> terms) {
    _questions = (List<Term>.of(terms)..shuffle(_random))
        .take(widget.questionCount)
        .toList();
    _index = 0;
    _score = 0;
    _finished = false;
    _setUpQuestion();
  }

  List<String> get _words =>
      _questions[_index].exampleSentence.trim().split(RegExp(r'\s+'));

  void _setUpQuestion() {
    if (_questions.isEmpty) {
      return;
    }
    final List<_Token> tokens = <_Token>[
      for (final (int i, String word) in _words.indexed) _Token(i, word),
    ];
    // Karışık hali doğru sırayla aynı olmasın (bütün kelimeler aynıysa
    // farklı bir sıra mümkün değildir).
    final bool canDiffer =
        tokens.map((_Token t) => t.text).toSet().length > 1;
    do {
      tokens.shuffle(_random);
    } while (canDiffer &&
        tokens.map((_Token t) => t.text).join(' ') == _words.join(' '));
    _pool = tokens;
    _answer = <_Token>[];
    _solved = false;
    _wrong = false;
    _hadMistake = false;
  }

  void _pick(_Token token) {
    if (_solved) {
      return;
    }
    setState(() {
      _pool.remove(token);
      _answer.add(token);
      _wrong = false;
    });
  }

  void _unpick(_Token token) {
    if (_solved) {
      return;
    }
    setState(() {
      _answer.remove(token);
      _pool.add(token);
      _wrong = false;
    });
  }

  void _check() {
    final bool correct =
        _answer.map((_Token t) => t.text).join(' ') == _words.join(' ');
    if (!correct) {
      setState(() {
        _wrong = true;
        _hadMistake = true;
      });
      return;
    }
    _finishQuestion(scored: true);
  }

  void _showAnswer() {
    setState(() {
      _answer = <_Token>[
        for (final (int i, String word) in _words.indexed) _Token(i, word),
      ];
      _pool = <_Token>[];
    });
    _finishQuestion(scored: false);
  }

  /// Soruyu bitirir; [scored] ise ve bu soruda yanlış denenmediyse puan
  /// verilir. Otomatik okuma açıksa cümle okunur.
  void _finishQuestion({required bool scored}) {
    ProgressService.instance.recordPractice();
    setState(() {
      if (scored && !_hadMistake) {
        _score++;
      }
      _solved = true;
      _wrong = false;
    });
    TtsService.instance.speakIfAuto(_questions[_index].exampleSentence);
  }

  void _next() {
    TtsService.instance.stop();
    setState(() {
      if (_index >= _questions.length - 1) {
        _finished = true;
        return;
      }
      _index++;
      _setUpQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Build the Sentence'), centerTitle: true),
      body: SafeArea(
        child: FutureBuilder<List<Term>>(
          future: _termsFuture,
          builder: (BuildContext context, AsyncSnapshot<List<Term>> snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
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
                constraints: const BoxConstraints(maxWidth: 640),
                child: _finished
                    ? _buildResult(context, terms)
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
    final Term term = _questions[_index];
    final bool isLast = _index >= _questions.length - 1;
    final String hint = term.turkish.isEmpty
        ? 'Use the word: ${term.displayTerm}'
        : 'Use the word: ${term.displayTerm} · ${term.turkish}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_index + 1} / ${_questions.length}',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Put the words in the right order.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          // Kurulan cümle.
          Container(
            constraints: const BoxConstraints(minHeight: 120),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _solved
                    ? _correctColor
                    : _wrong
                        ? _wrongColor
                        : theme.colorScheme.outline,
                width: 2,
              ),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final _Token token in _answer)
                  _buildChip(token, onTap: () => _unpick(token), filled: true),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 24,
            child: Text(
              _solved
                  ? 'Correct!'
                  : _wrong
                      ? 'Not quite. Tap a word to move it back.'
                      : '',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: _solved ? _correctColor : _wrongColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Kalan kelimeler.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final _Token token in _pool)
                _buildChip(token, onTap: () => _pick(token), filled: false),
            ],
          ),
          const SizedBox(height: 20),
          if (_solved)
            FilledButton.icon(
              onPressed: _next,
              icon: Icon(isLast ? Icons.flag_rounded : Icons.arrow_forward_rounded),
              label: Text(isLast ? 'See results' : 'Next'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _showAnswer,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Show answer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _pool.isEmpty ? _check : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Check'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildChip(
    _Token token, {
    required VoidCallback onTap,
    required bool filled,
  }) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ActionChip(
      label: Text(token.text, style: const TextStyle(fontSize: 18)),
      onPressed: _solved ? null : onTap,
      backgroundColor: filled ? colors.primaryContainer : null,
      side: BorderSide(color: colors.primary),
    );
  }

  Widget _buildResult(BuildContext context, List<Term> terms) {
    final ThemeData theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.emoji_events_rounded,
            size: 96,
            color: _score * 10 >= _questions.length * 6
                ? const Color(0xFFFFB300)
                : theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '$_score / ${_questions.length} correct on the first try',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => setState(() => _startRound(terms)),
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Play again'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.home_rounded),
            label: const Text('Done'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          ),
        ],
      ),
    );
  }
}
