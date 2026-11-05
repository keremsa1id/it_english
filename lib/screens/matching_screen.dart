import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/term.dart';
import '../services/progress_service.dart';
import '../services/term_repository.dart';
import '../widgets/message_view.dart';
import '../widgets/study_timer.dart';

/// Eşleştirme oyunu: her turda 6 İngilizce kelime solda, Türkçe karşılıkları
/// sağda karışık durur. Önce bir kelimeye, sonra karşılığına dokunulur.
/// Doğru çiftler yeşile döner; yanlış seçim kısa süre turuncu yanar.
class MatchingScreen extends StatefulWidget {
  const MatchingScreen({
    super.key,
    required this.repository,
    this.include,
    this.emptyMessage = 'There are not enough words to play.',
  });

  final TermRepository repository;

  /// Verilirse yalnızca bunu sağlayan kelimeler kullanılır.
  final bool Function(Term term)? include;
  final String emptyMessage;

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen>
    with StudyTimer<MatchingScreen> {
  static const int _pairsPerRound = 6;
  static const Color _correctColor = Color(0xFF2E7D32);
  static const Color _wrongColor = Color(0xFFFFA726);

  final Random _random = Random();
  late Future<List<Term>> _termsFuture;

  List<Term> _left = const <Term>[];
  List<Term> _right = const <Term>[];
  final Set<Term> _matched = <Term>{};
  Term? _selectedLeft;
  Term? _selectedRight;
  (Term, Term)? _wrongPair;
  Timer? _wrongTimer;
  int _round = 0;
  int _mistakes = 0;

  @override
  void initState() {
    super.initState();
    _termsFuture = _loadTerms();
  }

  @override
  void dispose() {
    _wrongTimer?.cancel();
    super.dispose();
  }

  Future<List<Term>> _loadTerms() async {
    final List<Term> terms = (await widget.repository.loadTerms())
        .where((Term t) =>
            t.turkish.isNotEmpty && (widget.include?.call(t) ?? true))
        .toList();
    _startRound(terms);
    return terms;
  }

  /// Yeni tur: aynı Türkçe karşılığa sahip kelimeler aynı tura girmez ki
  /// eşleştirme belirsiz olmasın.
  void _startRound(List<Term> terms) {
    final List<Term> shuffled = List<Term>.of(terms)..shuffle(_random);
    final Set<String> usedMeanings = <String>{};
    final List<Term> round = <Term>[
      for (final Term term in shuffled)
        if (usedMeanings.add(term.turkish.toLowerCase())) term,
    ].take(_pairsPerRound).toList();

    _left = List<Term>.of(round)..shuffle(_random);
    _right = List<Term>.of(round)..shuffle(_random);
    _matched.clear();
    _selectedLeft = null;
    _selectedRight = null;
    _wrongPair = null;
    _round++;
  }

  bool get _roundComplete => _left.isNotEmpty && _matched.length == _left.length;

  void _onLeftTap(Term term) {
    if (_matched.contains(term) || _wrongPair != null) {
      return;
    }
    setState(() => _selectedLeft = term);
    _checkPair();
  }

  void _onRightTap(Term term) {
    if (_matched.contains(term) || _wrongPair != null) {
      return;
    }
    setState(() => _selectedRight = term);
    _checkPair();
  }

  void _checkPair() {
    final Term? left = _selectedLeft;
    final Term? right = _selectedRight;
    if (left == null || right == null) {
      return;
    }
    if (identical(left, right)) {
      ProgressService.instance.recordPractice();
      setState(() {
        _matched.add(left);
        _selectedLeft = null;
        _selectedRight = null;
      });
      return;
    }
    setState(() {
      _mistakes++;
      _wrongPair = (left, right);
    });
    _wrongTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _wrongPair = null;
          _selectedLeft = null;
          _selectedRight = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Match the Words'), centerTitle: true),
      body: SafeArea(
        child: FutureBuilder<List<Term>>(
          future: _termsFuture,
          builder: (BuildContext context, AsyncSnapshot<List<Term>> snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final List<Term> terms = snapshot.data ?? const <Term>[];
            if (_left.length < 2) {
              return MessageView(
                icon: Icons.inbox_rounded,
                message: widget.emptyMessage,
              );
            }
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: _buildBoard(context, terms),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBoard(BuildContext context, List<Term> terms) {
    final ThemeData theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Round $_round  ·  Mistakes: $_mistakes',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    for (final Term term in _left)
                      _buildTile(
                        label: term.term,
                        term: term,
                        selected: identical(_selectedLeft, term),
                        wrong: identical(_wrongPair?.$1, term),
                        onTap: () => _onLeftTap(term),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    for (final Term term in _right)
                      _buildTile(
                        label: term.turkish,
                        term: term,
                        selected: identical(_selectedRight, term),
                        wrong: identical(_wrongPair?.$2, term),
                        onTap: () => _onRightTap(term),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_roundComplete) ...[
            Text(
              'Round complete!',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: _correctColor,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => setState(() => _startRound(terms)),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Next round'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('Done'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTile({
    required String label,
    required Term term,
    required bool selected,
    required bool wrong,
    required VoidCallback onTap,
  }) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool matched = _matched.contains(term);
    final Color color = matched
        ? _correctColor
        : wrong
            ? _wrongColor
            : colors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: matched ? 0.5 : 1.0,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: matched ? null : onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: selected ? colors.onPrimary : color,
              backgroundColor: selected
                  ? colors.primary
                  : (matched || wrong ? color.withValues(alpha: 0.12) : null),
              disabledForegroundColor: _correctColor,
              side: BorderSide(color: color, width: selected || wrong ? 2.5 : 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
