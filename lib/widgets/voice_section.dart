import 'package:flutter/material.dart';

import '../services/tts_service.dart';

/// Seslendirme sesi seçimi: "Automatic" (en doğal ses otomatik seçilir) ya
/// da cihazdaki İngilizce seslerden biri. "Test" ile denenebilir.
class VoiceSection extends StatefulWidget {
  const VoiceSection({super.key});

  @override
  State<VoiceSection> createState() => _VoiceSectionState();
}

class _VoiceSectionState extends State<VoiceSection> {
  static const String _sample = 'This is how words and sentences will sound.';

  late final Future<List<TtsVoice>> _voicesFuture =
      TtsService.instance.englishVoices();

  /// Kaydedilmiş seçim; null ise otomatik.
  String? _selected;
  bool _loadedSelection = false;

  @override
  void initState() {
    super.initState();
    TtsService.instance.savedVoiceName().then((String? name) {
      if (mounted) {
        setState(() {
          _selected = name;
          _loadedSelection = true;
        });
      }
    });
  }

  Future<void> _select(String? name) async {
    setState(() => _selected = name);
    await TtsService.instance.selectVoice(name);
    await TtsService.instance.speak(_sample);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return FutureBuilder<List<TtsVoice>>(
      future: _voicesFuture,
      builder: (BuildContext context, AsyncSnapshot<List<TtsVoice>> snapshot) {
        final List<TtsVoice> voices = snapshot.data ?? const <TtsVoice>[];
        if (snapshot.connectionState != ConnectionState.done ||
            !_loadedSelection) {
          return const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (voices.isEmpty) {
          return Text(
            'No English voices were found on this device. The default voice '
            'is used.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );
        }
        // Kayıtlı ses artık cihazda yoksa otomatik göster.
        final String? value = voices.any((TtsVoice v) => v.name == _selected)
            ? _selected
            : null;

        return Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                initialValue: value,
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    child: Text('Automatic (best available)'),
                  ),
                  for (final TtsVoice voice in voices)
                    DropdownMenuItem<String?>(
                      value: voice.name,
                      child: Text(
                        '${voice.name} (${voice.locale})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: _select,
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => TtsService.instance.speak(_sample),
              icon: const Icon(Icons.volume_up_rounded),
              label: const Text('Test'),
            ),
          ],
        );
      },
    );
  }
}
