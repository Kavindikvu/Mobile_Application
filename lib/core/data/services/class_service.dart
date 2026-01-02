import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/api_config.dart';
import '../../providers/logger_provider.dart';
import '../api_client.dart';
import '../models/api_class_model.dart';

/// Validates that the base URL is configured before making API calls
void _validateApiConfig(String baseUrl) {
  if (baseUrl.contains('{{') || 
      baseUrl.contains('your-api-id') || 
      baseUrl.contains('your-region') ||
      baseUrl.contains('your-env') ||
      baseUrl.contains('your-qa-api-id') ||
      baseUrl.contains('your-staging-api-id') ||
      baseUrl.contains('your-production-api-id')) {
    throw ArgumentError(
      'API base URL is not properly configured. '
      'Please update lib/core/config/app_environment.dart with your actual API endpoint for the current environment. '
      'Current value: $baseUrl'
    );
  }
}

class ClassService {
  final ApiClient _client;
  final String _baseUrl;

  ClassService(this._client, this._baseUrl);

  Future<List<ApiClassModel>> getAllClasses({
    List<String>? homeVisitCities,
  }) async {
    try {
      if (homeVisitCities != null && homeVisitCities.isNotEmpty) {
        // Validate API configuration before making the request
        _validateApiConfig(_baseUrl);
        
        // Build query string manually for multiple values with same key
        // The API expects: ?homeVisitCities=city1&homeVisitCities=city2
        final cityParams = homeVisitCities.map((city) => 'homeVisitCities=${Uri.encodeComponent(city)}').join('&');
        final path = '/classes?$cityParams';
        final fullUrl = Uri.parse('$_baseUrl$path');
        
        final requestHeaders = {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        };
        
        AppLogger.logApiRequest(
          method: 'GET',
          url: fullUrl.toString(),
          queryParameters: {'homeVisitCities': homeVisitCities.join(', ')},
          headers: requestHeaders,
        );
        
        final stopwatch = Stopwatch()..start();
        final response = await _client.client.get(
          fullUrl,
          headers: requestHeaders,
        );
        stopwatch.stop();

        AppLogger.logApiResponse(
          statusCode: response.statusCode,
          url: fullUrl.toString(),
          headers: response.headers,
          body: response.body,
          duration: stopwatch.elapsed,
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return _parseClassesResponse(response.body, fullUrl.toString());
        } else {
          AppLogger.error(
            'Failed to load classes with city filter',
            error: 'HTTP ${response.statusCode}',
            context: {'url': fullUrl.toString(), 'body': response.body},
          );
          throw Exception('Failed to load classes: ${response.statusCode}');
        }
      }

      // Use ApiClient for standard list request
      // Logging is handled by ApiClient.getList()
      final response = await _client.getList('/classes');

      return _parseClassesList(response, '$_baseUrl/classes');
    } catch (e, stackTrace) {
      AppLogger.logApiError(
        url: '$_baseUrl/classes',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Parse classes response with defensive type checking
  List<ApiClassModel> _parseClassesResponse(String responseBody, String url) {
    try {
      final dynamic decoded = jsonDecode(responseBody);
      
      if (decoded is! List) {
        AppLogger.error(
          'Invalid API response format: expected List, got ${decoded.runtimeType}',
          context: {'url': url, 'response': responseBody},
        );
        throw FormatException(
          'Expected List from classes API, but received ${decoded.runtimeType}',
        );
      }
      
      return _parseClassesList(decoded, url);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to parse classes response',
        error: e,
        stackTrace: stackTrace,
        context: {'url': url, 'response': responseBody},
      );
      rethrow;
    }
  }
  
  /// Parse classes list with type checking
  List<ApiClassModel> _parseClassesList(List<dynamic> jsonList, String url) {
    final List<ApiClassModel> classes = [];
    
    for (int i = 0; i < jsonList.length; i++) {
      final item = jsonList[i];
      
      if (item is! Map<String, dynamic>) {
        AppLogger.warning(
          'Invalid item type in classes list at index $i: expected Map, got ${item.runtimeType}',
          context: {
            'url': url,
            'index': i,
            'item': item.toString(),
          },
        );
        continue; // Skip invalid items instead of crashing
      }
      
      try {
        classes.add(ApiClassModel.fromJson(item));
      } catch (e, stackTrace) {
        AppLogger.error(
          'Failed to parse class at index $i',
          error: e,
          stackTrace: stackTrace,
          context: {
            'url': url,
            'index': i,
            'item': item.toString(),
          },
        );
        // Continue processing other items
      }
    }
    
    AppLogger.debug('Parsed ${classes.length} classes from ${jsonList.length} items');
    return classes;
  }

  Future<ApiClassModel> getClassById(String classId) async {
    try {
      // Logging is handled by ApiClient.get()
      final response = await _client.get('/classes/$classId');
      return ApiClassModel.fromJson(response);
    } catch (e, stackTrace) {
      AppLogger.logApiError(
        url: '$_baseUrl/classes/$classId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<ApiClassModel>> getClassesByTeacher(String teacherId) async {
    try {
      // Logging is handled by ApiClient.getList()
      final response = await _client.getList('/classes/teacher/$teacherId');
      return _parseClassesList(response, '$_baseUrl/classes/teacher/$teacherId');
    } catch (e, stackTrace) {
      AppLogger.logApiError(
        url: '$_baseUrl/classes/teacher/$teacherId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

final classServiceProvider = Provider<ClassService>((ref) {
  final apiClient = ref.watch(apiClientProvider(ApiConfig.classServiceBaseUrl));
  return ClassService(apiClient, ApiConfig.classServiceBaseUrl);
});

