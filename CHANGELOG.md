# Changelog

All notable changes to this package. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the package uses [semantic versioning](https://semver.org/) (pre-1.0: a minor bump may break the API). Each version is a git tag (`vX.Y.Z`) with a GitHub release.

## [0.1.0] - 2026-11-26
### Added
- `StatusScreen`: one structure for every screen that parks the app (title, body, an optional block, actions), with the busy timing (the line after 1.5 s, "takes longer" + Try again after 10 s).
- `StatusAction` / `StatusEmphasis` and `StatusView`: the actions as data and what the screen shows, drawn by the app's `AuthScreens.layout` and `AuthScreens.button`.
- `AuthScreensStrings` and `AuthScreens.configure`: the app's words and look.
- The states: `BootingStatus`, `SigningInStatus`, `AuthFailedStatus`, `ExpiredStatus`, `MaintenanceStatus`, `OutdatedStatus`, `EmailNotVerifiedStatus`.

[0.1.0]: https://github.com/arnoutvandervorst/auth_screens/releases/tag/v0.1.0
