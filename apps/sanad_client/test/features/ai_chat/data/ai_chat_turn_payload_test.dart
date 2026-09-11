import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/ai_chat_turn_payload.dart';

import '../support/attachment_fixtures.dart';

Map<String, dynamic> decode(String body) =>
    jsonDecode(body) as Map<String, dynamic>;

List<Map<String, dynamic>> attachmentsOf(Map<String, dynamic> body) => [
  for (final a in body['attachments'] as List<dynamic>)
    a as Map<String, dynamic>,
];

void main() {
  const conversationId = 'conv_1';

  group('a text turn is unchanged', () {
    test('carries exactly conversation_id and message', () {
      final body = decode(
        AiChatTurnPayload.encode(
          conversationId: conversationId,
          message: 'book me a service',
        ),
      );

      expect(body, <String, dynamic>{
        'conversation_id': conversationId,
        'message': 'book me a service',
      });
    });

    test('omits attachments entirely rather than sending an empty list', () {
      // The whole reason this change is additive: the endpoint receives the
      // same two-field body it always has. Turning this into `[]` would be a
      // protocol change disguised as tidying.
      final body = AiChatTurnPayload.encode(
        conversationId: conversationId,
        message: 'hello',
      );

      expect(body, isNot(contains('attachments')));
    });

    test('does not trim the message', () {
      // Trimming already happened in the bloc; doing it twice would silently
      // change a body the transport tests pin.
      final body = decode(
        AiChatTurnPayload.encode(
          conversationId: conversationId,
          message: '  spaced  ',
        ),
      );

      expect(body['message'], '  spaced  ');
    });
  });

  group('attachments carry an id and a resolved url', () {
    test('a normal attachment object has exactly id and url', () {
      final body = decode(
        AiChatTurnPayload.encode(
          conversationId: conversationId,
          message: 'what does this say?',
          attachments: [
            uploadedFixture(
              source: imageFixture(),
              mediaId: 'upl_123',
              url: 'https://cdn.invalid/upl_123.jpg',
            ),
          ],
        ),
      );

      expect(attachmentsOf(body).single, <String, dynamic>{
        'id': 'upl_123',
        'url': 'https://cdn.invalid/upl_123.jpg',
      });
    });

    test('a document is the same two keys', () {
      final body = decode(
        AiChatTurnPayload.encode(
          conversationId: conversationId,
          message: '',
          attachments: [uploadedFixture(source: documentFixture())],
        ),
      );

      expect(attachmentsOf(body).single.keys, unorderedEquals(['id', 'url']));
    });

    test('order is preserved', () {
      final body = decode(
        AiChatTurnPayload.encode(
          conversationId: conversationId,
          message: 'three things',
          attachments: [
            uploadedFixture(source: imageFixture(), mediaId: 'a'),
            uploadedFixture(source: documentFixture(), mediaId: 'b'),
            uploadedFixture(
              source: imageFixture(id: 'att_2'),
              mediaId: 'c',
            ),
          ],
        ),
      );

      expect([for (final a in attachmentsOf(body)) a['id']], ['a', 'b', 'c']);
    });

    test('nothing local ever leaves the device', () {
      // A path, file name, MIME type or size on the wire would describe a
      // file the agent already has a URL for — and `localPath` in particular
      // is a device detail the backend must never learn.
      final body = AiChatTurnPayload.encode(
        conversationId: conversationId,
        message: 'look',
        attachments: [
          uploadedFixture(
            source: imageFixture(
              localPath: '/data/user/0/private/photo.jpg',
              sizeBytes: 4242,
            ),
          ),
          uploadedFixture(
            source: documentFixture(
              localPath: '/data/user/0/private/report.pdf',
              sizeBytes: 9191,
            ),
            mediaId: 'upl_doc',
          ),
        ],
      );

      expect(body, isNot(contains('/data/user/0/private')));
      expect(body, isNot(contains('photo.jpg')));
      expect(body, isNot(contains('report.pdf')));
      expect(body, isNot(contains('image/jpeg')));
      expect(body, isNot(contains('4242')));
      expect(body, isNot(contains('9191')));
    });
  });

  group('no audio attachment can be serialized', () {
    // AI Chat retired recorded audio: its one voice input is Speech-to-Text,
    // which reaches the agent as ordinary text in `message`. These assert the
    // wire contract that decision produced, so reintroducing an audio
    // discriminator fails here rather than silently reaching the backend.
    test('an attachment object is exactly id and url, always', () {
      final body = AiChatTurnPayload.encode(
        conversationId: conversationId,
        message: 'what does this say?',
        attachments: [
          uploadedFixture(source: imageFixture(), mediaId: 'a'),
          uploadedFixture(source: documentFixture(), mediaId: 'b'),
        ],
      );

      for (final attachment in attachmentsOf(decode(body))) {
        expect(attachment.keys, unorderedEquals(['id', 'url']));
      }
    });

    test('the encoded body carries no audio vocabulary at all', () {
      final body = AiChatTurnPayload.encode(
        conversationId: conversationId,
        message: 'book me for tomorrow at nine',
        attachments: [
          uploadedFixture(source: imageFixture(), mediaId: 'a'),
        ],
      );

      expect(body, isNot(contains('audio')));
      expect(body, isNot(contains('transcript')));
      expect(body, isNot(contains('"type"')));
      expect(body, isNot(contains('waveform')));
      expect(body, isNot(contains('duration')));
    });

    test('a dictated turn is byte-identical to a typed one', () {
      // The product invariant: once the recogniser lets go, its words are
      // ordinary composer text and the request cannot tell the two apart.
      const spoken = 'book me for tomorrow at nine';

      expect(
        AiChatTurnPayload.encode(
          conversationId: conversationId,
          message: spoken,
        ),
        AiChatTurnPayload.encode(
          conversationId: conversationId,
          message: spoken,
        ),
      );
      expect(
        AiChatTurnPayload.encode(
          conversationId: conversationId,
          message: spoken,
        ),
        '{"conversation_id":"$conversationId","message":"$spoken"}',
      );
    });
  });
}
