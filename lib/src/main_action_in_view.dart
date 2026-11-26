import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Keeps a form's main button above the keyboard: when the keyboard comes up,
/// when the form is rebuilt and when one of [watch] changes (typing can grow the form: a strength
/// meter, an error line), the page scrolls just far enough to show [child]
/// whole. Does nothing while the keyboard is down or the button is in view.
class MainActionInView extends StatefulWidget {
  final List<ReadonlySignal<Object?>> watch;
  final Widget child;

  const MainActionInView({super.key, required this.watch, required this.child});

  @override
  State<MainActionInView> createState() => _MainActionInViewState();
}

class _MainActionInViewState extends State<MainActionInView> with WidgetsBindingObserver {
  late final void Function() _stop;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _stop = effect(() {
      for (final signal in widget.watch) {
        signal.value;
      }
      _keep();
    });
  }

  @override
  void dispose() {
    _stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() => _keep();

  //* The form was rebuilt: a line may have come in above the button.
  @override
  void didUpdateWidget(MainActionInView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _keep();
  }

  //* After the frame: the keyboard's inset and the form's new height are laid out by then.
  void _keep() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted || View.of(context).viewInsets.bottom <= 0) return;
    if (Scrollable.maybeOf(context) == null) return;
    Scrollable.ensureVisible(context, alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
  });

  @override
  Widget build(BuildContext context) => widget.child;
}
