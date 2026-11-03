import 'package:flutter/material.dart';

/// Metni sesli okutan yuvarlak hoparlör butonu.
class SpeakButton extends StatelessWidget {
  const SpeakButton({super.key, required this.onPressed, this.color});

  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onPressed,
      tooltip: 'Listen',
      iconSize: 32,
      padding: const EdgeInsets.all(14),
      style: color == null
          ? null
          : IconButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
      icon: const Icon(Icons.volume_up_rounded),
    );
  }
}
