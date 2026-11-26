import 'package:auth_screens/auth_screens.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  Directionality(textDirection: TextDirection.ltr, child: MediaQuery(data: const MediaQueryData(), child: child)),
);

void main() {
  final views = <StatusView>[];
  setUp(() {
    views.clear();
    AuthScreens.configure(
      layout: (context, view) {
        views.add(view);
        return Column(children: [if (view.showMessage && view.title != null) Text(view.title!), ...view.buttons]);
      },
      button: (context, action) => GestureDetector(onTap: action.onPressed, child: Text(action.label)),
      strings: () => const AuthScreensStrings(),
    );
  });

  testWidgets('busy: no line at first, the line after 1.5 s, slow with try again after 10 s', (tester) async {
    var retries = 0;
    await pump(tester, BootingStatus(onRetry: () => retries++));
    expect(views.last.busy, isTrue);
    expect(views.last.showMessage, isFalse);
    await tester.pump(const Duration(milliseconds: 1600));
    expect(find.text('Getting ready'), findsOneWidget);
    await tester.pump(const Duration(seconds: 9));
    expect(views.last.slow, isTrue);
    expect(find.text('This takes longer than usual'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retries, 1);
  });

  testWidgets('still: title and actions at once, in their order', (tester) async {
    var signedOut = 0;
    await pump(tester, ExpiredStatus(onSignInOther: () => signedOut++));
    expect(views.last.showMessage, isTrue);
    expect(find.text('Your session has ended'), findsOneWidget);
    await tester.tap(find.text('Sign in with another account'));
    expect(signedOut, 1);
  });

  testWidgets('outdated: a store button only with a link', (tester) async {
    Uri? opened;
    await pump(tester, OutdatedStatus(storeUrl: null, onOpen: (uri) => opened = uri));
    expect(views.last.buttons, isEmpty);
    await pump(tester, OutdatedStatus(storeUrl: Uri.parse('https://store/app'), onOpen: (uri) => opened = uri));
    await tester.tap(find.text('Update'));
    expect(opened, Uri.parse('https://store/app'));
  });

  testWidgets('e-mail: resend, check with the result line, sign out', (tester) async {
    var sent = 0;
    await pump(
      tester,
      EmailNotVerifiedStatus(
        email: 'a@b.c',
        onResend: () async => true,
        onSent: () => sent++,
        onCheck: () async => const Text('Not yet confirmed'),
        onSignOut: () {},
      ),
    );
    expect(views.last.buttons.length, 3);
    await tester.tap(find.text('Send the e-mail again'));
    await tester.pump();
    expect(sent, 1);
    await tester.tap(find.text('I have confirmed it'));
    await tester.pump();
    expect(views.last.extra, isA<Text>());
  });
}
