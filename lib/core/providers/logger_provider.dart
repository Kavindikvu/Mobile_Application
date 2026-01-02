import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Logging levels for the application
enum AppLogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
  fatal,
}

/// Logger abstraction following engineering prompt guidelines
///
/// Provides a centralized logging system with:
/// - Multiple log levels (verbose, debug, info, warning, error, fatal)
/// - Conditional logging in debug vs release
/// - No print statements in production paths
/// - Structured logging support
/// - PII sanitization hooks
class AppLogger {
  AppLogger._();

  static Logger? _instance;

  /// Get the logger instance
  static Logger get _logger {
    _instance ??= Logger(
      printer: _createPrinter(),
      filter: _createFilter(),
      output: _createOutput(),
    );
    return _instance!;
  }

  /// Create printer based on environment
  static LogPrinter _createPrinter() {
    if (kDebugMode) {
      // Pretty printer for development
      return PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      );
    } else {
      // Compact printer for production
      return SimplePrinter(
        colors: false,
      );
    }
  }

  /// Create filter based on environment
  static LogFilter _createFilter() {
    if (kDebugMode) {
      // Show all logs in debug mode
      return DevelopmentFilter();
    } else {
      // Only show info, warning, error, fatal in production
      return ProductionFilter();
    }
  }

  /// Create output based on environment
  static LogOutput _createOutput() {
    if (kDebugMode) {
      // Console output for development
      return ConsoleOutput();
    } else {
      // Can add remote logging here (e.g., Firebase Crashlytics, Sentry)
      // For now, use console output but can be extended
      return ConsoleOutput();
    }
  }

  /// Log verbose message (very detailed, only in debug)
  static void verbose(
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    if (kDebugMode) {
      _logger.t(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log debug message (development debugging)
  static void debug(
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    if (kDebugMode) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log info message (general application flow)
  static void info(
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning (potentially problematic situations)
  static void warning(
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error (runtime errors, API failures)
  static void error(
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _logger.e(message, error: error, stackTrace: stackTrace);

    // In production, you can send to crash reporting here
    // Example: FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  /// Log fatal error (critical errors causing crashes)
  static void fatal(
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _logger.f(message, error: error, stackTrace: stackTrace);

    // In production, send to crash reporting
    // Example: FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
  }

  /// Sanitize sensitive data from logs
  /// Remove PII, tokens, passwords, etc.
  static String sanitize(String message) {
    // Remove email patterns
    String sanitized = message.replaceAll(
      RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
      '[EMAIL_REDACTED]',
    );

    // Remove phone patterns
    sanitized = sanitized.replaceAll(
      RegExp(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b'),
      '[PHONE_REDACTED]',
    );

    // Remove potential tokens (JWT-like strings)
    sanitized = sanitized.replaceAll(
      RegExp(r'\b[A-Za-z0-9_-]{20,}\b'),
      '[TOKEN_REDACTED]',
    );

    return sanitized;
  }

  /// Log API request with full details
  static void logApiRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    dynamic body,
  }) {
    if (kDebugMode) {
      final requestInfo = StringBuffer();
      requestInfo
          .writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      requestInfo.writeln('📤 API REQUEST');
      requestInfo
          .writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      requestInfo.writeln('Method: $method');
      requestInfo.writeln('URL: $url');

      if (queryParameters != null && queryParameters.isNotEmpty) {
        requestInfo.writeln('Query Parameters:');
        queryParameters.forEach((key, value) {
          requestInfo.writeln('  $key: $value');
        });
      }

      if (headers != null && headers.isNotEmpty) {
        requestInfo.writeln('Headers:');
        headers.forEach((key, value) {
          // Sanitize sensitive headers
          final sanitizedValue = _sanitizeHeader(key, value);
          requestInfo.writeln('  $key: $sanitizedValue');
        });
      }

      if (body != null) {
        requestInfo.writeln('Body:');
        if (body is String) {
          requestInfo.writeln('  $body');
        } else if (body is Map || body is List) {
          try {
            final encoder = JsonEncoder.withIndent('  ');
            requestInfo.writeln(encoder.convert(body));
          } catch (e) {
            requestInfo.writeln('  ${body.toString()}');
          }
        } else {
          requestInfo.writeln('  ${body.toString()}');
        }
      }
      requestInfo
          .writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      debug(requestInfo.toString());
    }
  }

  /// Log API response with full details
  static void logApiResponse({
    required int statusCode,
    required String url,
    Map<String, String>? headers,
    dynamic body,
    Duration? duration,
  }) {
    if (kDebugMode) {
      final responseInfo = StringBuffer();
      responseInfo
          .writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      responseInfo.writeln('📥 API RESPONSE');
      responseInfo
          .writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      responseInfo.writeln('Status Code: $statusCode');
      responseInfo.writeln('URL: $url');

      if (duration != null) {
        responseInfo.writeln('Duration: ${duration.inMilliseconds}ms');
      }

      if (headers != null && headers.isNotEmpty) {
        responseInfo.writeln('Response Headers:');
        headers.forEach((key, value) {
          responseInfo.writeln('  $key: $value');
        });
      }

      if (body != null) {
        responseInfo.writeln('Response Body:');
        if (body is String) {
          // Try to format as JSON if possible
          try {
            final decoded = jsonDecode(body);
            final encoder = JsonEncoder.withIndent('  ');
            responseInfo.writeln(encoder.convert(decoded));
          } catch (e) {
            // Not JSON, print as is
            responseInfo.writeln('  $body');
          }
        } else if (body is Map || body is List) {
          try {
            final encoder = JsonEncoder.withIndent('  ');
            responseInfo.writeln(encoder.convert(body));
          } catch (e) {
            responseInfo.writeln('  ${body.toString()}');
          }
        } else {
          responseInfo.writeln('  ${body.toString()}');
        }
      }
      responseInfo
          .writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (statusCode >= 200 && statusCode < 300) {
        info(responseInfo.toString());
      } else {
        warning(responseInfo.toString());
      }
    } else {
      // Production: only log summary
      if (statusCode >= 200 && statusCode < 300) {
        info('API Response: $statusCode $url', context: {
          'duration': duration?.inMilliseconds,
        });
      } else {
        warning('API Response: $statusCode $url', context: {
          'duration': duration?.inMilliseconds,
        });
      }
    }
  }

  /// Sanitize sensitive header values
  static String _sanitizeHeader(String key, String value) {
    final lowerKey = key.toLowerCase();
    if (lowerKey.contains('authorization') ||
        lowerKey.contains('token') ||
        lowerKey.contains('api-key') ||
        lowerKey.contains('secret')) {
      return '[REDACTED]';
    }
    return value;
  }

  /// Log API error
  static void logApiError({
    required String url,
    required dynamic error,
    StackTrace? stackTrace,
    int? statusCode,
  }) {
    AppLogger.error(
      'API Error: $url',
      error: error,
      stackTrace: stackTrace,
      context: {
        'statusCode': statusCode,
      },
    );
  }
}
