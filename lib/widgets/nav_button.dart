import 'package:flutter/material.dart';

/// Alt çubuktaki yalnızca simgeli geçiş butonu.
/// [onPressed] null ise buton soluk ve pasif görünür.
class NavButton extends StatelessWidget {
  const NavButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 80,
        height: 60,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Icon(icon, size: 34),
        ),
      ),
    );
  }
}
