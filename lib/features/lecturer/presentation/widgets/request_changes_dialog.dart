import 'package:flutter/material.dart';

/// Dialog collecting a lecturer's comments before requesting changes on a
/// logbook entry.
///
/// Returns the entered comments via [Navigator.pop], or `null` if
/// cancelled.
class RequestChangesDialog extends StatefulWidget {
  /// Creates the request-changes dialog.
  const RequestChangesDialog({super.key});

  @override
  State<RequestChangesDialog> createState() => _RequestChangesDialogState();
}

class _RequestChangesDialogState extends State<RequestChangesDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request Changes'),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        autofocus: true,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          labelText: 'What needs to change?',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Send'),
        ),
      ],
    );
  }
}
