import 'package:flutter/widgets.dart';

/// How much a status action stands out: the one main action, a second one,
/// or a quiet way out (sign in with another account).
enum StatusEmphasis { primary, secondary, quiet }

/// A button on a status screen, as data: the app draws it in its own look.
class StatusAction {
  final String label;
  final VoidCallback? onPressed;
  final StatusEmphasis emphasis;
  final IconData? icon;
  final bool busy;
  final Key? key;

  const StatusAction({
    required this.label,
    required this.onPressed,
    this.emphasis = StatusEmphasis.primary,
    this.icon,
    this.busy = false,
    this.key,
  });
}

/// What a status screen shows at this moment, for the app's layout.
class StatusView {
  /// The app is still working (booting, signing in): the mark moves.
  final bool busy;

  /// Whether the title and body are shown yet (a busy screen waits 1.5 s,
  /// so most starts never show a line).
  final bool showMessage;

  /// A busy screen that took longer than usual: the title and body say so
  /// and a Try again button is among [buttons].
  final bool slow;
  final String? title;
  final String? body;

  /// The picture of this state above the title (an icon in a medallion, a
  /// photo), in the app's look; null when the layout has one mark of its own.
  final Widget? visual;

  /// A block under the body (a reason, a result line).
  final Widget? extra;

  /// The buttons, primary first, already drawn by [AuthScreens.button].
  final List<Widget> buttons;

  const StatusView({
    required this.busy,
    required this.showMessage,
    required this.slow,
    this.title,
    this.body,
    this.visual,
    this.extra,
    this.buttons = const [],
  });
}

typedef StatusLayoutBuilder = Widget Function(BuildContext context, StatusView view);
typedef StatusButtonBuilder = Widget Function(BuildContext context, StatusAction action);

/// The words of the status screens. The app fills them from its own
/// translations ([AuthScreens.strings]); the defaults are English.
class AuthScreensStrings {
  final String booting;
  final String signingIn;
  final String slowTitle;
  final String slowBody;
  final String retry;
  final String maintenanceTitle;
  final String maintenanceBody;
  final String outdatedTitle;
  final String outdatedBody;
  final String outdatedBodyNoLink;
  final String outdatedAction;
  final String expiredTitle;
  final String signInOther;
  final String emailTitle;
  final String Function(String email) emailBody;
  final String resendEmail;
  final String checkEmail;
  final String checkingEmail;

  const AuthScreensStrings({
    this.booting = 'Getting ready',
    this.signingIn = 'Signing you in',
    this.slowTitle = 'This takes longer than usual',
    this.slowBody = 'Check your connection, or try again.',
    this.retry = 'Try again',
    this.maintenanceTitle = 'Down for maintenance',
    this.maintenanceBody = 'We are working on the app. Try again in a little while.',
    this.outdatedTitle = 'Update the app',
    this.outdatedBody = 'This version no longer works. Get the new one from the store.',
    this.outdatedBodyNoLink = 'This version no longer works. Get the new one from the store.',
    this.outdatedAction = 'Update',
    this.expiredTitle = 'Your session has ended',
    this.signInOther = 'Sign in with another account',
    this.emailTitle = 'Confirm your e-mail',
    this.emailBody = _emailBody,
    this.resendEmail = 'Send the e-mail again',
    this.checkEmail = 'I have confirmed it',
    this.checkingEmail = 'Checking…',
  });
}

String _emailBody(String email) => 'We sent a link to $email. Open it, then come back here.';

/// The app's look and words for the status screens. Set once at start-up
/// (and in the test config), before the first status screen shows.
abstract final class AuthScreens {
  static StatusLayoutBuilder layout = _defaultLayout;
  static StatusButtonBuilder button = _defaultButton;
  static AuthScreensStrings Function() strings = () => const AuthScreensStrings();

  static void configure({
    required StatusLayoutBuilder layout,
    required StatusButtonBuilder button,
    AuthScreensStrings Function()? strings,
  }) {
    AuthScreens.layout = layout;
    AuthScreens.button = button;
    if (strings != null) AuthScreens.strings = strings;
  }
}

//* Plain fallbacks so a screen renders before configure (and in this kit's tests).
Widget _defaultLayout(BuildContext context, StatusView view) => Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ?view.visual,
      if (view.showMessage && view.title != null) Text(view.title!),
      if (view.showMessage && view.body != null) Text(view.body!),
      ?view.extra,
      ...view.buttons,
    ],
  ),
);

Widget _defaultButton(BuildContext context, StatusAction action) => GestureDetector(
  key: action.key,
  onTap: action.busy ? null : action.onPressed,
  child: Text(action.label),
);
