import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_suggestion.dart';

/// The suggestions shown before a conversation starts — Figma
/// `quick-suggestions` (`5153:42722`).
///
/// A local constant, not a use case or a repository: there is no backend for
/// suggestions yet, and this phase is a client-side mock by design. Swapping
/// this out for an agent- or backend-driven list later is a change to this
/// one list, not to `AiChatPage` or the widget that renders it — neither
/// reads anything but `id`/`labelKey`.
const List<AiChatSuggestion> defaultAiChatSuggestions = [
  AiChatSuggestion(
    id: 'renew_emirates_id',
    labelKey: 'ai_chat.suggestion_renew_emirates_id',
  ),
  AiChatSuggestion(
    id: 'passport_expiry',
    labelKey: 'ai_chat.suggestion_passport_expiry',
  ),
];
