import 'package:auth_engine/auth_engine.dart';
import 'package:auth_screens/src/auth_forms_config.dart';
import 'package:auth_screens/src/auth_screens_config.dart';
import 'package:flutter/services.dart';
import 'package:auth_screens/src/main_action_in_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Signing in or ([signUp]) up with an e-mail address, in one structure:
/// [header], [intro], the e-mail and password fields with the inline error
/// and the main button, the provider buttons, "Forgot password?" (sign-in,
/// with [onForgotPassword]) and [footer] (terms, for example).
///
/// The keyboard moves from e-mail to password and submits from there, or
/// says what is still missing; every
/// trigger (button, keyboard, providers) runs through [CredentialsStateCore.run],
/// so only one is in flight and an error stays on the page. The main button
/// stays above the keyboard ([MainActionInView]).
class EmailAuthBody extends HookWidget {
  final bool signUp;
  final CredentialsStateCore credentials;
  final AuthFlowsCore<Object?> flows;
  final Widget? header;
  final Widget? intro;
  final Widget? footer;
  final VoidCallback? onForgotPassword;
  final List<AuthProvider> providers;

  const EmailAuthBody({
    super.key,
    required this.signUp,
    required this.credentials,
    required this.flows,
    this.header,
    this.intro,
    this.footer,
    this.onForgotPassword,
    this.providers = AuthProvider.values,
  });

  static const submitKey = ValueKey('auth-submit');

  /// Why the form cannot be sent yet, or null when it can.
  String? _missing(AuthFormsStrings l) {
    if (!credentials.isUserNameValid.value) return l.emailInvalid;
    if (signUp) return credentials.isValid.value ? null : l.passwordWeak;
    return credentials.canSignIn.value ? null : l.passwordMissing;
  }

  Future<void> _submit() async {
    if (_missing(AuthForms.strings()) != null) return;
    //* The keyboard goes: the busy button and an error line are then in view.
    FocusManager.instance.primaryFocus?.unfocus();
    final email = credentials.username.value;
    final password = credentials.password.value;
    final ok = await credentials.run(
      () => signUp
          ? flows.createUserWithEmailAndPassword(email: email, password: password)
          : flows.signInWithEmailAndPassword(email: email, password: password),
    );
    if (ok) TextInput.finishAutofillContext(shouldSave: AuthForms.savePassword);
  }

  @override
  Widget build(BuildContext context) {
    final l = AuthForms.strings();
    //* What the keyboard's Go found missing; gone at the next keystroke.
    final missing = useMemoized(() => signal<String?>(null));
    useEffect(() => missing.dispose, [missing]);

    //* The page is built once: only the error line with the main button and
    //* the provider buttons follow the state, each in its own builder.
    return AuthForms.pageOf(context, [
      ?header,
      ?intro,
      AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            AuthForms.field(
              context,
              AuthFieldSpec(
                key: const ValueKey('auth-email'),
                kind: AuthFieldKind.email,
                hint: l.email,
                //* What the state already holds (typed on another page) shows in the field.
                initialValue: credentials.username.peek(),
                onChanged: (value) {
                  missing.value = null;
                  credentials.setUserName(value);
                },
                action: TextInputAction.next,
              ),
            ),
            AuthForms.field(
              context,
              AuthFieldSpec(
                key: const ValueKey('auth-password'),
                kind: signUp ? AuthFieldKind.newPassword : AuthFieldKind.password,
                hint: l.password,
                onChanged: (value) {
                  missing.value = null;
                  credentials.setPassword(value);
                },
                action: TextInputAction.go,
                onSubmitted: (_) {
                  missing.value = _missing(l);
                  if (missing.value == null) _submit();
                },
              ),
            ),
            SignalBuilder(builder: (context) {
              final busy = credentials.busy.value;
              final error = credentials.authError.value;
              final line = error != null ? AuthForms.describe(error) : missing.value;
              final ready = signUp ? credentials.isValid.value : credentials.canSignIn.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [
                  if (line != null) AuthForms.error(context, line),
                  MainActionInView(
                    watch: [credentials.username, credentials.password],
                    child: AuthScreens.button(
                      context,
                      StatusAction(
                        key: submitKey,
                        label: signUp ? l.signUp : l.signIn,
                        icon: signUp ? AuthForms.icons.signUp : AuthForms.icons.signIn,
                        busy: busy,
                        onPressed: ready && !busy ? _submit : null,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
      if (providers.isNotEmpty)
        SignalBuilder(builder: (context) {
          final busy = credentials.busy.value;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 24,
            children: [
              for (final provider in providers)
                AuthForms.providerButton(
                  context,
                  provider,
                  busy,
                  busy
                      ? null
                      : () => credentials.run(switch (provider) {
                          AuthProvider.google => flows.signInWithGoogle,
                          AuthProvider.apple => flows.signInWithApple,
                        }),
                ),
            ],
          );
        }),
      if (!signUp && onForgotPassword != null)
        AuthScreens.button(
          context,
          StatusAction(label: l.forgotPassword, emphasis: StatusEmphasis.quiet, onPressed: onForgotPassword),
        ),
      ?footer,
    ]);
  }
}
