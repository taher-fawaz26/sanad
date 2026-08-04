/// DI registration for the `otp` package.
///
/// There is nothing to register: `OtpBloc` is constructed per-call with the
/// caller's `OtpFlowConfig` (via `OtpFlow.start`), not resolved from the
/// locator. This class exists to match the one-`XDI`-per-package convention
/// and give future package-level dependencies (analytics hooks, etc.) a home.
abstract final class OtpDI {
  OtpDI._();

  static void init() {}
}
