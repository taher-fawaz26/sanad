import 'package:flutter/widgets.dart';

/// Which product's OTP *visual specification* to render.
///
/// The two Sanad apps ship genuinely different OTP designs — different
/// hierarchy (the client leads with an icon, the provider with a centered
/// title), different type scale, cell size, button placement and resend
/// treatment. They share one state machine (`OtpBloc`), one verifier
/// contract, one input control and one set of parts; only the arrangement
/// and the tokens differ.
///
/// This enum is what keeps them from bleeding into each other: a change to
/// the client layout touches `ClientOtpLayout` only, and a change to the
/// provider layout touches `ProviderOtpLayout` only.
///
/// Orthogonal to `OtpPresentation`, which says whether the screen is hosted
/// as a page or a bottom sheet. Both styles support both hosts.
enum OtpVisualStyle {
  /// Figma `6979:27634` / `6979:27585` / `7063:25563` — the sanad_client OTP
  /// screen: leading icon circle, start-aligned 28dp title, compact cells,
  /// mutually-exclusive countdown/resend caption, action pinned to the
  /// bottom bar.
  client,

  /// Figma `2142:14121` (page) / `3809:18083` & `3809:18133` (sheet) — the
  /// sanad_provider OTP screen: no icon, centered 32dp title, large cells,
  /// action inline above a teal countdown and a centered resend row.
  provider,
}

/// App-level default for [OtpVisualStyle].
///
/// Several OTP call sites live in packages **both** apps depend on
/// (`auth`'s sign-in OTP, `account_settings`' deletion OTP,
/// `contact_verification`'s change-contact OTP). Those packages cannot know
/// which product they were compiled into, and threading a style parameter
/// through each of their public APIs would put a pixel concern in three
/// unrelated feature contracts.
///
/// Instead each app installs this scope once, above its router:
///
/// ```dart
/// OtpStyleScope(
///   style: OtpVisualStyle.client,
///   child: MaterialApp.router(...),
/// )
/// ```
///
/// A single flow can still opt out by setting `OtpFlowConfig.style`, which
/// takes precedence. With neither, [OtpVisualStyle.provider] applies — it is
/// the spec the shared `otp.*` copy in `localization` was written against.
class OtpStyleScope extends InheritedWidget {
  const OtpStyleScope({
    required this.style,
    required super.child,
    super.key,
  });

  final OtpVisualStyle style;

  /// The app-level style, or `null` when no scope is installed above
  /// [context].
  static OtpVisualStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OtpStyleScope>()?.style;

  @override
  bool updateShouldNotify(OtpStyleScope oldWidget) => oldWidget.style != style;
}
