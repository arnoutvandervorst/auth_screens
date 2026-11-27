import 'package:auth_engine/auth_engine.dart';
import 'package:auth_screens/auth_forms.dart';
import 'package:auth_screens/auth_screens.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _Flows implements AuthFlowsCore<Object?> {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  Directionality(textDirection: TextDirection.ltr, child: MediaQuery(data: const MediaQueryData(), child: child)),
);

void main() {
  final views = <StatusView>[];
  final actions = <String, StatusAction>{};
  final fields = <AuthFieldSpec>[];
  setUp(() {
    views.clear();
    actions.clear();
    fields.clear();
    AuthScreens.configure(
      layout: (context, view) {
        views.add(view);
        return Column(children: view.buttons);
      },
      button: (context, action) {
        actions[action.label] = action;
        return GestureDetector(key: action.key, onTap: action.onPressed, child: Text(action.label));
      },
      strings: () => const AuthScreensStrings(),
    );
    AuthForms.configure(
      page: (context, children) => Column(children: children),
      field: (context, field) {
        fields.add(field);
        return Text('field ${field.kind.name}', key: field.key);
      },
      providerButton: (context, provider, busy, onPressed) => const SizedBox(),
      error: (context, message) => Text(message),
      text: (context, text) => Text(text),
      describe: (error) => error.name,
    );
  });

  testWidgets('e-mail: a resend or a check that throws releases its button', (tester) async {
    await pump(
      tester,
      EmailNotVerifiedStatus(
        email: 'a@b.c',
        onResend: () async => throw StateError('too-many-requests'),
        resendFailed: const Text('Could not send'),
        onCheck: () async => throw StateError('offline'),
        onSignOut: () {},
      ),
    );
    await tester.tap(find.text('Send the e-mail again'));
    await tester.pump();
    expect(actions['Send the e-mail again']!.busy, isFalse);
    expect(views.last.extra, isA<Text>());

    //* The failure still reaches the caller (the app's error report).
    final check = actions['I have confirmed it']!.onPressed! as Future<void> Function();
    await expectLater(check(), throwsStateError);
    await tester.pump();
    expect(actions['I have confirmed it']!.busy, isFalse);
  });

  testWidgets('the e-mail field shows the address the state already holds', (tester) async {
    final credentials = CredentialsStateCore(isEmailValid: (email) => email.contains('@'), isPasswordStrong: (_) => true)
      ..setUserName('a@b.c');
    final flows = _Flows();
    await pump(tester, EmailAuthBody(signUp: false, credentials: credentials, flows: flows, providers: const []));
    expect(fields.firstWhere((field) => field.kind == AuthFieldKind.email).initialValue, 'a@b.c');
    fields.clear();
    await pump(tester, ResetPasswordBody(credentials: credentials, flows: flows, onBack: () {}, onSent: () {}, onFailed: () {}));
    expect(fields.single.initialValue, 'a@b.c');
    credentials.dispose();
  });
}
