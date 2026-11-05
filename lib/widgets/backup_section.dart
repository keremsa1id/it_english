import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../services/progress_service.dart';

/// İlerlemeyi yedekleme: dışa aktarılan metin panoya kopyalanır ve telefonda
/// paylaşma menüsüyle de gönderilebilir; içe aktarırken metin yapıştırılır ve
/// onay sorulur.
class BackupSection extends StatelessWidget {
  const BackupSection({super.key});

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _export(BuildContext context) async {
    final String backup;
    try {
      backup = await ProgressService.instance.exportBackup();
    } on StateError catch (error) {
      if (context.mounted) {
        _showMessage(context, error.message);
      }
      return;
    }
    await Clipboard.setData(ClipboardData(text: backup));
    if (!context.mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Backup copied'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your progress was copied to the clipboard. Paste it into an '
                'email, a note or a chat to keep it safe. On your new phone, '
                'use "Import progress" and paste it there.',
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: SelectableText(
                    backup,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Telefonun paylaşma menüsü (e-posta, WhatsApp, Drive...). Webde
          // masaüstü tarayıcılar bunu her zaman desteklemediği için yalnızca
          // panoya kopyalama kullanılır.
          if (!kIsWeb)
            TextButton.icon(
              onPressed: () => _share(context, backup),
              icon: const Icon(Icons.share_rounded),
              label: const Text('Share'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _share(BuildContext context, String backup) async {
    try {
      await SharePlus.instance.share(ShareParams(text: backup));
    } catch (error) {
      if (context.mounted) {
        _showMessage(
          context,
          'Sharing is not available. The backup is still in your clipboard.',
        );
      }
    }
  }

  Future<void> _import(BuildContext context) async {
    final String? raw = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const _ImportDialog(),
    );
    if (raw == null || raw.trim().isEmpty || !context.mounted) {
      return;
    }
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Replace your progress?'),
            content: const Text(
              'Your current progress on this device will be replaced by the '
              'backup. This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Replace'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) {
      return;
    }
    try {
      await ProgressService.instance.importBackup(raw);
      if (context.mounted) {
        _showMessage(context, 'Progress restored.');
      }
    } on FormatException catch (error) {
      if (context.mounted) {
        _showMessage(context, error.message);
      }
    } on StateError catch (error) {
      if (context.mounted) {
        _showMessage(context, error.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _export(context),
            icon: const Icon(Icons.upload_rounded),
            label: const Text('Export progress'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _import(context),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Import progress'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ),
      ],
    );
  }
}

/// Yedek metninin yapıştırıldığı pencere; "Import"a basılınca metni döndürür.
class _ImportDialog extends StatefulWidget {
  const _ImportDialog();

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text case final String text) {
      _controller.text = text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import progress'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Paste your backup here',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _paste,
                icon: const Icon(Icons.content_paste_rounded),
                label: const Text('Paste from clipboard'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Import'),
        ),
      ],
    );
  }
}
