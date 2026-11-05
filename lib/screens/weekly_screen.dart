import 'package:flutter/material.dart';

import '../models/weekly_pack.dart';
import '../services/pack_service.dart';
import '../services/term_repository.dart';
import '../widgets/locked_card.dart';
import '../widgets/menu_card.dart';
import '../widgets/message_view.dart';
import '../widgets/progress_footer.dart';
import '../widgets/section_icon.dart';
import 'section_screen.dart';

/// "Mon, 9 Nov" biçiminde kısa tarih (intl paketine gerek kalmasın diye).
String formatShortDate(DateTime date) {
  const List<String> days = <String>[
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', //
  ];
  const List<String> months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
  ];
  return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
}

/// Haftalık paketler: açılmış olanlar (en yenisi başta) ve kilitli bir
/// sonraki paket.
class WeeklyScreen extends StatefulWidget {
  const WeeklyScreen({super.key});

  @override
  State<WeeklyScreen> createState() => _WeeklyScreenState();
}

class _WeeklyScreenState extends State<WeeklyScreen> {
  final PackService _packs = PackService.instance;
  late final Future<(List<WeeklyPack>, WeeklyPack?)> _future = _load();

  Future<(List<WeeklyPack>, WeeklyPack?)> _load() async =>
      (await _packs.releasedPacks(), await _packs.nextPack());

  void _open(WeeklyPack pack, TermRepository repository) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => SectionScreen(
          section: pack.toSection(),
          repository: repository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Words'), centerTitle: true),
      body: SafeArea(
        child: FutureBuilder<(List<WeeklyPack>, WeeklyPack?)>(
          future: _future,
          builder: (
            BuildContext context,
            AsyncSnapshot<(List<WeeklyPack>, WeeklyPack?)> snapshot,
          ) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final (List<WeeklyPack> released, WeeklyPack? next) =
                snapshot.data ?? (const <WeeklyPack>[], null);
            if (released.isEmpty && next == null) {
              return const MessageView(
                icon: Icons.inbox_rounded,
                message: 'There are no weekly packs yet.',
              );
            }

            return Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '40 new work and IT words every Monday.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 24),
                      if (next != null) ...[
                        _LockedPackCard(
                          pack: next,
                          daysLeft: _packs.daysUntil(next),
                        ),
                        const SizedBox(height: 16),
                      ],
                      for (final (int i, WeeklyPack pack)
                          in released.indexed) ...[
                        _buildPackCard(pack, isNewest: i == 0),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPackCard(WeeklyPack pack, {required bool isNewest}) {
    final TermRepository repository = _packs.repositoryFor(pack);
    final String quizId = pack.toSection().assetPath;
    // En yeni paket, açıldığı haftanın içindeyse "yeni" diye işaretlenir.
    final bool isNew = isNewest &&
        DateTime.now().difference(pack.releaseDate).inDays < 7;

    return MenuCard(
      title: pack.title,
      subtitle: isNew ? 'New this week · ${pack.subtitle}' : pack.subtitle,
      icon: sectionIcon(pack.toSection().kind),
      onTap: () => _open(pack, repository),
      footer: ProgressFooter(
        repositories: <TermRepository>[repository],
        quizId: quizId,
      ),
    );
  }
}

/// Henüz açılmamış paketin kartı: kilit simgesi ve açılış tarihi.
class _LockedPackCard extends StatelessWidget {
  const _LockedPackCard({required this.pack, required this.daysLeft});

  final WeeklyPack pack;
  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    final String when = switch (daysLeft) {
      0 => 'today',
      1 => 'tomorrow',
      _ => 'in $daysLeft days',
    };

    return LockedCard(
      title: pack.title,
      message: 'Unlocks ${formatShortDate(pack.releaseDate)} ($when)',
    );
  }
}

/// Ana ekrandaki Weekly Words kartının alt yazısı: açık paket sayısı ve
/// sıradakinin ne zaman açılacağı.
class WeeklyFooter extends StatefulWidget {
  const WeeklyFooter({super.key});

  @override
  State<WeeklyFooter> createState() => _WeeklyFooterState();
}

class _WeeklyFooterState extends State<WeeklyFooter> {
  late final Future<String> _text = _load();

  Future<String> _load() async {
    final PackService packs = PackService.instance;
    final int released = (await packs.releasedPacks()).length;
    final WeeklyPack? next = await packs.nextPack();
    final String opened =
        released == 1 ? '1 pack unlocked' : '$released packs unlocked';
    if (next == null) {
      return opened;
    }
    final int days = packs.daysUntil(next);
    final String when = switch (days) {
      0 => 'today',
      1 => 'tomorrow',
      _ => 'in $days days',
    };
    return '$opened · next $when';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return FutureBuilder<String>(
      future: _text,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        final String? text = snapshot.data;
        if (text == null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        );
      },
    );
  }
}
