import 'package:auth_engine/auth_engine.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The kinds of field the auth forms ask for. [newPassword] is a password
/// being set (sign-up): the app may show its strength.
enum AuthFieldKind { email, password, newPassword, phone, code }

/// The sign-in providers next to the e-mail form.
enum AuthProvider { google, apple }

/// One field, as data: the app draws it in its own look.
class AuthFieldSpec {
  final AuthFieldKind kind;
  final String hint;
  final String? helper;

  /// What the field holds when it first shows (the number after "Use
  /// another number"); null for an empty field.
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final TextInputAction action;
  final ValueChanged<String>? onSubmitted;
  final TextEditingController? controller;
  final bool autofocus;
  final bool enabled;
  final Key? key;

  const AuthFieldSpec({
    required this.kind,
    required this.hint,
    required this.onChanged,
    this.helper,
    this.initialValue,
    this.action = TextInputAction.done,
    this.onSubmitted,
    this.controller,
    this.autofocus = false,
    this.enabled = true,
    this.key,
  });
}

typedef AuthPageBuilder = Widget Function(BuildContext context, List<Widget> children);
typedef AuthFieldBuilder = Widget Function(BuildContext context, AuthFieldSpec field);
typedef AuthProviderButtonBuilder =
    Widget Function(BuildContext context, AuthProvider provider, bool busy, VoidCallback? onPressed);
typedef AuthErrorBuilder = Widget Function(BuildContext context, String message);
typedef AuthTextBuilder = Widget Function(BuildContext context, String text);

/// The words of the auth forms; the app fills them from its translations.
class AuthFormsStrings {
  final String email;
  final String password;
  final String signIn;
  final String signUp;
  final String forgotPassword;
  final String resetIntro;
  final String reset;
  final String backToSignIn;
  final String phoneIntro;
  final String phoneLabel;
  final String phoneHelper;
  final String sendCode;
  final String codeLabel;
  final String Function(String phoneNumber) codeHelper;
  final String verifyCode;
  final String changePhoneNumber;

  /// What the form says when the keyboard submits it too early.
  final String emailInvalid;
  final String passwordMissing;
  final String passwordWeak;

  const AuthFormsStrings({
    this.email = 'E-mail',
    this.password = 'Password',
    this.signIn = 'Sign in',
    this.signUp = 'Create account',
    this.forgotPassword = 'Forgot password?',
    this.resetIntro = 'Enter your e-mail and we send you a link to set a new password.',
    this.reset = 'Send the link',
    this.backToSignIn = 'Back to sign in',
    this.phoneIntro = 'Sign in with your phone number; we text you a code.',
    this.phoneLabel = 'Phone number',
    this.phoneHelper = 'With the country code, for example +31 6 12345678',
    this.sendCode = 'Send the code',
    this.codeLabel = 'Code',
    this.codeHelper = _codeHelper,
    this.verifyCode = 'Sign in',
    this.changePhoneNumber = 'Use another number',
    this.emailInvalid = 'Enter a valid e-mail address.',
    this.passwordMissing = 'Enter your password.',
    this.passwordWeak = 'Choose a stronger password.',
  });
}

/// The icons on the forms' main buttons, in the app's icon set; null for a
/// button without one.
class AuthFormsIcons {
  final IconData? signIn;
  final IconData? signUp;
  final IconData? reset;
  final IconData? sendCode;
  final IconData? verifyCode;

  const AuthFormsIcons({this.signIn, this.signUp, this.reset, this.sendCode, this.verifyCode});
}

String _codeHelper(String phoneNumber) => 'The code we texted to $phoneNumber';

/// The app's look and words for the auth forms. Set once at start-up (and
/// in the test config), next to `AuthScreens.configure`.
abstract final class AuthForms {
  static AuthPageBuilder page = (context, children) => ListView(children: children);
  static AuthFieldBuilder field = _defaultField;
  static AuthProviderButtonBuilder providerButton = _defaultProvider;
  static AuthErrorBuilder error = (context, message) => Text(message);
  static AuthTextBuilder text = (context, text) => Text(text);
  static String Function(AuthError error) describe = (error) => error.name;
  static AuthFormsStrings Function() strings = () => const AuthFormsStrings();
  static AuthFormsIcons icons = const AuthFormsIcons();

  /// Whether a sign-in or sign-up that worked offers to save the password
  /// (the platform's sheet). Off in an automated run, where nobody answers it.
  static bool savePassword = true;

  /// A form's page ([page]) that puts the keyboard away when the person
  /// drags it: what lies under the keyboard is then in reach.
  static Widget pageOf(BuildContext context, List<Widget> children) => NotificationListener<ScrollStartNotification>(
    onNotification: (notification) {
      if (notification.dragDetails != null) FocusManager.instance.primaryFocus?.unfocus();
      return false;
    },
    child: page(context, children),
  );

  static void configure({
    required AuthPageBuilder page,
    required AuthFieldBuilder field,
    required AuthProviderButtonBuilder providerButton,
    required AuthErrorBuilder error,
    required AuthTextBuilder text,
    required String Function(AuthError error) describe,
    AuthFormsStrings Function()? strings,
    AuthFormsIcons icons = const AuthFormsIcons(),
    bool savePassword = true,
  }) {
    AuthForms.page = page;
    AuthForms.field = field;
    AuthForms.providerButton = providerButton;
    AuthForms.error = error;
    AuthForms.text = text;
    AuthForms.describe = describe;
    if (strings != null) AuthForms.strings = strings;
    AuthForms.icons = icons;
    AuthForms.savePassword = savePassword;
  }
}

//* shortcut: the fallback makes a controller and focus node per build; it only
//* serves an unconfigured test, every app configures its own field.
Widget _defaultField(BuildContext context, AuthFieldSpec field) => EditableText(
  key: field.key,
  controller: field.controller ?? TextEditingController(),
  focusNode: FocusNode(),
  style: const TextStyle(),
  cursorColor: const Color(0xFF000000),
  backgroundCursorColor: const Color(0xFF000000),
  onChanged: field.onChanged,
  onSubmitted: field.onSubmitted,
  textInputAction: field.action,
);

Widget _defaultProvider(BuildContext context, AuthProvider provider, bool busy, VoidCallback? onPressed) =>
    GestureDetector(onTap: onPressed, child: Text(provider.name));
