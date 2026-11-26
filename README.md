# auth_screens

The screens around signing in for Flutter apps, kept in one place so every app parks the person the same way: the same states, the same words in the same order, the same timing. Each app keeps its own look.

- **One structure** (`StatusScreen`): a title, a body, an optional block and the actions. Busy (booting, signing in): the line shows after 1.5 s, so most starts never show one, and after 10 s "this takes longer than usual" with Try again. Still: everything at once.
- **Every state as a widget** (`status_screens.dart`): `BootingStatus`, `SigningInStatus`, `AuthFailedStatus`, `ExpiredStatus`, `MaintenanceStatus`, `OutdatedStatus` (a store button only with a link), `EmailNotVerifiedStatus` (resend, "I have confirmed it", sign in with another account). The app passes the callbacks (its auth flows); the widgets fix the words and the order of the actions.
- **The app's look** (`AuthScreens.configure`): a `layout` that draws a `StatusView` (busy, showMessage, slow, title, body, extra, buttons) and a `button` that draws a `StatusAction` (label, emphasis primary / secondary / quiet, icon, busy). One app shows its splash colour and a moving mark, another a header and a medallion; the structure stays the same.
- **The app's words** (`AuthScreensStrings`): set `strings` to a function that reads your translations. Defaults are English.

No Firebase and no native code: only Flutter and `flutter_hooks`, so a boot shell can use it before Firebase starts.

## Use

```yaml
dependencies:
  auth_screens:
    git:
      url: https://github.com/arnoutvandervorst/auth_screens.git
      ref: v0.1.0
```

```dart
void main() {
  AuthScreens.configure(
    layout: (context, view) => MyStatusLayout(view: view),
    button: (context, action) => MyButton(action: action),
    strings: () => AuthScreensStrings(booting: t.launch.preparing /* … */),
  );
  runApp(const App());
}

// In the auth gate:
AuthFailedStatus(reason: error.title, onRetry: flows.retry);
```

Call `configure` in `test/flutter_test_config.dart` too.

## Changes

See [CHANGELOG.md](CHANGELOG.md). Versions are git tags (`vX.Y.Z`) with a GitHub release.
