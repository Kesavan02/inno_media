import 'dart:async';
import '../errors/exceptions.dart';

/// Sliding-window & Token-bucket rate limiter for controlling data flow rates.
/// Prevents spamming like/comment actions, repeated rapid form submissions,
/// and API request flooding.
class RateLimiter {
  final int maxRequests;
  final Duration window;
  final Map<String, List<DateTime>> _requestTimestamps = {};

  RateLimiter({
    this.maxRequests = 5,
    this.window = const Duration(seconds: 3),
  });

  /// Check whether an action key is currently allowed under the rate limit.
  bool isAllowed(String key) {
    final now = DateTime.now();
    _cleanExpired(key, now);

    final timestamps = _requestTimestamps.putIfAbsent(key, () => []);
    return timestamps.length < maxRequests;
  }

  /// Attempts to consume 1 rate-limit token for [key].
  /// Throws [RateLimitException] if rate limit is exceeded.
  void acquire(String key) {
    final now = DateTime.now();
    _cleanExpired(key, now);

    final timestamps = _requestTimestamps.putIfAbsent(key, () => []);
    if (timestamps.length >= maxRequests) {
      final oldest = timestamps.first;
      final retryAfter = window - now.difference(oldest);
      throw RateLimitException(
        'Rate limit reached for "$key". Please wait ${retryAfter.inSeconds + 1}s.',
        retryAfter,
      );
    }
    timestamps.add(now);
  }

  /// Tries to execute [action] if allowed, otherwise throws [RateLimitException].
  Future<T> runGuarded<T>(String key, Future<T> Function() action) async {
    acquire(key);
    return await action();
  }

  /// Reset history for [key] or all if [key] is null.
  void reset([String? key]) {
    if (key != null) {
      _requestTimestamps.remove(key);
    } else {
      _requestTimestamps.clear();
    }
  }

  void _cleanExpired(String key, DateTime now) {
    final timestamps = _requestTimestamps[key];
    if (timestamps == null) return;
    final cutoff = now.subtract(window);
    timestamps.removeWhere((timestamp) => timestamp.isBefore(cutoff));
  }
}
