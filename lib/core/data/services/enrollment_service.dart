import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/api_config.dart';
import '../api_client.dart';
import '../../providers/logger_provider.dart';
import '../../domain/enrollment_model.dart';

class EnrollmentService {
  final ApiClient _client;
  final String _baseUrl;
  final http.Client _httpClient;

  EnrollmentService(this._client, this._baseUrl, {http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Enroll a student in a class with optional subject selection
  /// Creates one enrollment per subject
  /// Returns a list of created enrollments
  Future<List<Enrollment>> enrollInClass({
    required String classId,
    required String studentId,
    required List<String> subjectIds,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/enrollments/classes/$classId/enrollments');
      
      final requestBody = {
        'studentId': studentId,
        'subjectIds': subjectIds,
      };

      final requestHeaders = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      AppLogger.logApiRequest(
        method: 'POST',
        url: uri.toString(),
        headers: requestHeaders,
        body: requestBody,
      );

      final stopwatch = Stopwatch()..start();
      final response = await _httpClient.post(
        uri,
        headers: requestHeaders,
        body: jsonEncode(requestBody),
      );
      stopwatch.stop();

      AppLogger.logApiResponse(
        statusCode: response.statusCode,
        url: uri.toString(),
        headers: response.headers,
        body: response.body,
        duration: stopwatch.elapsed,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return [];
        }

        try {
          final decoded = jsonDecode(response.body);
          if (decoded is List) {
            return decoded
                .map((json) => Enrollment.fromJson(json as Map<String, dynamic>))
                .toList();
          } else {
            AppLogger.error(
              'API returned non-list response for enrollment',
              context: {
                'statusCode': response.statusCode,
                'body': response.body,
                'type': decoded.runtimeType.toString(),
              },
            );
            throw Exception('Expected List but received ${decoded.runtimeType}');
          }
        } catch (e, stackTrace) {
          AppLogger.error(
            'Failed to parse enrollment response',
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
          url: uri.toString(),
          error: 'HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
        
        String errorMessage = 'Failed to enroll in class';
        if (response.body.isNotEmpty) {
          try {
            final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
            errorMessage = errorJson['message'] as String? ?? errorMessage;
          } catch (_) {
            // If parsing fails, use default message
          }
        }
        
        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      AppLogger.logApiError(
        url: '$_baseUrl/enrollments/classes/$classId/enrollments',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get enrollments for a specific student
  Future<List<Enrollment>> getEnrollmentsByStudent({
    required String studentId,
    EnrollmentStatus? status,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) {
        queryParams['status'] = status.toApiString();
      }

      final uri = Uri.parse('$_baseUrl/enrollments/students/$studentId/enrollments')
          .replace(queryParameters: queryParams);

      final response = await _client.getList(
        '/enrollments/students/$studentId/enrollments',
        queryParameters: queryParams,
      );

      return response
          .map((json) => Enrollment.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.logApiError(
        url: '$_baseUrl/enrollments/students/$studentId/enrollments',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get enrollments for a specific class
  Future<List<Enrollment>> getEnrollmentsByClass({
    required String classId,
    String? subjectId,
    EnrollmentStatus? status,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (subjectId != null) {
        queryParams['subjectId'] = subjectId;
      }
      if (status != null) {
        queryParams['status'] = status.toApiString();
      }

      final response = await _client.getList(
        '/enrollments/classes/$classId/enrollments',
        queryParameters: queryParams,
      );

      return response
          .map((json) => Enrollment.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.logApiError(
        url: '$_baseUrl/enrollments/classes/$classId/enrollments',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get a specific enrollment by ID
  Future<Enrollment> getEnrollmentById(String enrollmentId) async {
    try {
      final response = await _client.get('/enrollments/$enrollmentId');
      return Enrollment.fromJson(response);
    } catch (e, stackTrace) {
      AppLogger.logApiError(
        url: '$_baseUrl/enrollments/$enrollmentId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update enrollment status (approve, reject, or cancel)
  Future<Enrollment> updateEnrollmentStatus({
    required String enrollmentId,
    required EnrollmentStatus status,
    String? reason,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'status': status.toApiString(),
      };
      if (reason != null && reason.isNotEmpty) {
        requestBody['reason'] = reason;
      }

      final response = await _client.patch(
        '/enrollments/$enrollmentId',
        body: requestBody,
      );

      return Enrollment.fromJson(response);
    } catch (e, stackTrace) {
      AppLogger.logApiError(
        url: '$_baseUrl/enrollments/$enrollmentId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

final enrollmentServiceProvider = Provider<EnrollmentService>((ref) {
  final apiClient = ref.watch(apiClientProvider(ApiConfig.enrollmentServiceBaseUrl));
  return EnrollmentService(apiClient, ApiConfig.enrollmentServiceBaseUrl);
});

