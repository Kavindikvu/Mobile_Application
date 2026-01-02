import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/api_config.dart';
import '../api_client.dart';
import '../../providers/logger_provider.dart';
import '../../domain/attendance_model.dart';

class AttendanceService {
  final ApiClient _client;
  final String _baseUrl;

  AttendanceService(this._client, this._baseUrl);

  /// Get attendance records for a specific student
  Future<List<Attendance>> getAttendanceByStudent({
    required String studentId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (fromDate != null) {
        queryParams['fromDate'] = fromDate.toIso8601String();
      }
      if (toDate != null) {
        queryParams['toDate'] = toDate.toIso8601String();
      }

      final response = await _client.getList(
        '/attendance/student/$studentId',
        queryParameters: queryParams,
      );

      // Handle the response structure from API
      List<dynamic> attendanceList;
      if (response.isNotEmpty && response.first is Map) {
        final firstItem = response.first as Map<String, dynamic>;
        if (firstItem.containsKey('attendances')) {
          // Response has { attendances: [...], success: true, totalCount: ... }
          attendanceList = firstItem['attendances'] as List<dynamic>;
        } else {
          attendanceList = response;
        }
      } else {
        attendanceList = response;
      }

      return attendanceList
          .map((json) => Attendance.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.logApiError(
        url: '$_baseUrl/attendance/student/$studentId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get attendance summary for a student (calculated from records)
  Future<AttendanceSummary> getAttendanceSummary({
    required String studentId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final attendances = await getAttendanceByStudent(
      studentId: studentId,
      fromDate: fromDate,
      toDate: toDate,
    );
    return AttendanceSummary.fromAttendanceList(attendances);
  }
}

final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  final apiClient = ref.watch(apiClientProvider(ApiConfig.baseUrl));
  // Attendance service uses base URL with /attendance-service path
  final baseUrl = '${ApiConfig.baseUrl}/attendance-service';
  return AttendanceService(apiClient, baseUrl);
});

