/// The sign-in, sign-up, password-reset and phone forms on auth_engine's
/// states, in one structure with each app's own look ([AuthForms.configure]).
/// A separate library so the status screens (auth_screens.dart) never import
/// the auth engine.
library;

export 'src/auth_forms_config.dart';
export 'src/email_auth_body.dart';
export 'src/main_action_in_view.dart';
export 'src/phone_sign_in_body.dart';
export 'src/reset_password_body.dart';
