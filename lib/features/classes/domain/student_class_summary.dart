import '../../../core/domain/class_model.dart';
import '../../../core/domain/enrollment_model.dart';

/// Lightweight projection of a student's relationship with a class.
///
/// Designed for the My Classes overview list where we need to show
/// teacher details, schedule, assignment signals, and enrollment health
/// without fetching every related record repeatedly.
class StudentClassSummary {
  const StudentClassSummary({
    required this.enrollmentId,
    required this.classId,
    required this.className,
    required this.studentId,
    required this.studentName,
    required this.teacherName,
    required this.subjects,
    required this.schedule,
    required this.startDate,
    required this.endDate,
    required this.approvedEnrollmentCount,
    required this.capacity,
    required this.pendingAssignments,
    required this.totalAssignments,
    required this.enrollmentStatus,
    required this.classType,
    this.heroImageUrl,
    this.location,
    this.nextSession,
  });

  final String enrollmentId;
  final String classId;
  final String className;
  final String studentId;
  final String studentName;
  final String teacherName;
  final List<String> subjects;
  final List<String> schedule;
  final DateTime startDate;
  final DateTime endDate;
  final int approvedEnrollmentCount;
  final int capacity;
  final int pendingAssignments;
  final int totalAssignments;
  final EnrollmentStatus enrollmentStatus;
  final ClassType classType;
  final String? heroImageUrl;
  final String? location;
  final DateTime? nextSession;

  double get occupancy =>
      capacity <= 0 ? 0 : approvedEnrollmentCount.clamp(0, capacity) / capacity;

  bool get hasAssignments => totalAssignments > 0;

  double get assignmentCompletionRate =>
      totalAssignments == 0 ? 1 : (totalAssignments - pendingAssignments) / totalAssignments;

  String get assignmentsLabel {
    if (totalAssignments == 0) return 'No assignments yet';
    if (pendingAssignments == 0) return '$totalAssignments assignments complete';
    return '$pendingAssignments of $totalAssignments due';
  }

  String get scheduleLabel {
    if (schedule.isEmpty) return 'Schedule to be shared';
    if (schedule.length == 1) return schedule.first;
    final firstTwo = schedule.take(2).join(' • ');
    return schedule.length > 2 ? '$firstTwo • +' : firstTwo;
  }

  String get subjectsLabel {
    if (subjects.isEmpty) return 'Subject TBD';
    if (subjects.length == 1) return subjects.first;
    return subjects.take(2).join(', ') + (subjects.length > 2 ? ' +' : '');
  }

  String get capacityLabel {
    if (capacity <= 0) return '${approvedEnrollmentCount} enrolled';
    return '$approvedEnrollmentCount of $capacity seats taken';
  }

  bool get isAtCapacity => capacity > 0 && approvedEnrollmentCount >= capacity;

  String get statusLabel {
    switch (enrollmentStatus) {
      case EnrollmentStatus.pending:
        return 'Pending Confirmation';
      case EnrollmentStatus.approved:
        return 'Active Enrollment';
      case EnrollmentStatus.rejected:
        return 'Not Approved';
      case EnrollmentStatus.cancelled:
        return 'Enrollment Cancelled';
    }
  }

  StudentClassSummary copyWith({
    String? enrollmentId,
    String? classId,
    String? className,
    String? studentId,
    String? studentName,
    String? teacherName,
    List<String>? subjects,
    List<String>? schedule,
    DateTime? startDate,
    DateTime? endDate,
    int? approvedEnrollmentCount,
    int? capacity,
    int? pendingAssignments,
    int? totalAssignments,
    EnrollmentStatus? enrollmentStatus,
    ClassType? classType,
    String? heroImageUrl,
    String? location,
    DateTime? nextSession,
  }) {
    return StudentClassSummary(
      enrollmentId: enrollmentId ?? this.enrollmentId,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      teacherName: teacherName ?? this.teacherName,
      subjects: subjects ?? this.subjects,
      schedule: schedule ?? this.schedule,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      approvedEnrollmentCount: approvedEnrollmentCount ?? this.approvedEnrollmentCount,
      capacity: capacity ?? this.capacity,
      pendingAssignments: pendingAssignments ?? this.pendingAssignments,
      totalAssignments: totalAssignments ?? this.totalAssignments,
      enrollmentStatus: enrollmentStatus ?? this.enrollmentStatus,
      classType: classType ?? this.classType,
      heroImageUrl: heroImageUrl ?? this.heroImageUrl,
      location: location ?? this.location,
      nextSession: nextSession ?? this.nextSession,
    );
  }
}

