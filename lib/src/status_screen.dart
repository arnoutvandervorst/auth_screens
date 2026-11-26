import 'dart:async';

import 'package:auth_screens/src/auth_screens_config.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Everything that parks the app instead of showing it, in one structure:
/// a title, a body, an optional block and the actions, drawn by the app's
/// [AuthScreens.layout].
///
/// [busy]: the line shows after [kMessageAfter] (most starts are done by
/// then), and after [kSlowAfter] "this takes longer than usual" with Try
/// again ([onRetry]). Still: everything at once. [visual] is the app's
/// picture of this state, handed to the layout as it is. [buttons] are drawn by the
/// app already (a case the data in [actions] does not cover); they follow
/// [actions].
class StatusScreen extends HookWidget {
  final bool busy;
  final String? title;
  final String? body;
  final Widget? visual;
  final Widget? extra;
  final List<StatusAction> actions;
  final List<Widget> buttons;
  final VoidCallback? onRetry;

  const StatusScreen({
    super.key,
    this.busy = false,
    this.title,
    this.body,
    this.visual,
    this.extra,
    this.actions = const [],
    this.buttons = const [],
    this.onRetry,
  });

  static const Duration kMessageAfter = Duration(milliseconds: 1500);
  static const Duration kSlowAfter = Duration(seconds: 10);

  @override
  Widget build(BuildContext context) {
    final l = AuthScreens.strings();
    final elapsed = useState(Duration.zero);
    useEffect(() {
      if (!busy) return null;
      elapsed.value = Duration.zero;
      final timers = [
        Timer(kMessageAfter, () => elapsed.value = kMessageAfter),
        Timer(kSlowAfter, () => elapsed.value = kSlowAfter),
      ];
      return () {
        for (final timer in timers) {
          timer.cancel();
        }
      };
    }, [busy]);
    final slow = busy && elapsed.value >= kSlowAfter;
    final showMessage = !busy || elapsed.value >= kMessageAfter || MediaQuery.maybeDisableAnimationsOf(context) == true;
    final List<Widget> drawn;
    if (slow) {
      drawn = [if (onRetry != null) AuthScreens.button(context, StatusAction(label: l.retry, onPressed: onRetry))];
    } else if (busy) {
      drawn = const [];
    } else {
      drawn = [for (final action in actions) AuthScreens.button(context, action), ...buttons];
    }
    return AuthScreens.layout(
      context,
      StatusView(
        busy: busy,
        showMessage: showMessage,
        slow: slow,
        title: slow ? l.slowTitle : title,
        body: slow ? l.slowBody : body,
        visual: visual,
        extra: slow || busy ? null : extra,
        buttons: drawn,
      ),
    );
  }
}
