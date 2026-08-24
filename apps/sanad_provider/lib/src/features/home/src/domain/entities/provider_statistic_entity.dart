import 'package:equatable/equatable.dart';

/// A single dashboard statistic card — `GET service-provider/statistics`.
///
/// [icon] is opaque backend data: a Font Awesome CSS class string (e.g.
/// `"fa-solid fa-store"`). This layer never interprets it — only the
/// presentation-side icon resolver (`BackendIconResolver` in
/// `design_system`) understands Font Awesome syntax.
class ProviderStatisticEntity extends Equatable {
  const ProviderStatisticEntity({
    required this.key,
    required this.name,
    required this.value,
    this.icon,
  });

  /// Stable identifier (e.g. `branches`, `workers`, `invitations`) used to
  /// route taps — never displayed.
  final String key;

  /// Backend-localized display label.
  final String name;

  /// Font Awesome CSS class string, or `null` if the backend sent none.
  final String? icon;

  final int value;

  @override
  List<Object?> get props => [key, name, icon, value];
}
