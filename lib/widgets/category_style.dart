import 'package:flutter/material.dart';

/// Bir kategorinin ekranda görünen adı, simgesi ve rengi.
class CategoryStyle {
  const CategoryStyle(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  static const Map<String, CategoryStyle> _styles = <String, CategoryStyle>{
    'hardware': CategoryStyle('Hardware', Icons.memory_rounded, Color(0xFF5C6BC0)),
    'software': CategoryStyle('Software', Icons.code_rounded, Color(0xFF26A69A)),
    'networking': CategoryStyle('Networking', Icons.lan_rounded, Color(0xFF42A5F5)),
    'security': CategoryStyle('Security', Icons.shield_rounded, Color(0xFFEF5350)),
    'data': CategoryStyle('Data & Cloud', Icons.cloud_rounded, Color(0xFFAB47BC)),
  };

  /// Bilinmeyen kategoriler için gri, genel bir stil.
  static const CategoryStyle fallback =
      CategoryStyle('IT', Icons.computer_rounded, Color(0xFF78909C));

  static CategoryStyle of(String category) =>
      _styles[category.toLowerCase()] ?? fallback;
}

/// Kartların üstündeki küçük kategori etiketi.
class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final CategoryStyle style = CategoryStyle.of(category);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 20, color: style.color),
          const SizedBox(width: 6),
          Text(
            style.label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: style.color,
            ),
          ),
        ],
      ),
    );
  }
}
