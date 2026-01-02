# Logging Best Practices - Skillora Family Mobile

This document outlines the logging system and best practices for the Skillora Family mobile application, following industry-grade production-ready standards.

## Overview

The application uses a centralized logging system (`AppLogger`) located in `lib/core/providers/logger_provider.dart`. This system follows the engineering prompt guidelines and provides:

- **Multiple log levels** (verbose, debug, info, warning, error, fatal)
- **Conditional logging** in debug vs release builds
- **No print statements** in production paths
- **Structured logging** with context support
- **PII sanitization** hooks
- **API request/response logging** helpers

## Logging Levels

### Verbose
Very detailed information, typically only for debugging specific issues.

```dart
AppLogger.verbose('Detailed method call', context: {'param': value});
```

**Usage:** Only in debug mode, for very detailed debugging.

### Debug
Information useful for debugging during development.

```dart
AppLogger.debug('User clicked button', context: {'buttonId': 'submit'});
```

**Usage:** Development debugging, automatically disabled in production.

### Info
General application flow, significant events.

```dart
AppLogger.info('User logged in successfully', context: {'userId': userId});
```

**Usage:** Important events like user actions, API success, navigation.

### Warning
Potentially problematic situations that don't stop the application.

```dart
AppLogger.warning('API returned unexpected format', context: {'url': url});
```

**Usage:** Deprecated API usage, unexpected data formats, recoverable errors.

### Error
Runtime errors or unexpected conditions that prevent operations.

```dart
AppLogger.error('Failed to load classes', error: exception, stackTrace: stackTrace);
```

**Usage:** API failures, file I/O errors, parsing errors.

### Fatal
Critical errors that cause the application to crash or become unusable.

```dart
AppLogger.fatal('Critical system error', error: exception, stackTrace: stackTrace);
```

**Usage:** Unrecoverable errors, system failures.

## Usage Examples

### Basic Logging

```dart
// Info level
AppLogger.info('User navigated to Discovery screen');

// Error with context
AppLogger.error(
  'Failed to fetch classes',
  error: exception,
  stackTrace: stackTrace,
  context: {
    'userId': userId,
    'endpoint': '/classes',
  },
);
```

### API Request/Response Logging

The logger provides specialized methods for API logging:

```dart
// Log API request
AppLogger.logApiRequest(
  method: 'GET',
  url: 'https://api.example.com/classes',
  headers: headers,
);

// Log API response
AppLogger.logApiResponse(
  statusCode: 200,
  url: 'https://api.example.com/classes',
  duration: Duration(milliseconds: 150),
);

// Log API error
AppLogger.logApiError(
  url: 'https://api.example.com/classes',
  error: exception,
  stackTrace: stackTrace,
  statusCode: 500,
);
```

### PII Sanitization

Always sanitize sensitive data before logging:

```dart
String userEmail = 'user@example.com';
String sanitizedMessage = AppLogger.sanitize('User email: $userEmail');
AppLogger.info(sanitizedMessage); // Will replace email with [EMAIL_REDACTED]
```

The `sanitize` method automatically removes:
- Email addresses → `[EMAIL_REDACTED]`
- Phone numbers → `[PHONE_REDACTED]`
- Potential tokens → `[TOKEN_REDACTED]`

## Environment-Specific Behavior

### Debug Mode (`kDebugMode`)
- All log levels are shown
- Pretty printer with colors and emojis
- Console output
- Detailed stack traces

### Production Mode (Release)
- Only `info`, `warning`, `error`, and `fatal` are shown
- Compact printer format
- Can be extended to send to remote logging services
- Stack traces included for errors

## Best Practices

### 1. Use Appropriate Log Levels

```dart
// ✅ Good
AppLogger.info('User logged in');
AppLogger.error('Failed to save data', error: e, stackTrace: stackTrace);

// ❌ Bad
AppLogger.error('User clicked button'); // Should be debug or info
AppLogger.info('Critical error occurred'); // Should be error or fatal
```

### 2. Always Include Context

```dart
// ✅ Good
AppLogger.error(
  'Failed to load classes',
  error: exception,
  stackTrace: stackTrace,
  context: {
    'userId': userId,
    'endpoint': url,
    'retryCount': retryCount,
  },
);

// ❌ Bad
AppLogger.error('Failed to load classes'); // Missing context
```

### 3. Never Log Sensitive Data

```dart
// ✅ Good
AppLogger.info('User logged in', context: {'userId': userId});

// ❌ Bad
AppLogger.info('User logged in', context: {
  'password': password, // Never log passwords!
  'token': authToken, // Never log tokens!
});
```

### 4. Use Structured Context

```dart
// ✅ Good - structured context
AppLogger.warning(
  'API response format changed',
  context: {
    'endpoint': '/classes',
    'expectedFormat': 'List',
    'receivedFormat': responseType,
  },
);
```

### 5. Log at Appropriate Points

```dart
// ✅ Good - log before and after operations
AppLogger.info('Starting data sync');
try {
  await syncData();
  AppLogger.info('Data sync completed successfully');
} catch (e, stackTrace) {
  AppLogger.error('Data sync failed', error: e, stackTrace: stackTrace);
}
```

## Integration with Crash Reporting

The logger is designed to integrate with crash reporting services. In production, you can extend the logger to send critical errors to services like:

- **Firebase Crashlytics**
- **Sentry**
- **Datadog**
- **Custom logging service**

Example integration point:

```dart
// In logger_provider.dart, error method
static void error(...) {
  _logger.e(message, error: error, stackTrace: stackTrace);
  
  // Production: Send to crash reporting
  if (!kDebugMode) {
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
    // Sentry.captureException(error, stackTrace: stackTrace);
  }
}
```

## Performance Considerations

1. **Debug logs are disabled in production** - Only shown when `kDebugMode` is true
2. **Context is evaluated lazily** - Pass context as Map, not as expensive computations
3. **Async logging** - For remote logging, ensure it's done asynchronously

## Common Patterns

### Repository Pattern

```dart
class ClassRepository {
  Future<List<Class>> getClasses() async {
    AppLogger.debug('Fetching classes');
    try {
      final classes = await _apiClient.getClasses();
      AppLogger.info('Successfully fetched ${classes.length} classes');
      return classes;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch classes', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
```

### API Client Pattern

```dart
Future<Response> get(String endpoint) async {
  AppLogger.logApiRequest(method: 'GET', url: endpoint);
  final stopwatch = Stopwatch()..start();
  
  try {
    final response = await http.get(uri);
    stopwatch.stop();
    
    AppLogger.logApiResponse(
      statusCode: response.statusCode,
      url: endpoint,
      duration: stopwatch.elapsed,
    );
    
    return response;
  } catch (e, stackTrace) {
    AppLogger.logApiError(url: endpoint, error: e, stackTrace: stackTrace);
    rethrow;
  }
}
```

## Migration from Print Statements

Replace all `print()` statements with appropriate logger calls:

```dart
// ❌ Old
print('Error: $error');

// ✅ New
AppLogger.error('Operation failed', error: error);
```

## Testing

In tests, you can verify logging behavior:

```dart
test('should log error on API failure', () async {
  // Test implementation
  // Verify that AppLogger.error was called with correct parameters
});
```

## Future Enhancements

- [ ] Remote logging integration (Firebase, Sentry)
- [ ] Log file persistence for debugging
- [ ] Log rotation and cleanup
- [ ] Performance metrics logging
- [ ] User action analytics
- [ ] Custom log formatters per environment

## References

- [Engineering Prompt - Logging Section](../../SKILLORA_FAMILY_PROMPT.md)
- [Logger Package Documentation](https://pub.dev/packages/logger)
- [Flutter Foundation - kDebugMode](https://api.flutter.dev/flutter/foundation/kDebugMode-constant.html)

