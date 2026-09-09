import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_renderer_registry.dart';
import 'package:ai_ui_renderer/src/rendering/renderers/control_renderers.dart';
import 'package:ai_ui_renderer/src/rendering/renderers/fallback_renderer.dart';
import 'package:ai_ui_renderer/src/rendering/renderers/layout_renderers.dart';
import 'package:ai_ui_renderer/src/rendering/renderers/media_renderers.dart';
import 'package:ai_ui_renderer/src/rendering/renderers/semantic/entity_cards.dart';
import 'package:ai_ui_renderer/src/rendering/renderers/semantic/interactive.dart';
import 'package:ai_ui_renderer/src/rendering/renderers/semantic/prompts.dart';
import 'package:ai_ui_renderer/src/rendering/renderers/semantic/summaries.dart';
import 'package:ai_ui_renderer/src/rendering/renderers/text_renderers.dart';

/// The stock registry: one renderer per node type in the v1 catalog.
///
/// An app can [AiUiRendererRegistry.register] over any entry to specialise a
/// node without forking this list.
AiUiRendererRegistry defaultRendererRegistry({
  bool showUnsupportedMarker = false,
}) => AiUiRendererRegistry(
  fallbackRenderer: showUnsupportedMarker
      ? const AiUiUnsupportedRenderer()
      : null,
  renderers: const {
    // Primitives
    AiUiNodeType.text: AiUiTextRenderer(),
    AiUiNodeType.richText: AiUiRichTextRenderer(),
    AiUiNodeType.icon: AiUiIconRenderer(),
    AiUiNodeType.image: AiUiImageRenderer(),
    AiUiNodeType.divider: AiUiDividerRenderer(),
    AiUiNodeType.spacer: AiUiSpacerRenderer(),
    AiUiNodeType.row: AiUiRowRenderer(),
    AiUiNodeType.column: AiUiColumnRenderer(),
    AiUiNodeType.card: AiUiCardRenderer(),
    AiUiNodeType.button: AiUiButtonRenderer(),
    AiUiNodeType.chip: AiUiChipRenderer(),
    AiUiNodeType.list: AiUiListRenderer(),
    AiUiNodeType.listItem: AiUiListItemRenderer(),
    AiUiNodeType.progress: AiUiProgressRenderer(),
    AiUiNodeType.loading: AiUiLoadingRenderer(),

    // Semantic — entity cards
    AiUiNodeType.serviceCard: AiUiServiceCardRenderer(),
    AiUiNodeType.appointmentCard: AiUiAppointmentCardRenderer(),
    AiUiNodeType.branchCard: AiUiBranchCardRenderer(),
    AiUiNodeType.documentCard: AiUiDocumentCardRenderer(),
    AiUiNodeType.orderCard: AiUiOrderCardRenderer(),
    AiUiNodeType.providerCard: AiUiProviderCardRenderer(),

    // Semantic — summaries
    AiUiNodeType.bookingSummary: AiUiBookingSummaryRenderer(),
    AiUiNodeType.requestSummary: AiUiRequestSummaryRenderer(),
    AiUiNodeType.paymentReceipt: AiUiPaymentReceiptRenderer(),

    // Semantic — interactive
    AiUiNodeType.quickReply: AiUiQuickReplyRenderer(),
    AiUiNodeType.timeSlots: AiUiTimeSlotsRenderer(),
    AiUiNodeType.reviewRequest: AiUiReviewRequestRenderer(),
    AiUiNodeType.locationPicker: AiUiLocationPickerRenderer(),

    // Semantic — prompts
    AiUiNodeType.reminderCard: AiUiReminderCardRenderer(),
    AiUiNodeType.mediaRequest: AiUiMediaRequestRenderer(),
    AiUiNodeType.permissionRequest: AiUiPermissionRequestRenderer(),
    AiUiNodeType.locationConfirm: AiUiLocationConfirmRenderer(),
  },
);
