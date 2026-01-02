import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/domain/student_profile.dart';
import '../../../core/domain/attendance_model.dart';
import '../../../core/domain/enrollment_model.dart';
import '../../../core/data/services/student_service.dart';
import '../../../core/data/services/attendance_service.dart';
import '../../../core/data/services/enrollment_service.dart';
import '../../../core/providers/logger_provider.dart';

class StudentActivityState {
  final StudentProfile? student;
  final List<Attendance> recentAttendance;
  final AttendanceSummary? attendanceSummary;
  final List<Enrollment> enrollments;
  final bool isLoading;
  final String? error;

  const StudentActivityState({
    this.student,
    this.recentAttendance = const [],
    this.attendanceSummary,
    this.enrollments = const [],
    this.isLoading = false,
    this.error,
  });

  StudentActivityState copyWith({
    StudentProfile? student,
    List<Attendance>? recentAttendance,
    AttendanceSummary? attendanceSummary,
    List<Enrollment>? enrollments,
    bool? isLoading,
    String? error,
  }) {
    return StudentActivityState(
      student: student ?? this.student,
      recentAttendance: recentAttendance ?? this.recentAttendance,
      attendanceSummary: attendanceSummary ?? this.attendanceSummary,
      enrollments: enrollments ?? this.enrollments,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class StudentActivityController extends StateNotifier<StudentActivityState> {
  StudentActivityController(this._ref, this._studentId)
      : super(const StudentActivityState()) {
    _loadData();
  }

  final Ref _ref;
  final String _studentId;

  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {

      // Load all data in parallel
      final results = await Future.wait([
        _loadStudent(_studentId),
        _loadAttendance(_studentId),
        _loadEnrollments(_studentId),
      ]);

      final student = results[0] as StudentProfile;
      final attendances = results[1] as List<Attendance>;
      final enrollments = results[2] as List<Enrollment>;

      // Get recent attendance (last 7 records)
      final recentAttendance = attendances.take(7).toList();

      // Calculate summary
      final attendanceSummary = AttendanceSummary.fromAttendanceList(attendances);

      state = state.copyWith(
        student: student,
        recentAttendance: recentAttendance,
        attendanceSummary: attendanceSummary,
        enrollments: enrollments,
        isLoading: false,
        error: null,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to load student activity',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<StudentProfile> _loadStudent(String studentId) async {
    final studentService = _ref.read(studentServiceProvider);
    return await studentService.getStudentById(studentId);
  }

  Future<List<Attendance>> _loadAttendance(String studentId) async {
    final attendanceService = _ref.read(attendanceServiceProvider);
    // Get attendance for the last 3 months
    final toDate = DateTime.now();
    final fromDate = DateTime(toDate.year, toDate.month - 3, toDate.day);
    return await attendanceService.getAttendanceByStudent(
      studentId: studentId,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  Future<List<Enrollment>> _loadEnrollments(String studentId) async {
    final enrollmentService = _ref.read(enrollmentServiceProvider);
    // Get only approved enrollments
    return await enrollmentService.getEnrollmentsByStudent(
      studentId: studentId,
      status: EnrollmentStatus.approved,
    );
  }

  Future<void> refresh() async {
    await _loadData();
  }
}

final studentActivityControllerProvider = StateNotifierProvider.family<
    StudentActivityController, StudentActivityState, String>((ref, studentId) {
  return StudentActivityController(ref, studentId);
});

