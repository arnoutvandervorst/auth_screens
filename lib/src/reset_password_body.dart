import 'package:auth_engine/auth_engine.dart';
import 'package:auth_screens/src/auth_forms_config.dart';
import 'package:auth_screens/src/auth_screens_config.dart';
import 'package:auth_screens/src/main_action_in_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Asking for a new password: [header], what happens, the e-mail field, the
/// send button and Back to sign in ([onBack]). After the e-mail went out
/// [onSent] (the app confirms it); when it failed [onFailed].
class ResetPasswordBody extends HookWidget {
  final CredentialsStateCore credentials;
  final AuthFlowsCore<Object?> flows;
  final Widget? header;
  final VoidCallback onBack;
  final VoidCallback onSent;
  final VoidCallback onFailed;

  const ResetPasswordBody({
    super.key,
    required this.credentials,
    required this.flows,
    required this.onBack,
    required this.onSent,
    required this.onFailed,
    this.header,
  });

  static const sendKey = ValueKey('auth-reset-send');

  @override
  Widget build(BuildContext context) {
    final l = AuthForms.strings();
    final busy = useMemoized(() => signal(false));
    useEffect(() => busy.dispose, [busy]);

    Future<void> send() async {
      if (busy.value || !credentials.isUserNameValid.value) return;
      FocusManager.instance.primaryFocus?.unfocus();
      busy.value = true;
      try {
        await flows.sendPasswordResetEmail(email: credentials.username.value);
      } catch (_) {
        if (context.mounted) busy.value = false;
        onFailed();
        return;
      }
      if (!context.mounted) return;
      busy.value = false;
      onSent();
    }

    //* The page is built once: only the send button follows the state.
    return AuthForms.pageOf(context, [
      ?header,
      AuthForms.text(context, l.resetIntro),
      AuthForms.field(
        context,
        AuthFieldSpec(
          key: const ValueKey('auth-email'),
          kind: AuthFieldKind.email,
          hint: l.email,
          onChanged: credentials.setUserName,
          onSubmitted: (_) => send(),
        ),
      ),
      MainActionInView(
        watch: [credentials.username],
        child: SignalBuilder(builder: (context) {
          final ready = credentials.isUserNameValid.value && !busy.value;
          return AuthScreens.button(
            context,
            StatusAction(key: sendKey, label: l.reset, icon: AuthForms.icons.reset, busy: busy.value, onPressed: ready ? send : null),
          );
        }),
      ),
      AuthScreens.button(context, StatusAction(label: l.backToSignIn, emphasis: StatusEmphasis.quiet, onPressed: onBack)),
    ]);
  }
}
