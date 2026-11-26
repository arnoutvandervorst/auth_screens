import 'package:auth_engine/auth_engine.dart';
import 'package:auth_screens/auth_forms.dart';
import 'package:auth_screens/auth_screens.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _Flows implements AuthFlowsCore<Object?> {
  final calls = <String>[];
  AuthError? answer;

  @override
  Future<AuthError?> signInWithEmailAndPassword({required String email, required String password}) async {
    calls.add('signIn $email');
    return answer;
  }

  @override
  Future<AuthError?> createUserWithEmailAndPassword({required String email, required String password}) async {
    calls.add('signUp $email');
    return answer;
  }

  @override
  Future<AuthError?> signInWithGoogle() async {
    calls.add('google');
    return null;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async => calls.add('reset $email');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  Directionality(textDirection: TextDirection.ltr, child: MediaQuery(data: const MediaQueryData(), child: child)),
);

void main() {
  final fields = <AuthFieldSpec>[];
  setUp(() {
    fields.clear();
    AuthScreens.configure(
      layout: (context, view) => const SizedBox(),
      button: (context, action) => GestureDetector(key: action.key, onTap: action.onPressed, child: Text(action.label)),
    );
    AuthForms.configure(
      page: (context, children) => Column(children: children),
      field: (context, field) {
        fields.add(field);
        return Text('field ${field.kind.name}', key: field.key);
      },
      providerButton: (context, provider, busy, onPressed) => GestureDetector(onTap: onPressed, child: Text(provider.name)),
      error: (context, message) => Text('error $message'),
      text: (context, text) => Text(text),
      describe: (error) => error.name,
    );
  });

  CredentialsStateCore credentials() =>
      CredentialsStateCore(isEmailValid: (email) => email.contains('@'), isPasswordStrong: (password) => password.length >= 8);

  testWidgets('sign-in: e-mail moves on, the password submits; the button waits for a valid form', (tester) async {
    final flows = _Flows();
    final state = credentials();
    addTearDown(state.dispose);
    await pump(tester, EmailAuthBody(signUp: false, credentials: state, flows: flows, onForgotPassword: () {}));
    expect(fields.map((f) => f.kind), [AuthFieldKind.email, AuthFieldKind.password]);
    expect(fields.first.action, TextInputAction.next);
    await tester.tap(find.byKey(EmailAuthBody.submitKey));
    expect(flows.calls, isEmpty, reason: 'no valid e-mail yet');
    state.setUserName('a@b.c');
    state.setPassword('x');
    await tester.pump();
    fields.last.onSubmitted!('x');
    await tester.pump();
    expect(flows.calls, ['signIn a@b.c']);
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('sign-up: the new password kind, an error stays inline, providers run through the same gate', (tester) async {
    final flows = _Flows()..answer = AuthError.emailAlreadyInUse;
    final state = credentials();
    addTearDown(state.dispose);
    await pump(tester, EmailAuthBody(signUp: true, credentials: state, flows: flows));
    expect(fields.last.kind, AuthFieldKind.newPassword);
    state.setUserName('a@b.c');
    state.setPassword('longenough');
    await tester.pump();
    await tester.tap(find.byKey(EmailAuthBody.submitKey));
    await tester.pump();
    expect(find.text('error emailAlreadyInUse'), findsOneWidget);
    expect(find.text('Forgot password?'), findsNothing);
    await tester.tap(find.text('google'));
    await tester.pump();
    expect(flows.calls.last, 'google');
  });

  testWidgets('reset: send with a valid e-mail, then onSent; back', (tester) async {
    final flows = _Flows();
    final state = credentials();
    addTearDown(state.dispose);
    var sent = 0;
    var back = 0;
    await pump(
      tester,
      ResetPasswordBody(credentials: state, flows: flows, onBack: () => back++, onSent: () => sent++, onFailed: () {}),
    );
    state.setUserName('a@b.c');
    await tester.pump();
    await tester.tap(find.byKey(ResetPasswordBody.sendKey));
    await tester.pump();
    expect(flows.calls, ['reset a@b.c']);
    expect(sent, 1);
    await tester.tap(find.text('Back to sign in'));
    expect(back, 1);
  });

  testWidgets('the configured icons stand on the main buttons; left out, none', (tester) async {
    const mark = IconData(0xe000);
    final actions = <StatusAction>[];
    AuthScreens.configure(
      layout: (context, view) => const SizedBox(),
      button: (context, action) {
        actions.add(action);
        return Text(action.label);
      },
    );
    final state = credentials();
    addTearDown(state.dispose);
    await pump(tester, EmailAuthBody(signUp: false, credentials: state, flows: _Flows()));
    expect(actions.first.icon, isNull);
    expect(AuthForms.savePassword, isTrue);

    AuthForms.configure(
      page: AuthForms.page,
      field: AuthForms.field,
      providerButton: AuthForms.providerButton,
      error: AuthForms.error,
      text: AuthForms.text,
      describe: AuthForms.describe,
      icons: const AuthFormsIcons(signUp: mark),
      savePassword: false,
    );
    actions.clear();
    await pump(tester, EmailAuthBody(signUp: true, credentials: state, flows: _Flows()));
    expect(actions.first.icon, mark);
    expect(AuthForms.savePassword, isFalse);
  });

  testWidgets('the keyboard sent too early: the form says what is missing, a keystroke takes it away', (tester) async {
    final flows = _Flows();
    final state = credentials();
    addTearDown(state.dispose);
    await pump(tester, EmailAuthBody(signUp: false, credentials: state, flows: flows));
    fields.last.onSubmitted!('');
    await tester.pump();
    expect(find.text('error Enter a valid e-mail address.'), findsOneWidget);
    expect(flows.calls, isEmpty);

    fields.first.onChanged('a@b.c');
    await tester.pump();
    expect(find.textContaining('error'), findsNothing);
    fields.last.onSubmitted!('');
    await tester.pump();
    expect(find.text('error Enter your password.'), findsOneWidget);
  });

  testWidgets('with the keyboard up the main button is scrolled into view', (tester) async {
    await tester.binding.setSurfaceSize(const Size(300, 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.view.reset);
    AuthForms.configure(
      page: (context, children) => ListView(children: children),
      field: (context, field) => SizedBox(height: 200, child: Text('field ${field.kind.name}')),
      providerButton: AuthForms.providerButton,
      error: AuthForms.error,
      text: AuthForms.text,
      describe: AuthForms.describe,
    );
    final state = credentials();
    addTearDown(state.dispose);
    await pump(tester, EmailAuthBody(signUp: false, credentials: state, flows: _Flows(), providers: const []));
    expect(find.byKey(EmailAuthBody.submitKey).hitTestable(), findsNothing, reason: 'below the fold');

    tester.view.viewInsets = const FakeViewPadding(bottom: 100);
    await tester.pumpAndSettle();
    expect(find.byKey(EmailAuthBody.submitKey).hitTestable(), findsOneWidget);
  });

  testWidgets('typing rebuilds neither the page nor a field: only the button follows', (tester) async {
    var pages = 0;
    final labels = <String>[];
    AuthForms.configure(
      page: (context, children) {
        pages++;
        return Column(children: children);
      },
      field: (context, field) {
        fields.add(field);
        return Text('field ${field.kind.name}');
      },
      providerButton: AuthForms.providerButton,
      error: AuthForms.error,
      text: AuthForms.text,
      describe: AuthForms.describe,
    );
    AuthScreens.configure(
      layout: (context, view) => const SizedBox(),
      button: (context, action) {
        labels.add('${action.label} ${action.onPressed != null}');
        return Text(action.label);
      },
    );
    final state = credentials();
    addTearDown(state.dispose);
    await pump(tester, EmailAuthBody(signUp: false, credentials: state, flows: _Flows(), providers: const []));
    expect((pages, fields.length), (1, 2));
    expect(labels, ['Sign in false']);

    fields.first.onChanged('a@b.c');
    fields.last.onChanged('secret');
    await tester.pump();
    expect((pages, fields.length), (1, 2));
    expect(labels.last, 'Sign in true');
  });
}
