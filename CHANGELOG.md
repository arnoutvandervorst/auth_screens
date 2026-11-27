# Changelog

All notable changes to this package. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the package uses [semantic versioning](https://semver.org/) (pre-1.0: a minor bump may break the API). Each version is a git tag (`vX.Y.Z`) with a GitHub release.

## [0.7.0] - 2026-11-27
### Changed
- Depends on auth_engine 0.4.0 (a failed step after sign-in never deletes a returning account; phone verification ends on every path). An app must be on auth_engine 0.4.0 to use this version without a git-ref conflict.
### Fixed
- `EmailNotVerifiedStatus`: a resend or a check that throws no longer leaves its button busy. A resend that throws shows `resendFailed`; a check that throws still reaches the caller.
- The e-mail fields of `EmailAuthBody` and `ResetPasswordBody` show the address the credentials state already holds.

## [0.6.0] - 2026-11-26
### Added
- `PhoneSignInBody` says an empty number or an empty code in its own words (`AuthFormsStrings.phoneMissing`, `codeMissing`) and does not ask the state: it used to show the wording of an invalid credential. The next keystroke takes the line away.
- `AuthFormsStrings.sendCodeFailed`: one line for a code that could not be sent, in place of the error's own wording. Null (the default) keeps that wording.
### Changed
- `PhoneSignInBody` is a `HookWidget`.
### Fixed
- The fallback field of an unconfigured `AuthForms` made a controller and a focus node on every build. It is a `Text` now.

## [0.5.2] - 2026-11-26
### Changed
- Depends on auth_engine 0.3.4: `PhoneLoginState` no longer writes to disposed signals when the phone form closes while a code is being sent or checked. An app on auth_engine 0.3.4 can use this version without a git-ref conflict.

## [0.5.1] - 2026-11-26
### Fixed
- A keystroke rebuilt the whole form page. The page and its fields are now built once; only the parts that show state rebuild: the error line with the main button, the provider buttons, and on the phone form the field and buttons that wait on the code. The phone form's page follows the step (number or code) and nothing else.

## [0.5.0] - 2026-11-26
### Added
- The forms never leave the person stuck behind the keyboard. `MainActionInView` keeps a form's main button above the keyboard: the page scrolls just far enough when the keyboard comes up, when the form grows (a strength meter, an error line) and while typing.
- The keyboard's Go on a form that cannot be sent yet says what is missing in the error line (`AuthFormsStrings.emailInvalid`, `passwordMissing`, `passwordWeak`) instead of doing nothing; the next keystroke takes the line away.
- `AuthForms.pageOf`: the forms' page puts the keyboard away when the person drags it, so what lies under the keyboard is in reach.
### Changed
- Sending a form (its button or the keyboard) puts the keyboard away, so the busy button and an error line are in view.
- `EmailAuthBody` is a `HookWidget`.

## [0.4.0] - 2026-11-26
### Added
- `AuthFormsIcons` (`AuthForms.configure(icons:)`): an icon on the forms' main buttons (sign in, sign up, send the reset link, send the code, verify the code), in the app's icon set. None by default.
- `AuthForms.configure(savePassword:)`: whether a sign-in or sign-up that worked offers to save the password. On by default; an automated run turns it off, where nobody answers the platform's sheet.
- `AuthFieldSpec.initialValue`: what a field holds when it first shows. The phone field gets the number already typed, so "Use another number" shows the number that is still in the state.
### Changed
- `AuthForms.configure` sets the icons and `savePassword` on every call: left out, they go back to their defaults.

## [0.3.0] - 2026-11-26
### Added
- `visual` on `StatusScreen`, on every state widget and on `StatusView`: the app's picture of that state (an icon in a medallion, a photo), handed to the layout as it is. For a look where each state has its own picture; a layout with one mark of its own ignores it.

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

[0.6.0]: https://github.com/arnoutvandervorst/auth_screens/releases/tag/v0.6.0
[0.5.2]: https://github.com/arnoutvandervorst/auth_screens/releases/tag/v0.5.2
[0.5.1]: https://github.com/arnoutvandervorst/auth_screens/releases/tag/v0.5.1
[0.5.0]: https://github.com/arnoutvandervorst/auth_screens/releases/tag/v0.5.0
[0.4.0]: https://github.com/arnoutvandervorst/auth_screens/releases/tag/v0.4.0
[0.3.0]: https://github.com/arnoutvandervorst/auth_screens/releases/tag/v0.3.0
[0.2.0]: https://github.com/arnoutvandervorst/auth_screens/releases/tag/v0.2.0
[0.1.0]: https://github.com/arnoutvandervorst/auth_screens/releases/tag/v0.1.0
