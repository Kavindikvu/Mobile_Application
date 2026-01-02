import 'dart:async';

/// In-memory cache entry with TTL (Time To Live)
class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl;

  _CacheEntry({
    required this.data,
    required this.timestamp,
    required this.ttl,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;
}

/// In-memory cache manager for API responses
/// Provides fast access to frequently used data without hitting the network
class InMemoryCache {
  static final InMemoryCache _instance = InMemoryCache._internal();
  factory InMemoryCache() => _instance;
  InMemoryCache._internal();

  final Map<String, _CacheEntry<dynamic>> _cache = {};
  Timer? _cleanupTimer;

  /// Initialize cache with periodic cleanup
  void initialize() {
    // Clean up expired entries every 5 minutes
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupExpired();
    });
  }

  /// Get cached value if available and not expired
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    return entry.data as T;
  }

  /// Set cached value with TTL
  void set<T>(String key, T value, {Duration ttl = const Duration(minutes: 5)}) {
    _cache[key] = _CacheEntry<T>(
      data: value,
      timestamp: DateTime.now(),
      ttl: ttl,
    );
  }

  /// Remove specific cache entry
  void remove(String key) {
    _cache.remove(key);
  }

  /// Remove all cache entries matching pattern
  void removePattern(String pattern) {
    final regex = RegExp(pattern.replaceAll('*', '.*'));
    final keysToRemove = _cache.keys.where((key) => regex.hasMatch(key)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }

  /// Clear all cache entries
  void clear() {
    _cache.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final now = DateTime.now();
    int expired = 0;
    int valid = 0;

    for (final entry in _cache.values) {
      if (entry.isExpired) {
        expired++;
      } else {
        valid++;
      }
    }

    return {
      'total': _cache.length,
      'valid': valid,
      'expired': expired,
    };
  }

  /// Clean up expired entries
  void _cleanupExpired() {
    final keysToRemove = <String>[];
    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        keysToRemove.add(entry.key);
      }
    }
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }

  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
    _cache.clear();
  }
}

