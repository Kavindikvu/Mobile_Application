import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/logger_provider.dart';
import '../services/app_toast.dart';

class ApiClient {
  final String baseUrl;
  final http.Client _httpClient;

  ApiClient({
    required this.baseUrl,
    http.Client? client,
  }) : _httpClient = client ?? http.Client();

  /// Validates the base URL before making a request
  void _validateBaseUrl() {
    if (baseUrl.contains('{{') ||
        baseUrl.contains('your-api-id') ||
        baseUrl.contains('your-region') ||
        baseUrl.contains('your-env') ||
        baseUrl.contains('your-qa-api-id') ||
        baseUrl.contains('your-staging-api-id') ||
        baseUrl.contains('your-production-api-id')) {
      throw ArgumentError('API base URL is not properly configured. '
          'Please update lib/core/config/app_environment.dart with your actual API endpoint for the current environment. '
          'Current value: $baseUrl');
    }
  }

  http.Client get client => _httpClient;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    _validateBaseUrl();
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters,
    );

    final requestHeaders = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      ...?headers,
    };

    AppLogger.logApiRequest(
      method: 'GET',
      url: uri.toString(),
      queryParameters: queryParameters,
      headers: requestHeaders,
    );

    final stopwatch = Stopwatch()..start();
    final response = await _httpClient.get(
      uri,
      headers: requestHeaders,
    );
    stopwatch.stop();

    AppLogger.logApiResponse(
      statusCode: response.statusCode,
      url: uri.toString(),
      headers: response.headers,
      body: response.body,
      duration: stopwatch.elapsed,
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    _validateBaseUrl();
    final uri = Uri.parse('$baseUrl$path');

    final requestHeaders = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      ...?headers,
    };

    final requestBody = body != null ? jsonEncode(body) : null;

    AppLogger.logApiRequest(
      method: 'POST',
      url: uri.toString(),
      headers: requestHeaders,
      body: body,
    );

    final stopwatch = Stopwatch()..start();
    final response = await _httpClient.post(
      uri,
      headers: requestHeaders,
      body: requestBody,
    );
    stopwatch.stop();

    AppLogger.logApiResponse(
      statusCode: response.statusCode,
      url: uri.toString(),
      headers: response.headers,
      body: response.body,
      duration: stopwatch.elapsed,
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    _validateBaseUrl();
    final uri = Uri.parse('$baseUrl$path');

    final requestHeaders = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      ...?headers,
    };

    final requestBody = body != null ? jsonEncode(body) : null;

    AppLogger.logApiRequest(
      method: 'PUT',
      url: uri.toString(),
      headers: requestHeaders,
      body: body,
    );

    final stopwatch = Stopwatch()..start();
    final response = await _httpClient.put(
      uri,
      headers: requestHeaders,
      body: requestBody,
    );
    stopwatch.stop();

    AppLogger.logApiResponse(
      statusCode: response.statusCode,
      url: uri.toString(),
      headers: response.headers,
      body: response.body,
      duration: stopwatch.elapsed,
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    _validateBaseUrl();
    final uri = Uri.parse('$baseUrl$path');

    final requestHeaders = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      ...?headers,
    };

    final requestBody = body != null ? jsonEncode(body) : null;

    AppLogger.logApiRequest(
      method: 'PATCH',
      url: uri.toString(),
      headers: requestHeaders,
      body: body,
    );

    final stopwatch = Stopwatch()..start();
    final response = await _httpClient.patch(
      uri,
      headers: requestHeaders,
      body: requestBody,
    );
    stopwatch.stop();

    AppLogger.logApiResponse(
      statusCode: response.statusCode,
      url: uri.toString(),
      headers: response.headers,
      body: response.body,
      duration: stopwatch.elapsed,
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    _validateBaseUrl();
    final uri = Uri.parse('$baseUrl$path');

    final requestHeaders = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      ...?headers,
    };

    AppLogger.logApiRequest(
      method: 'DELETE',
      url: uri.toString(),
      headers: requestHeaders,
    );

    final stopwatch = Stopwatch()..start();
    final response = await _httpClient.delete(
      uri,
      headers: requestHeaders,
    );
    stopwatch.stop();

    AppLogger.logApiResponse(
      statusCode: response.statusCode,
      url: uri.toString(),
      headers: response.headers,
      body: response.body,
      duration: stopwatch.elapsed,
    );

    return _handleResponse(response);
  }

  Future<List<dynamic>> getList(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    _validateBaseUrl();
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters,
    );

    final requestHeaders = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      ...?headers,
    };

    AppLogger.logApiRequest(
      method: 'GET',
      url: uri.toString(),
      queryParameters: queryParameters,
      headers: requestHeaders,
    );

    final stopwatch = Stopwatch()..start();
    final response = await _httpClient.get(
      uri,
      headers: requestHeaders,
    );
    stopwatch.stop();

    AppLogger.logApiResponse(
      statusCode: response.statusCode,
      url: uri.toString(),
      headers: response.headers,
      body: response.body,
      duration: stopwatch.elapsed,
    );

    return _handleListResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final message = response.body.isNotEmpty
          ? jsonDecode(response.body)['message'] as String? ?? 'Request failed'
          : 'Request failed';
      
      // Don't show error toasts for 404s - they're often expected (e.g., missing resources)
      // Repositories will handle them gracefully
      if (response.statusCode != 404) {
        AppToast.showApiError(
          statusCode: response.statusCode,
          message: message,
        );
      }
      
      throw ApiException(
        statusCode: response.statusCode,
        message: message,
      );
    }
  }

  List<dynamic> _handleListResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return [];
      }

      try {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded;
        } else {
          AppLogger.error(
            'API returned non-list response',
            context: {
              'statusCode': response.statusCode,
              'body': response.body,
              'type': decoded.runtimeType.toString(),
            },
          );
          AppToast.showApiError(
            statusCode: response.statusCode,
            message: 'Unexpected response format from the server.',
          );
          throw ApiException(
            statusCode: response.statusCode,
            message: 'Expected List but received ${decoded.runtimeType}',
          );
        }
      } catch (e, stackTrace) {
        AppLogger.error(
          'Failed to parse list response',
          error: e,
          stackTrace: stackTrace,
          context: {
            'statusCode': response.statusCode,
            'body': response.body,
          },
        );
        rethrow;
      }
    } else {
      AppLogger.logApiError(
        url: response.request?.url.toString() ?? 'unknown',
        error: 'HTTP ${response.statusCode}',
        statusCode: response.statusCode,
      );
      final message = response.body.isNotEmpty
          ? jsonDecode(response.body)['message'] as String? ?? 'Request failed'
          : 'Request failed';
      AppToast.showApiError(
        statusCode: response.statusCode,
        message: message,
      );
      throw ApiException(
        statusCode: response.statusCode,
        message: message,
      );
    }
  }

  void dispose() {
    _httpClient.close();
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message)';
}

final apiClientProvider = Provider.family<ApiClient, String>((ref, baseUrl) {
  return ApiClient(baseUrl: baseUrl);
});
