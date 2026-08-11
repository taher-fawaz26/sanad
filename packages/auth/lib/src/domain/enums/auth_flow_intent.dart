/// The user's explicitly chosen intent on the email/OTP entry screen.
///
/// The backend split login and signup into separate endpoint pairs
/// (`auth/login` + `auth/login/verify` vs `auth/signup` +
/// `auth/signup/verify`), so the app can no longer infer intent from a
/// single shared "request OTP" call — the caller must say up front which
/// pair to hit, and 404 (unknown email at login) / 409 (email already
/// registered at signup) are surfaced as real errors rather than silently
/// auto-branching between the two flows.
enum AuthFlowIntent { signIn, createAccount }
