import 'package:auth_engine/auth_engine.dart';
import 'package:auth_screens/src/auth_forms_config.dart';
import 'package:auth_screens/src/auth_screens_config.dart';
import 'package:auth_screens/src/main_action_in_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Signing in with a phone number in two steps: the number and Send the
/// code; then the code, Sign in and Use another number. The state is
/// auth_engine's [PhoneLoginState]; errors show inline.
class PhoneSignInBody extends HookWidget {
  final PhoneLoginState state;
  final Widget? header;

  const PhoneSignInBody({super.key, required this.state, this.header});

  static const sendKey = ValueKey('auth-phone-send');
  static const verifyKey = ValueKey('auth-phone-verify');

  @override
  Widget build(BuildContext context) {
    final l = AuthForms.strings();
    //* The keyboard goes with the tap: the busy button and an error line are then in view.
    void closing(void Function() action) {
      FocusManager.instance.primaryFocus?.unfocus();
      action();
    }

    //* An empty number or code is said in its own words, before the state is asked.
    final missing = useMemoized(() => signal<String?>(null));
    useEffect(() => missing.dispose, [missing]);
    void send() {
      missing.value = state.phoneNumber.value.trim().isEmpty ? l.phoneMissing : null;
      if (missing.value == null) closing(state.sendOtp);
    }

    void verify() {
      missing.value = state.smsCode.value.trim().isEmpty ? l.codeMissing : null;
      if (missing.value == null) closing(state.submitOtp);
    }

    Widget error() => SignalBuilder(builder: (context) {
      final error = state.errorAuthError.value;
      final failed = state.codeSent.value ? null : l.sendCodeFailed;
      final line = error == null ? missing.value : failed ?? AuthForms.describe(error);
      return line == null ? const SizedBox.shrink() : AuthForms.error(context, line);
    });

    //* The page follows the step only; a field, a button and the error line
    //* each follow what they show.
    return SignalBuilder(builder: (context) {
      final codeSent = state.codeSent.value;
      return AuthForms.pageOf(context, [
        ?header,
        AuthForms.text(context, l.phoneIntro),
        if (!codeSent) ...[
          SignalBuilder(builder: (context) {
            final busy = state.isLoading.value;
            return AuthForms.field(
              context,
              AuthFieldSpec(
                key: const ValueKey('phone_input'),
                kind: AuthFieldKind.phone,
                hint: l.phoneLabel,
                helper: l.phoneHelper,
                initialValue: state.phoneNumber.peek(),
                onChanged: (value) {
                  missing.value = null;
                  state.phoneNumber.value = value;
                },
                onSubmitted: (_) => busy ? null : send(),
                autofocus: true,
                enabled: !busy,
              ),
            );
          }),
          MainActionInView(
            watch: [state.phoneNumber, state.errorAuthError],
            child: SignalBuilder(builder: (context) {
              final busy = state.isLoading.value;
              return AuthScreens.button(
                context,
                StatusAction(key: sendKey, label: l.sendCode, icon: AuthForms.icons.sendCode, busy: busy, onPressed: busy ? null : send),
              );
            }),
          ),
          error(),
        ] else ...[
          SignalBuilder(builder: (context) {
            final busy = state.isLoading.value;
            return AuthForms.field(
              context,
              AuthFieldSpec(
                key: const ValueKey('otp_input'),
                kind: AuthFieldKind.code,
                hint: l.codeLabel,
                helper: l.codeHelper(state.phoneNumber.peek()),
                onChanged: (value) {
                  missing.value = null;
                  state.smsCode.value = value;
                },
                onSubmitted: (_) => busy ? null : verify(),
                autofocus: true,
                enabled: !busy,
              ),
            );
          }),
          MainActionInView(
            watch: [state.smsCode, state.errorAuthError],
            child: SignalBuilder(builder: (context) {
              final busy = state.isLoading.value;
              return AuthScreens.button(
                context,
                StatusAction(key: verifyKey, label: l.verifyCode, icon: AuthForms.icons.verifyCode, busy: busy, onPressed: busy ? null : verify),
              );
            }),
          ),
          SignalBuilder(builder: (context) {
            final busy = state.isLoading.value;
            return AuthScreens.button(
              context,
              StatusAction(label: l.changePhoneNumber, emphasis: StatusEmphasis.quiet, onPressed: busy ? null : state.changePhoneNumber),
            );
          }),
          error(),
        ],
      ]);
    });
  }
}
