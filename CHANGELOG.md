# Changelog

All notable changes to this package. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the package uses [semantic versioning](https://semver.org/) (pre-1.0: a minor bump may break the API). Each version is a git tag (`vX.Y.Z`) with a GitHub release.

## [0.2.0] - 2026-11-26
### Added
- The auth forms as a separate library, `package:auth_screens/auth_forms.dart`, on auth_engine's states: `EmailAuthBody` (sign in or up: e-mail, password with the keyboard moving on and submitting, the inline error, the main button, Google and Apple, "Forgot password?", header, intro and footer slots), `ResetPasswordBody` and `PhoneSignInBody` (number, code, another number, on `PhoneLoginState`). Every trigger runs through `CredentialsStateCore.run`, so only one is in flight and an error stays on the page.
- `AuthForms.configure` (page, field, provider button, error, text, error wording, strings), `AuthFieldSpec` / `AuthFieldKind`, `AuthProvider` and `AuthFormsStrings`: the app's look and words for the forms. Buttons use `AuthScreens.button`.
### Changed
- Depends on auth_engine (v0.3.3) and signals_flutter for the forms. The status screens (`auth_screens.dart`) still import neither.

## [0.1.0] - 2026-11-26
### Added
- `StatusScreen`: one structure for every screen that parks the app (title, body, an optional block, actions), with the busy timing (the line after 1.5 s, "takes longer" + Try again after 10 s).
- `StatusAction` / `StatusEmphasis` and `StatusView`: the actions as data and what the screen shows, drawn by the app's `AuthScreens.layout` and `AuthScreens.button`.
- `AuthScreensStrings` and `AuthScreens.configure`: the app's words and look.
- The states: `BootingStatus`, `SigningInStatus`, `AuthFailedStatus`, `ExpiredStatus`, `MaintenanceStatus`, `OutdatedStatus`, `EmailNotVerifiedStatus`.

[0.2.0]: https://github.com/arnoutvandervorst/auth_screens/releases/tag/v0.2.0
[0.1.0]: https://github.com/arnoutvandervorst/auth_screens/releases/tag/v0.1.0
