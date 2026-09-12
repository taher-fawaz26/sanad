/// SVG asset paths shipped under `packages/app_assets/assets/svgs/`.
///
/// Load with `AppSvgPicture.asset(AppSvgs.x)` from `design_system`, or
/// `SvgPicture.asset(AppSvgs.x, package: AppAssets.package)`.
abstract final class AppSvgs {
  AppSvgs._();

  static const String _base = 'assets/svgs';

  /// Upward-swiping hand — the AI chat contextual sheet's "Swipe up"
  /// affordance (Figma `image 11 [Vectorized]`, `8428:37444`). Vertical
  /// motion, so it is direction-neutral and must not be mirrored in RTL.
  static const String aiSwipeUpHand = '$_base/ai_swipe_up_hand.svg';

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

  /// Dotted connector + link glyph between the phone/laptop mocks on the
  /// "Continue in UAE PASS" screen (`7030:28401`).
  static const String uaePassConnectionBridge =
      '$_base/uae_pass_connection_bridge.svg';

  /// OTP screen icon — a message with a text cursor (`7063:25588`).
  static const String otpPasswordCursor = '$_base/password_cursor.svg';

  /// Sparkle mark shown inside the phone mock on the "Continue in UAE PASS"
  /// screen (`7030:28417`) — distinct from [onboardingSplashMark] (different
  /// colors/shape, a separate Figma illustration).
  static const String uaePassDeviceSparkle =
      '$_base/uae_pass_device_sparkle.svg';

  // ── UAE PASS flow — Waiting / Collecting / Success (Figma `7039:28597` /
  // `7020:28255` / `7043:28742`) ──────────────────────────────────────────

  /// Large sparkle + checkmark mark — "Waiting for UAE PASS" screen
  /// (`7076:29215`). A separate export from [uaePassDeviceSparkle]: same
  /// motif, different aspect ratio and a slightly different accent shade, so
  /// kept as its own asset rather than reusing/rescaling that one.
  static const String uaePassWaitingMark = '$_base/uae_pass_waiting_mark.svg';

  /// Scalloped success seal + checkmark — "You're all set!" screen
  /// (`7081:29231`).
  static const String uaePassSuccessSeal = '$_base/uae_pass_success_seal.svg';

  /// Per-row loading arc — "We collect data from UAE PASS" details card,
  /// in-progress row indicator (`7042:28718`).
  static const String uaePassLoadingArc = '$_base/uae_pass_loading_arc.svg';

  /// Document/notes icon — details card "Verified identity" row
  /// (`7020:28367`).
  static const String uaePassVerifiedIdentity =
      '$_base/uae_pass_verified_identity.svg';

  /// Phone-with-plus icon — details card "Mobile number" row (`7020:28373`).
  static const String uaePassMobileNumber = '$_base/uae_pass_mobile_number.svg';

  // ── AI chat home + composer (Figma `7118:29597` / `5153:42646` /
  // `7827:30542`) ─────────────────────────────────────────────────────────

  /// Two-tone sparkle mark — composer's leading "Sanad" glyph. Baked-in
  /// brand colors (`#1A7E6B` / `#87FC00`); rendered without a `colorFilter`,
  /// like [sanadLogo].
  static const String aiChatSparkle = '$_base/ai_chat_sparkle.svg';

  /// The "Sanad" nav-pill glyph — Figma `header-profile` (`7124:29682`).
  ///
  /// Green + lime (`#1A7A66` / `#87FC00`) at ~19dp, its own third colorway
  /// alongside [aiChatSparkle] and [aiChatHeroMark]. Rendered without a
  /// `colorFilter`, like [sanadLogo].
  ///
  /// This file previously held the **hero** export by mistake — 93×91,
  /// `white` + `#1A7A66`. Scaled into a 19dp nav slot, its white body
  /// disappeared against the white pill and only the dark check remained, so
  /// the selected destination showed a small dark smudge instead of the
  /// sparkle.
  static const String aiChatNavMark = '$_base/ai_chat_nav_mark.svg';

  /// The Home hero's large sparkle mark (Figma `7118:29600`).
  ///
  /// The same silhouette as [aiChatSparkle] in a **different colorway** —
  /// `white` + `#1A7A66` here, against the composer glyph's `#1A7E6B` +
  /// `#87FC00` lime. It reads as white because it sits on the hero's green
  /// bloom, where the composer's lime would disappear. Both are baked-in
  /// brand colors, so neither takes a `colorFilter`; scaling the composer
  /// export up to hero size would render the wrong colors, which is why this
  /// is its own asset rather than a size variant.
  static const String aiChatHeroMark = '$_base/ai_chat_hero_mark.svg';

  /// Outline document — the "Requests" nav-pill glyph. Single-color stroke
  /// (baked `#5C6C75`); recolor via `colorFilter` for the active/inactive
  /// tint rather than keeping a second copy per state.
  static const String aiChatNavPaper = '$_base/ai_chat_nav_paper.svg';

  /// Outline folder — the "My Life" nav-pill glyph. Single-color stroke,
  /// recolor via `colorFilter` as with [aiChatNavPaper].
  static const String aiChatNavFolder = '$_base/ai_chat_nav_folder.svg';

  /// Outline clock-in-circle — the History button glyph. Also the
  /// Conversation History screen's own trailing nav glyph (`8120:3285`),
  /// which is the same Iconly `Time Circle` export.
  static const String aiChatNavHistory = '$_base/ai_chat_nav_history.svg';

  /// Two-tone chat bubble with three dots — the centre of Conversation
  /// History's empty state (Figma `8124:3835`, Iconly `Chat`).
  ///
  /// Stroked in `#26A68C` (`MainPalette.shade600`), which is baked in rather
  /// than recolored: the glyph sits on its own pale-green bloom and the
  /// design specifies that one green for it.
  ///
  /// The `viewBox` is offset by half the 2.6765 stroke width relative to
  /// Figma's raw export so the round caps at the bubble's extremes are not
  /// clipped — Figma's HTML wrapper achieves the same with a negative inset,
  /// which has no equivalent inside an SVG viewport. Path data is verbatim,
  /// so drawing the file at 41.0394 reproduces Figma's own scale (a 38.3629
  /// glyph plus its stroke bleed) — see
  /// `ConversationHistoryTokens.emptyGlyphSize`.
  static const String aiChatHistoryEmptyChat =
      '$_base/ai_chat_history_empty_chat.svg';

  // ── Live Voice (Figma `Chat – 06/07/08`, `7137:29887` / `7880:16671` /
  // `7873:16622`) ─────────────────────────────────────────────────────────

  /// The Live Voice hero mark (Figma `7880:16695`) — the **fourth** colorway
  /// of Sanad's sparkle: `white` + lime `#87FC00`, at ~86×84.
  ///
  /// Each surface gets its own export because each sits on a different
  /// ground, and the marks are not recolourable (their brand colors are baked
  /// in, so no `colorFilter` applies):
  ///
  /// | asset | colors | ground |
  /// |---|---|---|
  /// | [aiChatSparkle] | `#1A7E6B` + `#87FC00` | white composer/bubble |
  /// | [aiChatNavMark] | `#1A7A66` + `#87FC00` | white nav pill |
  /// | [aiChatHeroMark] | `white` + `#1A7A66` | pale green chat bloom |
  /// | [aiChatVoiceMark] | `white` + `#87FC00` | dark green voice gradient |
  static const String aiChatVoiceMark = '$_base/ai_chat_voice_mark.svg';

  /// The Live Voice close (X) — Figma `7880:16685`, 32dp, stroked `#F9F9FA`
  /// for the dark background. Single-color, so it recolors via `colorFilter`.
  static const String aiChatVoiceClose = '$_base/ai_chat_voice_close.svg';

  /// Filled microphone — composer dictation button, Default/Focused states.
  static const String aiChatComposerMic = '$_base/ai_chat_composer_mic.svg';

  /// Plus — composer attach button.
  static const String aiChatComposerPlus = '$_base/ai_chat_composer_plus.svg';

  /// Right-arrow chevron — composer Send button.
  static const String aiChatComposerSend = '$_base/ai_chat_composer_send.svg';

  // ── Client requests (`8385:4513`) ──────────────────────────────────────────

  /// Outline calendar — the request card's date pill (`8385:4522`). 16dp,
  /// single-stroke, so it recolors via `colorFilter`.
  static const String requestCalendar = '$_base/request_calendar.svg';

  /// Diagonal maps arrow — the request card's area pill (`8385:4531`). 16dp,
  /// single-stroke.
  static const String requestAreaArrow = '$_base/request_area_arrow.svg';
}
