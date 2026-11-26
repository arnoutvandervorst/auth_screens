import 'package:auth_engine/auth_engine.dart';
import 'package:auth_screens/src/auth_forms_config.dart';
import 'package:auth_screens/src/auth_screens_config.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Signing in or ([signUp]) up with an e-mail address, in one structure:
/// [header], [intro], the e-mail and password fields with the inline error
/// and the main button, the provider buttons, "Forgot password?" (sign-in,
/// with [onForgotPassword]) and [footer] (terms, for example).
///
/// The keyboard moves from e-mail to password and submits from there; every
/// trigger (button, keyboard, providers) runs through [CredentialsStateCore.run],
/// so only one is in flight and an error stays on the page.
class EmailAuthBody extends StatelessWidget {
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

  Future<void> _submit() async {
    final ready = signUp ? credentials.isValid.value : credentials.canSignIn.value;
    if (!ready) return;
    final email = credentials.username.value;
    final password = credentials.password.value;
    final ok = await credentials.run(
      () => signUp
          ? flows.createUserWithEmailAndPassword(email: email, password: password)
          : flows.signInWithEmailAndPassword(email: email, password: password),
    );
    if (ok) TextInput.finishAutofillContext(shouldSave: true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AuthForms.strings();
    return SignalBuilder(builder: (context) {
      final busy = credentials.busy.value;
      final error = credentials.authError.value;
      final ready = signUp ? credentials.isValid.value : credentials.canSignIn.value;
      return AuthForms.page(context, [
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
                  onChanged: credentials.setUserName,
                  action: TextInputAction.next,
                ),
              ),
              AuthForms.field(
                context,
                AuthFieldSpec(
                  key: const ValueKey('auth-password'),
                  kind: signUp ? AuthFieldKind.newPassword : AuthFieldKind.password,
                  hint: l.password,
                  onChanged: credentials.setPassword,
                  action: TextInputAction.go,
                  onSubmitted: (_) => _submit(),
                ),
              ),
              if (error != null) AuthForms.error(context, AuthForms.describe(error)),
              AuthScreens.button(
                context,
                StatusAction(
                  key: submitKey,
                  label: signUp ? l.signUp : l.signIn,
                  busy: busy,
                  onPressed: ready && !busy ? _submit : null,
                ),
              ),
            ],
          ),
        ),
        if (providers.isNotEmpty)
          Row(
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
          ),
        if (!signUp && onForgotPassword != null)
          AuthScreens.button(
            context,
            StatusAction(label: l.forgotPassword, emphasis: StatusEmphasis.quiet, onPressed: onForgotPassword),
          ),
        ?footer,
      ]);
    });
  }
}
