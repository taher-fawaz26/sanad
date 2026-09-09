import 'package:notifications/src/domain/entities/app_notification.dart';
import 'package:notifications/src/domain/entities/notification_subject.dart';
import 'package:notifications/src/domain/enums/notification_subject_type.dart';
import 'package:notifications/src/domain/enums/notification_type.dart';

/// `NotificationResponseDto`.
///
/// `subjectType`, `subjectId` and `metadata` are the fields this API update
/// added, and all three are nullable: notifications written before deep links
/// existed carry none of them and must still parse and render.
class NotificationDto {
  const NotificationDto({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
    this.subjectType,
    this.subjectId,
    this.metadata,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) =>
      NotificationDto(
        id: json['id'] as String? ?? '',
        type: json['type'] as String?,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        createdAt: json['createdAt'] as String?,
        readAt: json['readAt'] as String?,
        subjectType: json['subjectType'] as String?,
        subjectId: json['subjectId'] as String?,
        metadata: json['metadata'] is Map
            ? Map<String, dynamic>.from(json['metadata'] as Map)
            : null,
      );

  final String id;
  final String? type;
  final String title;
  final String body;
  final String? createdAt;
  final String? readAt;
  final String? subjectType;
  final String? subjectId;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'body': body,
    'readAt': readAt,
    'subjectType': subjectType,
    'subjectId': subjectId,
    'metadata': metadata,
    'createdAt': createdAt,
  };

  AppNotification toEntity() {
    final subjectKind = NotificationSubjectType.fromApi(subjectType);
    return AppNotification(
      id: id,
      type: NotificationType.fromApi(type),
      title: title,
      body: body,
      // A row with an unparseable timestamp still belongs in the list; the
      // epoch sorts it last rather than dropping it.
      createdAt:
          DateTime.tryParse(createdAt ?? '')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      readAt: DateTime.tryParse(readAt ?? '')?.toLocal(),
      subject: subjectKind == NotificationSubjectType.unknown
          ? NotificationSubject.none
          : NotificationSubject(
              type: subjectKind,
              id: subjectId,
              metadata: metadata ?? const {},
            ),
    );
  }
}
