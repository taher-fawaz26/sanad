/// SVG asset paths shipped under `packages/app_assets/assets/svgs/`.
///
/// Load with `AppSvgPicture.asset(AppSvgs.x)` from `design_system`, or
/// `SvgPicture.asset(AppSvgs.x, package: AppAssets.package)`.
abstract final class AppSvgs {
  AppSvgs._();

  static const String _base = 'assets/svgs';

  /// Image / photo placeholder — missing URL or load error (`#26A68C` tile).
  static const String imagePlaceholder = '$_base/image_placeholder.svg';

  // ── Featured icons ─────────────────────────────────────────────────────────

  /// Lightning bolt — featured icon primary / gray default.
  static const String zap = '$_base/zap.svg';

  /// Alert circle — featured icon error default.
  static const String alertCircle = '$_base/alert_circle.svg';

  /// Browser window with refresh — inline alert review / rejected states
  /// (`3821:19180`, `3821:19202`).
  static const String reloadWindow = '$_base/reload_window.svg';

  /// Alert triangle — featured icon warning default.
  static const String alertTriangle = '$_base/alert_triangle.svg';

  /// Check circle — featured icon success default.
  static const String checkCircle = '$_base/check_circle.svg';

  /// Globe + pointer — network error featured icon (`1528:10165`).
  static const String internet = '$_base/internet.svg';

  /// Solid dark-green circle + light-green checkmark — add-branch success
  /// popover illustration (`194:5419` / `365:15054`). Baked-in Figma colors
  /// (`#085D3A` / `#75E0A7`) — not part of the `main` palette scale, so
  /// shipped as a standalone asset rather than reconstructed from tokens.
  static const String successCheck = '$_base/success_check.svg';

  // ── Bottom navigation (`3148:27106`) ───────────────────────────────────────

  static const String _navBase = 'assets/icons/navigation';

  /// Home tab.
  static const String navHome = '$_navBase/home.svg';

  /// Service / requests tab.
  static const String navRequest = '$_navBase/service.svg';

  /// Messages tab.
  static const String navMessage = '$_navBase/messages.svg';

  /// Settings tab.
  static const String navSettings = '$_navBase/settings.svg';

  /// Center FAB document action.
  static const String navCenterAction = '$_navBase/center_action.svg';

  // ── Header / actions ───────────────────────────────────────────────────────

  /// Notification bell — header icon (unread dot rendered in Flutter).
  static const String notification = '$_base/notification.svg';

  // ── Search bar ─────────────────────────────────────────────────────────────

  /// Magnifying glass — Figma `Bars / Search Bars` leading icon.
  static const String search = '$_base/search.svg';

  /// Magnifier with alert mark — search-empty states (`1517:9783`).
  static const String searchAlert = '$_base/search_alert.svg';

  /// Two-people outline — team empty / search-empty states (`1563:11019`).
  static const String users2 = '$_base/users_2.svg';

  /// Microphone — Figma `Bars / Search Bars` trailing icon.
  static const String mic = '$_base/mic.svg';

  // ── Form fields ────────────────────────────────────────────────────────────

  /// Map / location — branch location field leading icon.
  static const String map = '$_base/map.svg';

  /// Red map pin marker — Figma location / coverage map pin.
  static const String mapPinMarker = '$_base/map_pin_marker.svg';

  /// Outline map pin — Figma coverage empty state `map-pin` (`1563:10990`).
  static const String pin = '$_base/pin.svg';

  /// Outline car — service card icon (`962:6345`).
  static const String car = '$_base/car.svg';

  /// Teal radius ring overlay — Figma coverage map ellipse.
  static const String mapRadiusRing = '$_base/map_radius_ring.svg';

  /// UAE flag — phone field country prefix.
  static const String flagAe = '$_base/flag_ae.svg';

  /// Phone with incoming arrow — contact information sheet header
  /// (`3809:18013`).
  static const String phoneOutcome = '$_base/phone_outcome.svg';

  /// Chevron down — select / dropdown fields.
  static const String chevronDown = '$_base/chevron_down.svg';

  /// Close (X) — modal / form dismiss.
  static const String close = '$_base/close.svg';

  /// Trash / delete — list row remove action.
  static const String trash = '$_base/trash.svg';

  /// Bold trash — destructive action rows (e.g. branch actions sheet).
  static const String trashBold = '$_base/trash_bold.svg';

  // ── Branch actions bottom sheet ────────────────────────────────────────────

  /// Store / branch — header icon on white background.
  static const String branchStore = '$_base/branch_store.svg';

  /// View branch — expand / focus icon.
  static const String branchView = '$_base/branch_view.svg';

  /// Set under maintenance — settings gear icon.
  static const String branchMaintenance = '$_base/branch_maintenance.svg';

  /// Edit branch — pencil icon.
  static const String branchEdit = '$_base/branch_edit.svg';

  // ── Worker actions bottom sheet ────────────────────────────────────────────

  /// Two vertical bars (pause) — Suspend Worker action row (`1526:12629`).
  static const String workerSuspend = '$_base/worker_suspend.svg';

  /// Chat bubble with send arrow — Reset Password action row (`1526:12619`).
  static const String workerResetPassword = '$_base/worker_reset_password.svg';

  // ── Invitation actions bottom sheet ────────────────────────────────────────

  /// Overlapping squares — Copy Invitation Link (`1607:12705`).
  static const String invitationCopy = '$_base/invitation_copy.svg';

  /// Envelope + send arrow — Resend Invitation (`1607:12706`).
  static const String invitationResend = '$_base/invitation_resend.svg';

  // ── Organization settings stat cards ───────────────────────────────────────

  /// Crossed wrench + screwdriver — general settings (`1563:11093`).
  /// Baked stroke `#ECA100` (`YellowPalette.shade500`); recolor via
  /// `colorFilter` when a different tint is needed.
  static const String tools = '$_base/tools.svg';

  /// Invitations — outbound mail icon.
  static const String mailOut = '$_base/mail_out.svg';

  /// Services — bag icon.
  static const String bag = '$_base/bag.svg';

  /// Filter lines — services dashboard filter button (`4715:26126`).
  static const String filterLines = '$_base/filter_lines.svg';

  /// Wallet — service card revenue metric (`4715:26272`).
  static const String wallet = '$_base/wallet.svg';

  /// File / document — service card requests metric (`4715:26265`).
  static const String fileText = '$_base/file_text.svg';

  // ── Invitation flow (mocked UI, no backend) ────────────────────────────────

  /// Sanad wordmark — invitation-flow header logo (`2560:24653`). The
  /// gradient background behind it is drawn natively, not part of this asset.
  static const String sanadLogo = '$_base/sanad_logo.svg';

  /// Badge-check glyph inside the success-screen circle (`2560:24743`).
  static const String badgeCheck = '$_base/badge_check.svg';

  // ── Registration flow ──────────────────────────────────────────────────────

  /// Building / clipboard icon — Organization account-type card.
  static const String registrationOrganization =
      '$_base/registration_organization.svg';

  /// Person-in-circle icon — Individual account-type card.
  static const String registrationIndividual =
      '$_base/registration_individual.svg';

  /// City / building icon — Organization Details header (`2142:14206`).
  static const String registrationCity = '$_base/registration_city.svg';

  /// Profile circle — Individual Details header (`2982:18077`).
  static const String registrationProfile = '$_base/registration_profile.svg';

  /// Scan-corners icon — Identity Verification header (`2971:3589`).
  static const String registrationIdentityScan =
      '$_base/registration_identity_scan.svg';

  /// Cloud with upload arrow — document upload dropzone / CTA (`2897:13382`).
  static const String cloudUpload = '$_base/cloud_upload.svg';

  /// Document / mirror icon — Trade Licence header (`3001:19254`).
  static const String registrationTradeLicence =
      '$_base/registration_trade_licence.svg';

  /// Green check — ID side review success (`2897:13686`).
  static const String registrationCheckCircle =
      '$_base/registration_check_circle.svg';

  /// Red X — Review Information error alert (`3001:19468`).
  static const String registrationAlertCancel =
      '$_base/registration_alert_cancel.svg';

  /// Right arrow — Scan Back Side CTA (`2897:13631` icon).
  static const String registrationArrowRight =
      '$_base/registration_arrow_right.svg';

  /// Circular refresh — Retake Front/Back Side CTA (`2897:13632` icon).
  static const String registrationRetake = '$_base/registration_retake.svg';

  /// Replace document — Identity Verification success actions.
  static const String registrationReplace = '$_base/registration_replace.svg';

  /// Remove document — Identity Verification success actions.
  static const String registrationRemove = '$_base/registration_remove.svg';

  // ── Asset picker action sheet (`2947:14236`) ───────────────────────────────

  /// Cloud upload — asset picker "Upload file" row (`2947:14240`).
  static const String assetPickerUploadFile =
      '$_base/asset_picker_upload_file.svg';

  /// Scan viewfinder — asset picker "Scan or capture" row (`2947:14241`).
  static const String assetPickerScanCapture =
      '$_base/asset_picker_scan_capture.svg';

  /// Gallery with add — asset picker "Upload from Gallery" row (`2947:14242`).
  static const String assetPickerGallery = '$_base/asset_picker_gallery.svg';

  // ── Social profile brand icons (24×24) ─────────────────────────────────────

  /// Facebook — organization social profiles.
  static const String socialFacebook = '$_base/social_facebook.svg';

  /// TikTok — organization social profiles.
  static const String socialTiktok = '$_base/social_tiktok.svg';

  /// Instagram — organization social profiles.
  static const String socialInstagram = '$_base/social_instagram.svg';

  /// X (Twitter) — organization social profiles.
  static const String socialTwitter = '$_base/social_twitter.svg';

  // ── Organization setup stepper (`4349:5171`) ───────────────────────────────

  /// Phone handset — "Business Profile" stage icon.
  static const String call = '$_base/call.svg';

  /// Two-tier building with window dots — "First Branch" stage icon.
  static const String officeBuilding = '$_base/office_building.svg';

  /// Head-and-shoulders outline — "First Team Member" stage icon.
  static const String userOutline = '$_base/user_outline.svg';

  /// Upward trend line — "Grow Your Business" stage icon.
  static const String trendingUp = '$_base/trending_up.svg';

  // ── Home dashboard Quick Actions (Figma `6755:26003`) ──────────────────────

  /// Plus-in-circle — Home "Add Service" quick action (Figma `6801:6764`).
  static const String homeActionAddService =
      '$_base/home_action_add_service.svg';

  /// Git-branch — Home "Add Branch" quick action (Figma `6801:6767`).
  static const String homeActionAddBranch = '$_base/home_action_add_branch.svg';

  /// User-with-plus — Home "Invite Member" quick action (Figma `6801:6772`).
  static const String homeActionInviteMember =
      '$_base/home_action_invite_member.svg';

  /// Git-pull-request — Home "New Request" quick action (Figma `6801:6776`).
  static const String homeActionNewRequest =
      '$_base/home_action_new_request.svg';

  // ── Client onboarding (Figma `6979:27187` / `6974:25087` / `6979:27423`) ──

  /// Sparkle + checkmark splash mark — client onboarding splash screen
  /// (`6979:27190`). Distinct from [sanadLogo] (wordmark) and [badgeCheck].
  static const String onboardingSplashMark =
      '$_base/onboarding_splash_mark.svg';

  /// UAE PASS logo — "Continue with UAE PASS" button (`6736:49231` subtree
  /// of `6979:25202`).
  static const String uaePassLogo = '$_base/uae_pass_logo.svg';

  /// Smartphone/device outline — "Phone" sign-in option (`6979:25218`).
  static const String smartphoneDevice = '$_base/smartphone_device.svg';

  /// Send/mail icon — Continue with Email screen icon circle (`7002:27956`).
  static const String sendMail = '$_base/send_mail.svg';
}
