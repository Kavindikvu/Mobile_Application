import '../../../core/domain/assignment.dart';
import '../../../core/domain/notification.dart';
import 'student_class_summary.dart';

class ClassAttendanceRecord {
  const ClassAttendanceRecord({
    required this.periodLabel,
    required this.attendedSessions,
    required this.totalSessions,
  });

  final String periodLabel;
  final int attendedSessions;
  final int totalSessions;

  double get attendanceRate =>
      totalSessions == 0 ? 0 : attendedSessions / totalSessions;
}

class ClassPerformanceInsight {
  const ClassPerformanceInsight({
    required this.averageScore,
    required this.completedAssignments,
    required this.gradedAssignments,
    required this.feedbackHighlights,
  });

  final double? averageScore;
  final int completedAssignments;
  final int gradedAssignments;
  final List<String> feedbackHighlights;

  bool get hasScores => averageScore != null;
}

class MyClassDetail {
  const MyClassDetail({
    required this.summary,
    required this.assignments,
    required this.relatedNotifications,
    required this.attendanceHistory,
    required this.performance,
    required this.classmateCount,
    required this.upcomingMilestones,
  });

  final StudentClassSummary summary;
  final List<Assignment> assignments;
  final List<AppNotification> relatedNotifications;
  final List<ClassAttendanceRecord> attendanceHistory;
  final ClassPerformanceInsight performance;
  final int classmateCount;
  final List<String> upcomingMilestones;

  Assignment? get nextDueAssignment {
    final now = DateTime.now();
    final dueAssignments = assignments
        .where((a) => a.dueDate.isAfter(now) && !a.isSubmitted)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return dueAssignments.firstOrNull;
  }

  List<Assignment> get gradedAssignments =>
      assignments.where((a) => a.isGraded).toList();

  List<AppNotification> get highPriorityNotifications =>
      relatedNotifications.where((n) => n.priority.index >= kAppNotificationPriorityThreshold).toList();
}

/// Notifications at or above this priority index should be surfaced as alerts.
/// Keep this in sync with [NotificationPriority.high].
const int kAppNotificationPriorityThreshold = 2;

