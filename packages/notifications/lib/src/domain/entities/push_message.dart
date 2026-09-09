import 'package:equatable/equatable.dart';
import 'package:notifications/src/domain/entities/notification_subject.dart';
import 'package:notifications/src/domain/enums/notification_subject_type.dart';
import 'package:notifications/src/domain/enums/notification_type.dart';

/// A push delivered by FCM, already stripped of every vendor type.
///
/// FCM data payloads are `Map<String, String>` on the wire, so everything —
/// including the subject and its metadata — arrives as strings and is parsed
/// here rather than in the gateway.
class PushMessage extends Equatable {
  const PushMessage({
    required this.data,
    this.notificationId,
    this.title,
    this.body,
  });

  /// Builds a message from a raw FCM data map.
  factory PushMessage.fromData(
    Map<String, dynamic> data, {
    String? title,
    String? body,
  }) => PushMessage(
    data: data.map((key, value) => MapEntry(key, value?.toString() ?? '')),
    notificationId:
        _nonEmpty(data['notificationId']?.toString()) ??
        _nonEmpty(data['id']?.toString()),
    title: title,
    body: body,
  );

  final Map<String, String> data;

  /// The stable server notification id, when the payload carries one.
  ///
  /// Without it the message cannot be deduplicated against the same event
  /// arriving in the foreground, so it is treated as always-new.
  final String? notificationId;

  final String? title;
  final String? body;

  /// The notification type, for deciding whether open screens must re-read.
  NotificationType get type => NotificationType.fromApi(data['type']);

  /// Where a tap on this push should go.
  NotificationSubject get subject {
    final type = NotificationSubjectType.fromApi(data['subjectType']);
    if (type == NotificationSubjectType.unknown) {
      return NotificationSubject.none;
    }
    return NotificationSubject(
      type: type,
      id: _nonEmpty(data['subjectId']),
      // FCM flattens nested JSON, so metadata arrives as sibling data keys
      // rather than a nested object. Only the keys routing needs are lifted.
      metadata: {
        for (final key in const ['requestId', 'offerId', 'serviceName'])
          if (_nonEmpty(data[key]) case final value?) key: value,
      },
    );
  }

  static String? _nonEmpty(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  List<Object?> get props => [data, notificationId, title, body];
}
