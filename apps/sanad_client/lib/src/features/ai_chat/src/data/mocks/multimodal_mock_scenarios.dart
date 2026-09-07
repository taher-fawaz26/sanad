import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/mock_scenarios.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_attachment.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_outgoing_message.dart';

/// Mocked replies for turns that carried attachments.
///
/// Deterministic by construction: the reply is a pure function of what was
/// attached, with no randomness and no clock. A test can assert the exact
/// prose, and two runs of the same turn produce identical events.
///
/// The reply is *about* the attachments — it names the file, counts the
/// photos, reads back the recording's length — because a mock that answered
/// "I received your message" regardless would prove nothing about whether the
/// attachments actually reached the conversation.
abstract final class MultimodalMockScenarios {
  /// Builds the assistant's reply to [message].
  ///
  /// Falls back to the keyword-matched text scenarios when nothing is
  /// attached, so a plain text turn behaves exactly as it did before.
  static List<AiChatEvent> reply(String messageId, AiOutgoingMessage message) {
    if (!message.hasAttachments) {
      return scenarioFor(message.text).build(messageId);
    }
    return mockSay(messageId, describe(message));
  }

  /// The prose the mock replies with. Public so a test can assert it without
  /// reassembling deltas.
  static String describe(AiOutgoingMessage message) {
    final images = message.attachments.whereType<AiImageAttachment>().toList();
    final documents = message.attachments
        .whereType<AiDocumentAttachment>()
        .toList();
    final audio = message.attachments.whereType<AiAudioAttachment>().toList();

    final parts = <String>[];

    if (images.length == 1) {
      parts.add('I received your image **${images.single.fileName}**.');
    } else if (images.length > 1) {
      parts.add('I received **${images.length} images**. Comparing them now.');
    }

    for (final document in documents) {
      parts.add(
        'I received your document **${document.fileName}** '
        '(${_readableSize(document.sizeBytes)}).',
      );
    }

    for (final take in audio) {
      parts.add(
        'From your recording (${_readableDuration(take.duration)}), '
        'here is what I understood.',
      );
    }

    final text = message.text.trim();
    parts.add(
      text.isEmpty
          ? 'What would you like me to do with it?'
          : 'You asked: "$text". Here is what I can tell you.',
    );

    return parts.join(' ');
  }

  /// `mm:ss`, which is how a voice note reads everywhere else in the app.
  static String _readableDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  static String _readableSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
