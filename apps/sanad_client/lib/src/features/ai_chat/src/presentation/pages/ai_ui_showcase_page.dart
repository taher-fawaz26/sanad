import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/features/ai_chat/src/ai_chat_config.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/showcase_fixtures.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/actions/ai_chat_action_handlers.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/home/ai_chat_background.dart';

/// Every semantic component in the catalog, rendered through the real
/// protocol — the validation surface for a design change.
///
/// **Development only.** `AiChatModule` registers this route inside its
/// `!kReleaseMode` block, so the path does not exist in a shipped app and
/// nothing can deep-link into it.
///
/// The point is that nothing here is a demo widget. Every fixture is raw wire
/// JSON handed to `AiChatConfig.validator` and drawn by `AiUiSurface` inside a
/// real `AiUiHost`, so what appears on screen is exactly what the chat would
/// render for the same payload. A component that only looks right in a
/// hand-built preview is not validated at all.
///
/// Three controls sit in the header because they are the three things a design
/// review actually needs: mirror the layout, scale the text, and see what the
/// validator threw away.
class AiUiShowcasePage extends StatefulWidget {
  /// Creates the page.
  const AiUiShowcasePage({super.key});

  @override
  State<AiUiShowcasePage> createState() => _AiUiShowcasePageState();
}

class _AiUiShowcasePageState extends State<AiUiShowcasePage> {
  /// Text-scale steps a reviewer actually checks: default, comfortable, and
  /// the accessibility size that breaks layouts.
  static const _textScales = [1.0, 1.5, 2.0];

  late final AiUiEnvironment _environment;
  late final RecordingAiUiDiagnosticsSink _diagnostics;
  late final AiUiValidator _validator;
  late final List<ShowcaseGroup> _groups;

  /// `null` until the first build, then the app's own direction — so an
  /// Arabic reviewer opens the showcase already mirrored and the chip is a
  /// deliberate override rather than the only way to see RTL.
  bool? _rtl;
  bool _showDiagnostics = false;
  int _scaleIndex = 0;

  @override
  void initState() {
    super.initState();
    // Recording rather than logging: the reviewer can see on screen what the
    // validator refused, which is the one thing a screenshot cannot show.
    _diagnostics = RecordingAiUiDiagnosticsSink();
    _environment = AiUiEnvironment(
      registry: defaultRendererRegistry(showUnsupportedMarker: !kReleaseMode),
      // Actions resolve, and say so, without a composer or a live
      // conversation behind them: the default capability set is the stub, which
      // acknowledges every request instead of touching a sensor.
      actions: buildAiChatActionRegistry(onSendMessage: _showSentMessage),
      diagnostics: _diagnostics,
      strings: AiUiStrings(
        metresSuffix: 'ai_chat.unit_metres'.tr(),
        kilometresSuffix: 'ai_chat.unit_kilometres'.tr(),
        unsupportedContent: 'ai_chat.unsupported_content'.tr(),
        openInMaps: 'ai_chat.open_in_maps'.tr(),
        ratingOutOfFive: 'ai_chat.rating_out_of_five'.tr(),
      ),
    );
    _validator = AiChatConfig.validator(keepUnsupportedNodes: !kReleaseMode);
    _groups = showcaseGroups();
  }

  /// Stands in for the conversation: a card that posts a user turn shows what
  /// it would have sent.
  void _showSentMessage(String text) => showAppSnackbar(
    context: context,
    title: 'ai_chat.showcase_sent'.tr(),
    caption: text,
  );

  @override
  Widget build(BuildContext context) {
    _diagnostics.clear();

    final rtl = _rtl ?? Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AiChatBackground(
        child: SafeArea(
          bottom: false,
          child: AiUiHost(
            environment: _environment,
            child: Directionality(
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(_textScales[_scaleIndex]),
                ),
                child: Column(
                  children: [
                    // Outside the Directionality/MediaQuery overrides on
                    // purpose: the controls must stay readable and in place
                    // while the content under them mirrors and grows.
                    _Header(
                      rtl: rtl,
                      scale: _textScales[_scaleIndex],
                      showDiagnostics: _showDiagnostics,
                      onBack: () => context.pop(),
                      onToggleRtl: () => setState(() => _rtl = !rtl),
                      onCycleScale: () => setState(() {
                        _scaleIndex = (_scaleIndex + 1) % _textScales.length;
                      }),
                      onToggleDiagnostics: () => setState(() {
                        _showDiagnostics = !_showDiagnostics;
                      }),
                    ),
                    Expanded(
                      child: _Catalogue(groups: _groups, page: this),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The showcase's own chrome.
///
/// Deliberately plain: it is developer tooling, not a designed surface, and
/// styling it would invite someone to review *it* instead of the components.
class _Header extends StatelessWidget {
  const _Header({
    required this.rtl,
    required this.scale,
    required this.showDiagnostics,
    required this.onBack,
    required this.onToggleRtl,
    required this.onCycleScale,
    required this.onToggleDiagnostics,
  });

  final bool rtl;
  final double scale;
  final bool showDiagnostics;
  final VoidCallback onBack;
  final VoidCallback onToggleRtl;
  final VoidCallback onCycleScale;
  final VoidCallback onToggleDiagnostics;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      // Two lines rather than one: three chips beside the title left it
      // ellipsized to "Com…" on a 360dp screen, and the title is how a
      // reviewer knows which surface a screenshot came from.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.xs,
        children: [
          Row(
            spacing: AppSpacing.sm,
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.chevron_left),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              ),
              Expanded(
                child: Text(
                  'ai_chat.showcase_title'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.appTypography
                      .semiBold(context.appTypography.regularNone)
                      .copyWith(color: colors.textPrimary),
                ),
              ),
            ],
          ),
          Row(
            spacing: AppSpacing.sm,
            children: [
              AppChip(
                label: rtl ? 'RTL' : 'LTR',
                selected: rtl,
                onTap: onToggleRtl,
              ),
              AppChip(
                label: '${scale.toStringAsFixed(1)}×',
                selected: scale != 1.0,
                onTap: onCycleScale,
              ),
              AppChip(
                label: 'ai_chat.showcase_diagnostics'.tr(),
                selected: showDiagnostics,
                onTap: onToggleDiagnostics,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The scrolling list of groups and fixtures.
class _Catalogue extends StatelessWidget {
  const _Catalogue({required this.groups, required this.page});

  final List<ShowcaseGroup> groups;
  final _AiUiShowcasePageState page;

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: EdgeInsetsDirectional.fromSTEB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      AppSpacing.xxxl + MediaQuery.viewPaddingOf(context).bottom,
    ),
    itemCount: groups.length,
    itemBuilder: (context, index) {
      final group = groups[index];
      return Column(
        key: ValueKey(group.title),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(
              top: AppSpacing.xl,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              group.title,
              style: context.appTypography
                  .bold(context.appTypography.smallNone)
                  .copyWith(color: context.appColors.textSecondary),
            ),
          ),
          for (final fixture in group.fixtures)
            _FixtureTile(
              key: ValueKey(fixture.title),
              fixture: fixture,
              page: page,
            ),
        ],
      );
    },
  );
}

/// One fixture: its name, its note, and the blocks it renders to.
class _FixtureTile extends StatelessWidget {
  const _FixtureTile({required this.fixture, required this.page, super.key});

  final ShowcaseFixture fixture;
  final _AiUiShowcasePageState page;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    // Validated here rather than up front so a fixture's diagnostics can be
    // shown next to the thing that produced them.
    final result = page._validator.validate(fixture.payload);
    final document = result.document;

    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: [
          Text(
            fixture.title,
            style: typography
                .medium(typography.tinyNone)
                .copyWith(color: colors.textMuted),
          ),
          if (fixture.note != null)
            Text(
              fixture.note!,
              style: typography.tinyNone.copyWith(color: colors.textMuted),
            ),
          if (document == null)
            _Diagnostics(
              lines: const ['payload rejected'],
              tone: colors.error,
            )
          else
            AiUiSurface(document: document),
          if (page._showDiagnostics && result.hasDiagnostics)
            _Diagnostics(
              lines: [
                for (final diagnostic in result.diagnostics)
                  _describe(diagnostic),
              ],
              tone: colors.warning,
            ),
        ],
      ),
    );
  }
}

/// One diagnostic as a single line.
///
/// Shape only — a code, a document path, a field name — never AI or user
/// prose. That is the protocol's own rule for diagnostics, and it is what
/// makes this safe to leave on screen in a screenshot.
String _describe(AiUiDiagnostic diagnostic) {
  final detail = diagnostic.detail;
  final suffix = detail == null ? '' : ' · $detail';
  return '${diagnostic.code.wire} · ${diagnostic.path}$suffix';
}

/// What the validator refused, shown in place.
class _Diagnostics extends StatelessWidget {
  const _Diagnostics({required this.lines, required this.tone});

  final List<String> lines;
  final Color tone;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: tone.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppDimension.radiusSm),
      border: Border.all(color: tone.withValues(alpha: 0.4)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final line in lines)
          Text(
            line,
            style: context.appTypography.tinyNone.copyWith(color: tone),
          ),
      ],
    ),
  );
}
