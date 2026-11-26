import 'package:auth_screens/src/auth_screens_config.dart';
import 'package:auth_screens/src/status_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

//* One widget per state the app can be parked in. Each fixes the words and
//* the actions in their order, so every app tells the person the same thing;
//* the look comes from AuthScreens.layout / AuthScreens.button.

/// The cold start, until the session settles.
class BootingStatus extends StatelessWidget {
  /// The app's picture of this state, above the title.
  final Widget? visual;
  final VoidCallback? onRetry;

  const BootingStatus({super.key, this.visual, this.onRetry});

  @override
  Widget build(BuildContext context) => StatusScreen(busy: true, visual: visual, title: AuthScreens.strings().booting, onRetry: onRetry);
}

/// After signing in or up, while the account's session settles.
class SigningInStatus extends StatelessWidget {
  /// The app's picture of this state, above the title.
  final Widget? visual;
  final VoidCallback? onRetry;

  const SigningInStatus({super.key, this.visual, this.onRetry});

  @override
  Widget build(BuildContext context) => StatusScreen(busy: true, visual: visual, title: AuthScreens.strings().signingIn, onRetry: onRetry);
}

/// A session that failed to start: [reason], and Try again.
class AuthFailedStatus extends StatelessWidget {
  /// The app's picture of this state, above the title.
  final Widget? visual;
  final String reason;
  final VoidCallback onRetry;

  const AuthFailedStatus({super.key, this.visual, required this.reason, required this.onRetry});

  @override
  Widget build(BuildContext context) =>
      StatusScreen(visual: visual, title: reason, actions: [StatusAction(label: AuthScreens.strings().retry, onPressed: onRetry)]);
}

/// An account session that expired: sign in again.
class ExpiredStatus extends StatelessWidget {
  /// The app's picture of this state, above the title.
  final Widget? visual;
  final VoidCallback onSignInOther;

  const ExpiredStatus({super.key, this.visual, required this.onSignInOther});

  @override
  Widget build(BuildContext context) {
    final l = AuthScreens.strings();
    return StatusScreen(visual: visual, title: l.expiredTitle, actions: [StatusAction(label: l.signInOther, onPressed: onSignInOther)]);
  }
}

/// The maintenance window: what is going on, no way past it.
class MaintenanceStatus extends StatelessWidget {
  /// The app's picture of this state, above the title.
  final Widget? visual;

  const MaintenanceStatus({super.key, this.visual});

  @override
  Widget build(BuildContext context) {
    final l = AuthScreens.strings();
    return StatusScreen(visual: visual, title: l.maintenanceTitle, body: l.maintenanceBody);
  }
}

/// A build below the minimum: no way past it. With a [storeUrl] the button
/// opens the store ([onOpen]); without one the text alone.
class OutdatedStatus extends StatelessWidget {
  /// The app's picture of this state, above the title.
  final Widget? visual;
  final Uri? storeUrl;
  final ValueChanged<Uri> onOpen;

  /// The store button's icon, in the app's icon set.
  final IconData? actionIcon;

  const OutdatedStatus({super.key, this.visual, required this.storeUrl, required this.onOpen, this.actionIcon});

  static const actionKey = ValueKey('outdated-store');

  @override
  Widget build(BuildContext context) {
    final l = AuthScreens.strings();
    final link = storeUrl;
    return StatusScreen(
      visual: visual,
      title: l.outdatedTitle,
      body: link == null ? l.outdatedBodyNoLink : l.outdatedBody,
      actions: [
        if (link != null) StatusAction(key: actionKey, label: l.outdatedAction, icon: actionIcon, onPressed: () => onOpen(link)),
      ],
    );
  }
}

/// An e-mail account that is not confirmed yet: send the e-mail again, say
/// it is confirmed (the app checks; [onCheck] returns the result line to
/// show, or null), or sign in with another account.
class EmailNotVerifiedStatus extends HookWidget {
  /// The app's picture of this state, above the title.
  final Widget? visual;
  final String email;
  final Future<bool> Function() onResend;

  /// After a resend that worked (the app may confirm it in a dialog).
  final VoidCallback? onSent;

  /// After a resend that failed: the line to show.
  final Widget? resendFailed;
  final Future<Widget?> Function() onCheck;
  final VoidCallback onSignOut;

  const EmailNotVerifiedStatus({
    super.key,
    this.visual,
    required this.email,
    required this.onResend,
    required this.onCheck,
    required this.onSignOut,
    this.onSent,
    this.resendFailed,
  });

  @override
  Widget build(BuildContext context) {
    final l = AuthScreens.strings();
    final sending = useState(false);
    final checking = useState(false);
    final result = useState<Widget?>(null);
    return StatusScreen(
      visual: visual,
      title: l.emailTitle,
      body: l.emailBody(email),
      extra: result.value,
      actions: [
        StatusAction(
          label: l.resendEmail,
          busy: sending.value,
          onPressed: () async {
            sending.value = true;
            final sent = await onResend();
            if (!context.mounted) return;
            sending.value = false;
            result.value = sent ? null : resendFailed;
            if (sent) onSent?.call();
          },
        ),
        StatusAction(
          label: checking.value ? l.checkingEmail : l.checkEmail,
          emphasis: StatusEmphasis.secondary,
          busy: checking.value,
          onPressed: () async {
            checking.value = true;
            result.value = null;
            final line = await onCheck();
            if (!context.mounted) return;
            result.value = line;
            checking.value = false;
          },
        ),
        StatusAction(label: l.signInOther, emphasis: StatusEmphasis.quiet, onPressed: onSignOut),
      ],
    );
  }
}
