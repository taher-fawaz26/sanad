import 'package:flutter/foundation.dart';

class ServingAreaController<T> extends ChangeNotifier {
  ServingAreaController({List<T> initial = const []})
      : _items = List.of(initial);

  List<T> _items;

  List<T> get items => List.unmodifiable(_items);

  bool contains(T item) => _items.contains(item);

  void add(T item) {
    if (contains(item)) return;
    _items = [..._items, item];
    notifyListeners();
  }

  void remove(T item) {
    final before = _items.length;
    _items = _items.where((e) => e != item).toList(growable: false);
    if (_items.length != before) notifyListeners();
  }

  void replace(List<T> newItems) {
    _items = _deduplicated(newItems);
    notifyListeners();
  }

  void deduplicate() {
    final before = _items.length;
    _items = _deduplicated(_items);
    if (_items.length != before) notifyListeners();
  }

  List<T> _deduplicated(List<T> source) {
    final seen = <T>{};
    return source.where(seen.add).toList(growable: false);
  }
}
