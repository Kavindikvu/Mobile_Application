import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/logger_provider.dart';

/// Request deduplicator to prevent multiple identical API calls
/// When multiple widgets request the same data simultaneously,
/// only one actual API call is made and all requests share the result
class RequestDeduplicator {
  static final RequestDeduplicator _instance = RequestDeduplicator._internal();
  factory RequestDeduplicator() => _instance;
  RequestDeduplicator._internal();

  final Map<String, Future<dynamic>> _pendingRequests = {};

  /// Deduplicate a request by key
  /// If a request with the same key is already in progress, returns the existing future
  /// Otherwise, executes the request and caches the future
  Future<T> deduplicate<T>(
    String key,
    Future<T> Function() request, {
    bool logDeduplication = false,
  }) async {
    // Check if request is already in progress
    if (_pendingRequests.containsKey(key)) {
      if (logDeduplication) {
        AppLogger.debug(
          'Request deduplicated',
          context: {'key': key},
        );
      }
      return _pendingRequests[key] as Future<T>;
    }

    // Create new request
    final future = request().whenComplete(() {
      _pendingRequests.remove(key);
    });

    _pendingRequests[key] = future;
    return future;
  }

  /// Check if a request is currently in progress
  bool isPending(String key) => _pendingRequests.containsKey(key);

  /// Cancel a pending request (if possible)
  void cancel(String key) {
    _pendingRequests.remove(key);
  }

  /// Clear all pending requests
  void clear() {
    _pendingRequests.clear();
  }

  /// Get number of pending requests
  int get pendingCount => _pendingRequests.length;
}

/// Provider for RequestDeduplicator singleton
final requestDeduplicatorProvider = Provider<RequestDeduplicator>((ref) {
  return RequestDeduplicator();
});

