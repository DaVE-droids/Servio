import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Navigation helpers shared by the app's persistent controls.
extension AppNavigation on BuildContext {
  /// Opens [location] on top of the current page, unless that page is
  /// already [location].
  ///
  /// The bell, the account menu, and the coordinator's audit history sit in
  /// the top bar of every screen — including those screens themselves. A
  /// plain `push` stacked a fresh copy on each tap, so tapping the bell
  /// four times meant pressing Back four times to get out again.
  ///
  /// Returns the pushed page's result, so callers can still wait for the
  /// user to come back (the bell refreshes its unread count that way); when
  /// the push is skipped it completes immediately.
  Future<T?> pushUnlessCurrent<T extends Object?>(String location) {
    if (GoRouter.of(this).state.uri.path == location) {
      return Future<T?>.value();
    }
    return push<T>(location);
  }
}
