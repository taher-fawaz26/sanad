import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/sse_frame_parser.dart';

/// Feeds [chunks] in order and returns every frame produced.
List<String> parseAll(List<String> chunks) {
  final parser = SseFrameParser();
  return [for (final chunk in chunks) ...parser.addChunk(chunk)];
}

/// Decodes [bytes] split at [cut] through one streaming UTF-8 decoder, exactly
/// as the transport does, and returns the frames that come out.
List<String> parseBytesSplitAt(List<int> bytes, int cut) {
  final parser = SseFrameParser();
  final frames = <String>[];
  final sink = StringConversionSink.withCallback((text) {
    frames.addAll(parser.addChunk(text));
  });
  const Utf8Decoder(allowMalformed: true).startChunkedConversion(sink)
    ..add(bytes.sublist(0, cut))
    ..add(bytes.sublist(cut))
    ..close();
  return frames;
}

void main() {
  group('single frame', () {
    test('parses one data frame', () {
      expect(parseAll(['data: hello\n\n']), ['hello']);
    });

    test('strips exactly one leading space, not all whitespace', () {
      expect(parseAll(['data:  hello\n\n']), [' hello']);
    });

    test('parses a frame with no space after the colon', () {
      expect(parseAll(['data:hello\n\n']), ['hello']);
    });

    test('an empty data value still dispatches a frame', () {
      expect(parseAll(['data:\n\n']), ['']);
    });

    test('a field name with no colon is treated as an empty value', () {
      expect(parseAll(['data\n\n']), ['']);
    });
  });

  group('multiple frames', () {
    test('parses several frames from one chunk', () {
      expect(parseAll(['data: a\n\ndata: b\n\ndata: c\n\n']), ['a', 'b', 'c']);
    });

    test('parses frames arriving one per chunk', () {
      expect(parseAll(['data: a\n\n', 'data: b\n\n']), ['a', 'b']);
    });

    test('consecutive blank lines do not dispatch empty frames', () {
      expect(parseAll(['data: a\n\n\n\ndata: b\n\n']), ['a', 'b']);
    });
  });

  group('chunk splitting', () {
    test('reassembles a frame split mid-value', () {
      expect(parseAll(['data: hel', 'lo\n\n']), ['hello']);
    });

    test('reassembles a frame split at every position mid-JSON', () {
      const frame = 'data: {"eventId":"evt_1","type":"text_delta"}\n\n';
      for (var cut = 1; cut < frame.length; cut++) {
        expect(
          parseAll([frame.substring(0, cut), frame.substring(cut)]),
          ['{"eventId":"evt_1","type":"text_delta"}'],
          reason: 'split at $cut',
        );
      }
    });

    test('reassembles a frame split between the two delimiter newlines', () {
      expect(parseAll(['data: hello\n', '\n']), ['hello']);
    });

    test('reassembles a frame split on the field name', () {
      expect(parseAll(['da', 'ta: hello\n\n']), ['hello']);
    });

    test('one character per chunk still yields the frame', () {
      expect(parseAll('data: hello\n\n'.split('')), ['hello']);
    });
  });

  group('UTF-8 across chunk boundaries', () {
    // The regression this guards: decoding each byte chunk independently
    // corrupts any multi-byte sequence straddling the boundary. The transport
    // decodes with a streaming Utf8Decoder, which buffers the partial
    // sequence — this proves the pairing works for every possible split.
    test('Arabic split mid-codepoint survives a streaming decode', () {
      final bytes = utf8.encode('data: مرحبا بك في سند\n\n');
      for (var cut = 1; cut < bytes.length; cut++) {
        expect(
          parseBytesSplitAt(bytes, cut),
          ['مرحبا بك في سند'],
          reason: 'byte split at $cut',
        );
      }
    });

    test('emoji split mid-codepoint survives a streaming decode', () {
      final bytes = utf8.encode('data: ok 🚗 done\n\n');
      for (var cut = 1; cut < bytes.length; cut++) {
        expect(
          parseBytesSplitAt(bytes, cut),
          ['ok 🚗 done'],
          reason: 'byte split at $cut',
        );
      }
    });
  });

  group('multi-line data', () {
    test('joins multiple data lines with a newline', () {
      expect(parseAll(['data: one\ndata: two\n\n']), ['one\ntwo']);
    });

    test('preserves an empty data line in the middle', () {
      expect(parseAll(['data: one\ndata:\ndata: two\n\n']), ['one\n\ntwo']);
    });

    test('joins data lines split across chunks', () {
      expect(parseAll(['data: one\nda', 'ta: two\n\n']), ['one\ntwo']);
    });
  });

  group('line endings', () {
    test('handles CRLF', () {
      expect(parseAll(['data: hello\r\n\r\n']), ['hello']);
    });

    test('handles a lone CR', () {
      expect(parseAll(['data: hello\r\r']), ['hello']);
    });

    test('handles a CRLF pair split across chunks', () {
      expect(parseAll(['data: hello\r', '\n\r\n']), ['hello']);
    });

    test('a CR ending a chunk followed by content is a plain terminator', () {
      expect(parseAll(['data: hello\r', 'data: world\r\r']), ['hello\nworld']);
    });

    test('handles mixed line endings in one stream', () {
      expect(parseAll(['data: a\r\n\r\ndata: b\n\n']), ['a', 'b']);
    });
  });

  group('ignored lines', () {
    test('ignores a comment line', () {
      expect(parseAll([': keepalive\ndata: hello\n\n']), ['hello']);
    });

    test('a comment-only frame dispatches nothing', () {
      expect(parseAll([': keepalive\n\n']), isEmpty);
    });

    test('ignores event, id and retry fields', () {
      expect(parseAll(['event: message\nid: 7\nretry: 3000\ndata: hi\n\n']), [
        'hi',
      ]);
    });

    test('ignores an unknown field', () {
      expect(parseAll(['whatever: x\ndata: hello\n\n']), ['hello']);
    });

    test('a frame with no data line dispatches nothing', () {
      expect(parseAll(['event: ping\nid: 1\n\n']), isEmpty);
    });
  });

  group('incomplete and empty input', () {
    test('an unterminated final frame is not dispatched', () {
      final parser = SseFrameParser();
      expect(parser.addChunk('data: hello\n'), isEmpty);
      expect(parser.hasIncompleteFrame, isTrue);
      expect(parser.incompleteFrameLength, 'hello'.length);
    });

    test('a partial line with no terminator is not dispatched', () {
      final parser = SseFrameParser();
      expect(parser.addChunk('data: hel'), isEmpty);
      expect(parser.hasIncompleteFrame, isTrue);
    });

    test('a fully consumed stream reports no incomplete frame', () {
      final parser = SseFrameParser();
      expect(parser.addChunk('data: hello\n\n'), ['hello']);
      expect(parser.hasIncompleteFrame, isFalse);
      expect(parser.incompleteFrameLength, 0);
    });

    test('an empty chunk yields nothing and changes no state', () {
      final parser = SseFrameParser();
      expect(parser.addChunk(''), isEmpty);
      expect(parser.hasIncompleteFrame, isFalse);
    });

    test('an empty stream yields nothing', () {
      expect(parseAll([]), isEmpty);
    });

    test('blank lines only yield nothing', () {
      final parser = SseFrameParser();
      expect(parser.addChunk('\n\n\n'), isEmpty);
      expect(parser.hasIncompleteFrame, isFalse);
    });
  });

  group('the observed server framing', () {
    // Verbatim shape captured from POST /user-agent/chat/stream: `data: ` +
    // single-line JSON, bare LF, blank-line delimited, no event/id/retry.
    test('parses a real three-frame turn', () {
      // Envelope fields are trimmed to keep each frame on one line: this
      // test is about the framing, and `parseAll` never decodes the JSON.
      const start = 'data: {"type":"message_start"}\n\n';
      const delta = 'data: {"type":"text_delta","payload":{"delta":"hi"}}\n\n';
      const end = 'data: {"type":"message_end"}\n\n';

      final frames = parseAll([start, delta, end]);
      expect(frames, hasLength(3));
      expect(frames[0], contains('"type":"message_start"'));
      expect(frames[1], contains('"delta":"hi"'));
      expect(frames[2], contains('"type":"message_end"'));
    });

    test('parses the same turn arriving in every chunk size', () {
      const wire =
          'data: {"seq":0,"type":"message_start"}\n\n'
          'data: {"seq":1,"type":"text_delta"}\n\n'
          'data: {"seq":2,"type":"message_end"}\n\n';

      for (var size = 1; size <= 16; size++) {
        final chunks = <String>[];
        for (var i = 0; i < wire.length; i += size) {
          final end = i + size > wire.length ? wire.length : i + size;
          chunks.add(wire.substring(i, end));
        }
        expect(parseAll(chunks), hasLength(3), reason: 'chunk size $size');
      }
    });
  });
}
