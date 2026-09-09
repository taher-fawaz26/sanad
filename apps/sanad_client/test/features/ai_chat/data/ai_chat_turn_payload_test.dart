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
      // A path, file name, MIME type, size, duration or waveform on the wire
      // would describe a file the agent already has a URL for — and
      // `localPath` in particular is a device detail the backend must never
      // learn.
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
            source: audioFixture(
              localPath: '/data/user/0/private/voice.m4a',
              waveform: const [0.7],
              transcript: 'hello there',
            ),
            mediaId: 'upl_audio',
          ),
        ],
      );

      expect(body, isNot(contains('/data/user/0/private')));
      expect(body, isNot(contains('photo.jpg')));
      expect(body, isNot(contains('voice.m4a')));
      expect(body, isNot(contains('image/jpeg')));
      expect(body, isNot(contains('4242')));
      expect(body, isNot(contains('waveform')));
      expect(body, isNot(contains('duration')));
    });
  });

  group('a voice note is one message carrying audio and its words', () {
    test('the transcript rides on the audio attachment', () {
      final body = decode(
        AiChatTurnPayload.encode(
          conversationId: conversationId,
          message: 'and here it is',
          attachments: [
            uploadedFixture(
              source: audioFixture(transcript: 'book me a plumber'),
              mediaId: 'upl_audio_123',
              url: 'https://cdn.invalid/upl_audio_123.m4a',
            ),
          ],
        ),
      );

      expect(attachmentsOf(body).single, <String, dynamic>{
        'id': 'upl_audio_123',
        'url': 'https://cdn.invalid/upl_audio_123.m4a',
        'type': 'audio',
        'transcript': 'book me a plumber',
      });
    });

    test('a typed caption is not displaced by the transcript', () {
      // The decisive reason the transcript is not the top-level `message`: a
      // turn can carry both, and the caption is what the user actually wrote.
      final body = decode(
        AiChatTurnPayload.encode(
          conversationId: conversationId,
          message: 'and here it is',
          attachments: [
            uploadedFixture(source: audioFixture(transcript: 'book a plumber')),
          ],
        ),
      );

      expect(body['message'], 'and here it is');
      expect(attachmentsOf(body).single['transcript'], 'book a plumber');
    });

    test('an untyped voice note mirrors its transcript into message', () {
      // The live agent answers an empty `message` with 200 and zero frames, so
      // a voice-only turn would otherwise be met with silence. It is also what
      // makes the note understood before the backend reads `attachments`.
      final body = decode(
        AiChatTurnPayload.encode(
          conversationId: conversationId,
          message: '',
          attachments: [
            uploadedFixture(source: audioFixture(transcript: 'book a plumber')),
          ],
        ),
      );

      expect(body['message'], 'book a plumber');
      expect(attachmentsOf(body).single['transcript'], 'book a plumber');
    });

    test('an audio attachment is typed even with no transcript', () {
      // So the agent knows this is speech it has chosen not to be given words
      // for, rather than an opaque blob it should try to read as text.
      final body = decode(
        AiChatTurnPayload.encode(
          conversationId: conversationId,
          message: 'listen to this',
          attachments: [uploadedFixture(source: audioFixture())],
        ),
      );

      final attachment = attachmentsOf(body).single;
      expect(attachment['type'], 'audio');
      expect(attachment.containsKey('transcript'), isFalse);
    });

    test('an image-only turn leaves message empty', () {
      // There are no words to mirror, and inventing some would put a sentence
      // the user never said into the model's context.
      final body = decode(
        AiChatTurnPayload.encode(
          conversationId: conversationId,
          message: '',
          attachments: [uploadedFixture(source: imageFixture())],
        ),
      );

      expect(body['message'], '');
    });
  });
}
