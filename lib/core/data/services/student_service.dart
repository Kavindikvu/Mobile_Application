import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/api_config.dart';
import '../api_client.dart';
import '../../providers/logger_provider.dart';
import '../../domain/student_profile.dart';

class StudentService {
  final ApiClient _client;
  final String _baseUrl;

  StudentService(this._client, this._baseUrl);

  /// Get student details by ID
  Future<StudentProfile> getStudentById(String studentId) async {
    try {
      final response = await _client.get('/students/$studentId');
      return StudentProfile.fromJson(response);
    } catch (e, stackTrace) {
      AppLogger.logApiError(
        url: '$_baseUrl/students/$studentId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get all students by parent ID
  Future<List<StudentProfile>> getStudentsByParentId(String parentId) async {
    try {
      final response = await _client.getList('/students/parent/$parentId');
      return response
          .map((json) => StudentProfile.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.logApiError(
        url: '$_baseUrl/students/parent/$parentId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get all students by parent ID (alias for getStudentsByParentId)
  Future<List<StudentProfile>> getStudentsByParent(String parentId) async {
    return getStudentsByParentId(parentId);
  }

  /// Create a new student profile
  Future<StudentProfile> createStudent({
    required String name,
    required int grade,
    required String medium,
    required String parentId,
    String? address,
    List<String>? cities,
    String? parentContact,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'name': name,
        'grade': grade,
        'medium': medium,
        'parentId': parentId,
        if (address != null && address.isNotEmpty) 'address': address,
        if (cities != null && cities.isNotEmpty) 'cities': cities,
        if (parentContact != null && parentContact.isNotEmpty)
          'parentContact': parentContact,
      };

      final response = await _client.post(
        '/students',
        body: requestBody,
      );

      return StudentProfile.fromJson(response);
    } catch (e, stackTrace) {
      AppLogger.logApiError(
        url: '$_baseUrl/students',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete a student by ID
  Future<void> deleteStudent(String studentId) async {
    try {
      await _client.delete('/students/$studentId');
    } catch (e, stackTrace) {
      AppLogger.logApiError(
        url: '$_baseUrl/students/$studentId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

final studentServiceProvider = Provider<StudentService>((ref) {
  final apiClient = ref.watch(apiClientProvider(ApiConfig.studentServiceBaseUrl));
  return StudentService(apiClient, ApiConfig.studentServiceBaseUrl);
});
