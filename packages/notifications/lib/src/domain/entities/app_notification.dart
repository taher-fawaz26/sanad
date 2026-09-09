import 'package:equatable/equatable.dart';
import 'package:notifications/src/domain/entities/notification_subject.dart';
import 'package:notifications/src/domain/enums/notification_type.dart';

/// One row in the notification inbox.
///
/// [title] and [body] are already localized: the backend renders them in the
/// recipient's language at write time, so they are shown verbatim and never
/// passed through `.tr()`.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.subject,
    this.readAt,
  });

  /// The stable server id. This — not a timestamp, not a locally generated
  /// value — is the deduplication key when the same event arrives through more
  /// than one channel.
  final String id;

  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;

  /// Where a tap goes. [NotificationSubject.none] for older notifications.
  final NotificationSubject subject;

  final DateTime? readAt;

  bool get isUnread => readAt == null;

  AppNotification copyWith({DateTime? readAt}) => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    createdAt: createdAt,
    subject: subject,
    readAt: readAt ?? this.readAt,
  );

  @override
  List<Object?> get props => [
    id,
    type,
    title,
    body,
    createdAt,
    subject,
    readAt,
  ];
}
