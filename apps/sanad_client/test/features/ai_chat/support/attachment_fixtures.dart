import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_attachment.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_uploaded_attachment.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_attachment_status.dart';

/// Builders for attachment fixtures, so a test names only what it is about.
///
/// Every field has a sane default; a test overrides the one thing under
/// examination and the rest stays out of the way.
AiImageAttachment imageFixture({
  String id = 'att_img_1',
  String fileName = 'photo.jpg',
  int sizeBytes = 1024,
  String mimeType = 'image/jpeg',
  String localPath = '/tmp/photo.jpg',
  AiAttachmentStatus status = AiAttachmentStatus.picked,
  String? failureKey,
}) => AiImageAttachment(
  id: id,
  fileName: fileName,
  sizeBytes: sizeBytes,
  mimeType: mimeType,
  localPath: localPath,
  status: status,
  failureKey: failureKey,
);

AiDocumentAttachment documentFixture({
  String id = 'att_doc_1',
  String fileName = 'report.pdf',
  int sizeBytes = 2048,
  String mimeType = 'application/pdf',
  String localPath = '/tmp/report.pdf',
  String extension = 'pdf',
  AiAttachmentStatus status = AiAttachmentStatus.picked,
  String? failureKey,
}) => AiDocumentAttachment(
  id: id,
  fileName: fileName,
  sizeBytes: sizeBytes,
  mimeType: mimeType,
  localPath: localPath,
  extension: extension,
  status: status,
  failureKey: failureKey,
);

AiAudioAttachment audioFixture({
  String id = 'att_aud_1',
  String fileName = 'voice.m4a',
  int sizeBytes = 4096,
  String mimeType = 'audio/mp4',
  String localPath = '/tmp/voice.m4a',
  Duration duration = const Duration(seconds: 12),
  AiAttachmentStatus status = AiAttachmentStatus.picked,
  String? failureKey,
  List<double> waveform = const [0.1, 0.5, 0.9],
  String transcript = '',
}) => AiAudioAttachment(
  id: id,
  fileName: fileName,
  sizeBytes: sizeBytes,
  mimeType: mimeType,
  localPath: localPath,
  duration: duration,
  status: status,
  failureKey: failureKey,
  waveform: waveform,
  transcript: transcript,
);

/// An attachment that has already been uploaded, as the send path sees it.
AiUploadedAttachment uploadedFixture({
  AiChatAttachment? source,
  String mediaId = 'upl_1',
  String url = 'https://cdn.invalid/upl_1',
}) => AiUploadedAttachment(
  source: source ?? imageFixture(),
  mediaId: mediaId,
  url: url,
);
