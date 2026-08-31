import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/mock_ai_chat_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/mock_scenarios.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/actions/ai_chat_action_handlers.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_chat_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/ai_chat_bubble.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/ai_chat_composer.dart';
import 'package:shared_ui/shared_ui.dart';

/// The chat surface: message list, scenario picker and composer.
class AiChatPage extends StatefulWidget {
  /// Creates the chat page.
  const AiChatPage({super.key, this.mockSource});

  /// Present only in the prototype: lets the dev scenario picker force a
  /// specific scripted reply. A production source would not expose this.
  final MockAiChatEventSource? mockSource;

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  AiUiEnvironment? _environment;
  String? _selectedScenarioId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Built once, not per frame: AiUiHost compares environments to decide
    // whether to notify, and a fresh instance every build would invalidate
    // every surface beneath it.
    _environment ??= _buildEnvironment(context.read<AiChatBloc>());
  }

  AiUiEnvironment _buildEnvironment(AiChatBloc bloc) => AiUiEnvironment(
    registry: defaultRendererRegistry(
      // Developers see which component the agent asked for; users never do.
      showUnsupportedMarker: !kReleaseMode,
    ),
    actions: buildAiChatActionRegistry(
      onSendMessage: (text) => bloc.add(AiChatMessageSubmitted(text)),
    ),
    diagnostics: const LoggingAiUiDiagnosticsSink(),
    strings: AiUiStrings(
      metresSuffix: 'ai_chat.unit_metres'.tr(),
      kilometresSuffix: 'ai_chat.unit_kilometres'.tr(),
      unsupportedContent: 'ai_chat.unsupported_content'.tr(),
    ),
  );

  void _selectScenario(String? id) {
    setState(() => _selectedScenarioId = id);
    widget.mockSource?.forcedScenarioId = id;
  }

  @override
  Widget build(BuildContext context) {
    final environment = _environment;
    if (environment == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppNavBar(title: 'ai_chat.title'.tr()),
      body: AiUiHost(
        environment: environment,
        child: Column(
          children: [
            const Expanded(child: _MessageList()),
            if (widget.mockSource != null)
              _ScenarioPicker(
                selectedId: _selectedScenarioId,
                onSelected: _selectScenario,
              ),
            AiChatComposer(
              onSend: (text) =>
                  context.read<AiChatBloc>().add(AiChatMessageSubmitted(text)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList();

  @override
  Widget build(BuildContext context) {
    final activeStream = context.read<AiChatBloc>().activeStream;

    return BlocBuilder<AiChatBloc, AiChatState>(
      // Only list-shaped changes rebuild the list. Token deltas never emit
      // state at all, so they cannot reach here.
      buildWhen: (previous, current) =>
          previous.messages != current.messages ||
          previous.isTyping != current.isTyping,
      builder: (context, state) {
        if (state.isEmpty && !state.isTyping) {
          return AppEmptyState(
            title: 'ai_chat.empty_title'.tr(),
            description: 'ai_chat.empty_description'.tr(),
            illustration: const AppEmptyStateImage(
              assetPath: AppImages.emptyState,
            ),
          );
        }

        final rows = state.messages.reversed.toList();

        return ListView.separated(
          // Reversed so new messages appear at the bottom without the list
          // re-laying-out the whole conversation each time one arrives.
          reverse: true,
          padding: EdgeInsets.all(AppSpacing.md),
          itemCount: rows.length + (state.isTyping ? 1 : 0),
          separatorBuilder: (_, _) => SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            if (state.isTyping && index == 0) return const _TypingIndicator();
            final message = rows[index - (state.isTyping ? 1 : 0)];

            // A stable key plus a repaint boundary: an unchanged bubble is
            // neither rebuilt nor repainted when its neighbours change.
            return RepaintBoundary(
              key: ValueKey(message.id),
              child: AiChatBubble(
                message: message,
                activeStream: activeStream,
              ),
            );
          },
        );
      },
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: AppRadius.circularMd,
        border: Border.all(color: context.appColors.border),
      ),
      child: Semantics(
        label: 'ai_chat.typing'.tr(),
        liveRegion: true,
        child: const AppLoadingIndicator(size: 20),
      ),
    ),
  );
}

/// Prototype-only affordance for replaying a specific scripted reply,
/// including the deliberately broken ones.
class _ScenarioPicker extends StatelessWidget {
  const _ScenarioPicker({required this.selectedId, required this.onSelected});

  final String? selectedId;
  final void Function(String? id) onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: mockScenarios.length + 1,
      separatorBuilder: (_, _) => SizedBox(width: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (index == 0) {
          return AppChip(
            label: 'ai_chat.scenario_auto'.tr(),
            selected: selectedId == null,
            style: AppChipStyle.outline,
            onTap: () => onSelected(null),
          );
        }
        final scenario = mockScenarios[index - 1];
        return AppChip(
          label: scenario.label,
          selected: selectedId == scenario.id,
          style: AppChipStyle.outline,
          onTap: () => onSelected(scenario.id),
        );
      },
    ),
  );
}
