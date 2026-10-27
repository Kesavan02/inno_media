/// High-performance indexed collection providing O(1) primary key lookup
/// and secondary inverted indexes (e.g., query by authorId, tag, or status).
class IndexedCollection<K, V> {
  final K Function(V item) _keyExtractor;
  final Map<String, List<K> Function(V item)> _secondaryIndexExtractors;

  final Map<K, V> _primaryStore = {};
  final List<K> _orderIndex = [];
  final Map<String, Map<String, Set<K>>> _secondaryIndices = {};

  IndexedCollection({
    required K Function(V item) keyExtractor,
    Map<String, List<String> Function(V item)> secondaryIndexes = const {},
  })  : _keyExtractor = keyExtractor,
        _secondaryIndexExtractors = {} {
    for (final entry in secondaryIndexes.entries) {
      _secondaryIndices[entry.key] = {};
    }
  }

  /// Store or update an item, indexing primary and secondary keys in O(1).
  void put(V item) {
    final key = _keyExtractor(item);
    final exists = _primaryStore.containsKey(key);

    if (exists) {
      // Remove old secondary index entries before updating
      final old = _primaryStore[key];
      if (old != null) {
        _removeFromSecondaryIndices(key, old);
      }
    } else {
      _orderIndex.add(key);
    }

    _primaryStore[key] = item;

    // Index into secondary lookups
    for (final entry in _secondaryIndices.entries) {
      final indexName = entry.key;
      // If extractor exists
      // ignore: avoid_dynamic_calls
      final extractor = _secondaryIndexExtractors[indexName];
      if (extractor != null) {
        final secondaryKeys = extractor(item);
        for (final sKey in secondaryKeys) {
          final set = entry.value.putIfAbsent(sKey.toString(), () => <K>{});
          set.add(key);
        }
      }
    }
  }

  /// Store multiple items in bulk.
  void putAll(Iterable<V> items) {
    for (final item in items) {
      put(item);
    }
  }

  /// O(1) primary key lookup.
  V? get(K key) => _primaryStore[key];

  /// Check if key exists.
  bool contains(K key) => _primaryStore.containsKey(key);

  /// Return all items in natural insertion order.
  List<V> getAll() => _orderIndex.map((k) => _primaryStore[k]!).toList();

  /// Retrieve indexed sublist by page index and size (indexed pagination).
  List<V> getPaged({required int pageIndex, required int pageSize}) {
    final start = pageIndex * pageSize;
    if (start >= _orderIndex.length) return [];
    final end = (start + pageSize).clamp(0, _orderIndex.length);
    return _orderIndex.sublist(start, end).map((k) => _primaryStore[k]!).toList();
  }

  int get length => _primaryStore.length;

  bool get isEmpty => _primaryStore.isEmpty;

  void remove(K key) {
    final item = _primaryStore.remove(key);
    if (item != null) {
      _orderIndex.remove(key);
      _removeFromSecondaryIndices(key, item);
    }
  }

  void clear() {
    _primaryStore.clear();
    _orderIndex.clear();
    for (final subMap in _secondaryIndices.values) {
      subMap.clear();
    }
  }

  void _removeFromSecondaryIndices(K key, V item) {
    for (final subMap in _secondaryIndices.values) {
      for (final idSet in subMap.values) {
        idSet.remove(key);
      }
    }
  }
}
