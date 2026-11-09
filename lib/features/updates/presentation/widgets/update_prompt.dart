import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/update_decision.dart';
import '../providers/update_providers.dart';
import 'update_dialog.dart';

/// Wraps the app's content and offers a newer build once per launch.
///
/// A widget rather than a call in `main()` because the dialog needs a
/// Navigator to open in, and because the check should only reach people
/// who are signed in and looking at the app — not someone sitting on the
/// login screen.
class UpdatePrompt extends ConsumerStatefulWidget {
  /// Wraps [child].
  const UpdatePrompt({required this.child, super.key});

  /// The content to show.
  final Widget child;

  @override
  ConsumerState<UpdatePrompt> createState() => _UpdatePromptState();
}

class _UpdatePromptState extends ConsumerState<UpdatePrompt> {
  /// Once per process, not once per screen: the shell rebuilds this widget
  /// on every navigation, and nobody wants the same dialog on each page.
  static bool _hasPrompted = false;

  @override
  void initState() {
    super.initState();
    if (_hasPrompted) {
      return;
    }
    // After the first frame: the Navigator this dialog opens in does not
    // exist while initState runs.
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerUpdate());
  }

  Future<void> _offerUpdate() async {
    if (_hasPrompted) {
      return;
    }
    final decision = await ref.read(updateDecisionProvider.future);
    if (decision.action == UpdateAction.none || !mounted || _hasPrompted) {
      return;
    }
    _hasPrompted = true;
    await UpdateDialog.show(context, decision);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
