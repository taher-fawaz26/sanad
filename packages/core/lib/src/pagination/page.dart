import 'package:core/src/pagination/page_meta.dart';
import 'package:equatable/equatable.dart';

/// A generic page of items plus pagination metadata. Knows nothing about
/// any specific feature (worker, service, branch, ...) — the item type is
/// supplied by the caller.
class Page<T> extends Equatable {
  const Page({required this.items, required this.meta});

  const Page.empty() : items = const [], meta = const PageMeta.empty();

  final List<T> items;
  final PageMeta meta;

  bool get hasMore => meta.hasMore;

  /// Maps item type while preserving pagination metadata — used to convert
  /// a `Page<Dto>` into a `Page<Entity>` in the repository layer.
  Page<R> mapItems<R>(R Function(T item) convert) =>
      Page<R>(items: items.map(convert).toList(), meta: meta);

  @override
  List<Object?> get props => [items, meta];
}
