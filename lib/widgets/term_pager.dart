import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

import '../models/term.dart';
import '../services/term_repository.dart';
import '../services/tts_service.dart';
import 'message_view.dart';
import 'nav_button.dart';

/// Terimleri rastgele sırayla, kaydırılabilir kartlar halinde gösteren ekran
/// iskeleti. Words ve Sentences ekranları bunu farklı kartlarla kullanır.
///
/// Parmağı sola kaydırınca sonraki kart sağdan gelir. Alttaki butonlarla da
/// geçilebilir; son kartta ileri butonu yerine "Start again" gösterilir.
class TermPager extends StatefulWidget {
  const TermPager({
    super.key,
    required this.title,
    required this.cardBuilder,
    this.repository = const TermRepository(),
    this.speechText,
  });

  final String title;
  final Widget Function(BuildContext context, Term term) cardBuilder;
  final TermRepository repository;

  /// Otomatik okuma açıksa kart ekrana gelince okunacak metin (ör. kelime ya
  /// da cümle). Null ise kartlar kendiliğinden okunmaz.
  final String Function(Term term)? speechText;

  @override
  State<TermPager> createState() => _TermPagerState();
}

class _TermPagerState extends State<TermPager> {
  final PageController _pageController = PageController();
  late Future<List<Term>> _termsFuture;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _termsFuture = widget.repository.loadShuffledTerms();
    // İlk kart yüklenince (otomatik okuma açıksa) okunsun. Yükleme hatası
    // FutureBuilder'da gösterilir; burada yok sayılır.
    _termsFuture.then(
      (List<Term> terms) {
        if (mounted && terms.isNotEmpty) {
          _speakAuto(terms.first);
        }
      },
      onError: (Object _) {},
    );
  }

  void _speakAuto(Term term) {
    if (widget.speechText case final String Function(Term) text) {
      TtsService.instance.speakIfAuto(text(term));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    TtsService.instance.stop();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _currentIndex = 0;
      _load();
    });
  }

  void _goToFirst() {
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _goToNext() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _goToPrevious() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
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
                    : 'Could not load the words.',
                buttonLabel: 'Try again',
                onPressed: _retry,
              );
            }

            final List<Term> terms = snapshot.data ?? const <Term>[];
            if (terms.isEmpty) {
              return const MessageView(
                icon: Icons.inbox_rounded,
                message: 'There are no words yet.',
              );
            }

            return _buildPages(context, terms);
          },
        ),
      ),
    );
  }

  Widget _buildPages(BuildContext context, List<Term> terms) {
    final ThemeData theme = Theme.of(context);
    final bool isFirst = _currentIndex == 0;
    final bool isLast = _currentIndex >= terms.length - 1;

    return Column(
      children: [
        Expanded(
          // Web'de fareyle sürükleyerek de kart geçilebilsin.
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: <PointerDeviceKind>{
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.stylus,
                PointerDeviceKind.trackpad,
              },
            ),
            child: PageView.builder(
              controller: _pageController,
              itemCount: terms.length,
              onPageChanged: (int index) {
                TtsService.instance.stop();
                setState(() => _currentIndex = index);
                _speakAuto(terms[index]);
              },
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Center(
                    child: ConstrainedBox(
                      // Geniş ekranlarda kart aşırı uzamasın.
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: widget.cardBuilder(context, terms[index]),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Row(
            children: [
              NavButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Previous',
                onPressed: isFirst ? null : _goToPrevious,
              ),
              Expanded(
                child: Text(
                  '${_currentIndex + 1} / ${terms.length}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (isLast)
                NavButton(
                  icon: Icons.replay_rounded,
                  tooltip: 'Start again',
                  onPressed: terms.length > 1 ? _goToFirst : null,
                )
              else
                NavButton(
                  icon: Icons.arrow_forward_rounded,
                  tooltip: 'Next',
                  onPressed: _goToNext,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Words ve Sentences kartlarının ortak çerçevesi: kategori rengiyle ince
/// kenarlık, yuvarlak köşeler ve iç boşluk.
class TermCardFrame extends StatelessWidget {
  const TermCardFrame({super.key, required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
      ),
      padding: const EdgeInsets.all(24),
      child: child,
    );
  }
}
