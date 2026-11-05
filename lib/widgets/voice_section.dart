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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ReadingModeSelector(),
        const SizedBox(height: 16),
        _buildVoicePicker(context),
      ],
    );
  }

  Widget _buildVoicePicker(BuildContext context) {
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

/// Okuma şekli: yalnızca hoparlör butonuna basınca ya da kendiliğinden
/// (kart ekrana gelince, quiz'de soru çözülünce).
class ReadingModeSelector extends StatefulWidget {
  const ReadingModeSelector({super.key});

  @override
  State<ReadingModeSelector> createState() => _ReadingModeSelectorState();
}

class _ReadingModeSelectorState extends State<ReadingModeSelector> {
  bool _auto = TtsService.defaultAutoSpeak;

  @override
  void initState() {
    super.initState();
    TtsService.instance.autoSpeak().then((bool value) {
      if (mounted) {
        setState(() => _auto = value);
      }
    });
  }

  Future<void> _set(bool auto) async {
    setState(() => _auto = auto);
    await TtsService.instance.setAutoSpeak(auto);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<bool>(
          segments: const <ButtonSegment<bool>>[
            ButtonSegment<bool>(
              value: false,
              icon: Icon(Icons.touch_app_rounded),
              label: Text('On tap'),
            ),
            ButtonSegment<bool>(
              value: true,
              icon: Icon(Icons.record_voice_over_rounded),
              label: Text('Automatic'),
            ),
          ],
          selected: <bool>{_auto},
          onSelectionChanged: (Set<bool> selection) => _set(selection.first),
        ),
        const SizedBox(height: 8),
        Text(
          _auto
              ? 'Words and sentences are read aloud when a card appears and '
                  'after you answer a quiz question.'
              : 'Words and sentences are read only when you tap the speaker '
                  'button.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
