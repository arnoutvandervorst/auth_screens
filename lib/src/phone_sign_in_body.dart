import 'package:auth_engine/auth_engine.dart';
import 'package:auth_screens/src/auth_forms_config.dart';
import 'package:auth_screens/src/auth_screens_config.dart';
import 'package:auth_screens/src/main_action_in_view.dart';
import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Signing in with a phone number in two steps: the number and Send the
/// code; then the code, Sign in and Use another number. The state is
/// auth_engine's [PhoneLoginState]; errors show inline.
class PhoneSignInBody extends StatelessWidget {
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

    Widget error() => SignalBuilder(builder: (context) {
      final error = state.errorAuthError.value;
      return error == null ? const SizedBox.shrink() : AuthForms.error(context, AuthForms.describe(error));
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
                onChanged: (value) => state.phoneNumber.value = value,
                onSubmitted: (_) => busy ? null : state.sendOtp(),
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
                StatusAction(key: sendKey, label: l.sendCode, icon: AuthForms.icons.sendCode, busy: busy, onPressed: busy ? null : () => closing(state.sendOtp)),
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
                onChanged: (value) => state.smsCode.value = value,
                onSubmitted: (_) => busy ? null : state.submitOtp(),
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
                StatusAction(key: verifyKey, label: l.verifyCode, icon: AuthForms.icons.verifyCode, busy: busy, onPressed: busy ? null : () => closing(state.submitOtp)),
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
