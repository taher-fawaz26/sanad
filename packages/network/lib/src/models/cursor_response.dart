/// Shared cursor-pagination response wrapper.
class CursorResponse<T> {
  const CursorResponse({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  factory CursorResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemParser,
  ) =>
      CursorResponse(
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => itemParser(e as Map<String, dynamic>))
            .toList(),
        nextCursor: json['next_cursor'] as String? ?? json['nextCursor'] as String?,
        hasMore: json['has_more'] as bool? ?? json['hasMore'] as bool? ?? false,
      );

  final List<T> items;
  final String? nextCursor;
  final bool hasMore;
}
