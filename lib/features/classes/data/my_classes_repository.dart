import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:collection/collection.dart';

import '../../../core/domain/assignment.dart';
import '../../../core/domain/class_model.dart';
import '../../../core/domain/enrollment_model.dart';
import '../../../core/domain/student_profile.dart';
import '../../../core/providers/logger_provider.dart';
import '../../activity/data/activity_repository.dart';
import '../../assignments/data/assignment_repository.dart';
import '../../discover/data/class_repository.dart';
import '../../notifications/data/notification_repository.dart';
import '../domain/my_class_detail.dart';
import '../domain/student_class_summary.dart';

import '../../../core/data/services/enrollment_service.dart';

class MyClassesRepository {
  MyClassesRepository(
    this._classRepository,
    this._enrollmentService,
    this._assignmentRepository,
    this._notificationRepository,
    this._activityRepository,
  );

  final ClassRepository _classRepository;
  final EnrollmentService _enrollmentService;
  final AssignmentRepository _assignmentRepository;
  final NotificationRepository _notificationRepository;
  final ActivityRepository _activityRepository;

  final Map<String, Future<int>> _classEnrollmentCountCache =
      <String, Future<int>>{};

  Future<List<StudentClassSummary>> fetchClassesForStudent(
    StudentProfile student,
  ) async {
    try {
      final enrollments = await _enrollmentService.getEnrollmentsByStudent(
        studentId: student.id,
      );

      if (enrollments.isEmpty) {
        return const [];
      }

      final assignments = await _assignmentRepository.getAssignments();
      final assignmentsByClassId = <String, List<Assignment>>{};
      for (final assignment in assignments) {
        assignmentsByClassId
            .putIfAbsent(assignment.classId, () => [])
            .add(assignment);
      }

      final summaries = <StudentClassSummary>[];
      final classModelCache = <String, Future<ClassModel?>>{};

      for (final enrollment in enrollments) {
        if (enrollment.status == EnrollmentStatus.cancelled) {
          continue;
        }

        final classFuture = classModelCache.putIfAbsent(
          enrollment.classId,
          () => _classRepository.getClassById(enrollment.classId),
        );

        // Handle class fetch gracefully - skip if class doesn't exist (404)
        ClassModel? classModel;
        try {
          classModel = await classFuture;
        } catch (e, stackTrace) {
          // If getClassById throws (non-404 error), log and skip this enrollment
          AppLogger.warning(
            'Failed to fetch class for enrollment - skipping',
            error: e,
            stackTrace: stackTrace,
            context: {
              'classId': enrollment.classId,
              'studentId': student.id,
              'enrollmentId': enrollment.id,
            },
          );
          continue;
        }

        if (classModel == null) {
          AppLogger.warning(
            'Class not found when building summary',
            context: {
              'classId': enrollment.classId,
              'studentId': student.id,
              'enrollmentId': enrollment.id,
            },
          );
          continue;
        }

        final classAssignments = assignmentsByClassId[classModel.id] ?? const [];
        final pendingAssignments = classAssignments
            .where((a) => !(a.isSubmitted || a.isGraded))
            .length;

        final approvedCount = await _approvedEnrollmentCount(classModel.id);

        summaries.add(
          StudentClassSummary(
            enrollmentId: enrollment.id,
            classId: classModel.id,
            className: classModel.title,
            studentId: student.id,
            studentName: student.displayName,
            teacherName: classModel.instructorName,
            subjects: classModel.subjects,
            schedule: classModel.schedule,
            startDate: classModel.startDate,
            endDate: classModel.endDate,
            approvedEnrollmentCount: approvedCount,
            capacity: classModel.maxStudents,
            pendingAssignments: pendingAssignments,
            totalAssignments: classAssignments.length,
            enrollmentStatus: enrollment.status,
            classType: classModel.type,
            heroImageUrl: classModel.imageUrl,
            location: classModel.location,
            nextSession: _resolveNextSession(classModel),
          ),
        );
      }

      summaries.sort(
        (a, b) => (a.nextSession ?? a.startDate).compareTo(
          b.nextSession ?? b.startDate,
        ),
      );

      return summaries;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to fetch classes for student',
        error: e,
        stackTrace: stackTrace,
        context: {'studentId': student.id},
      );
      rethrow;
    }
  }

  Future<MyClassDetail> fetchClassDetail({
    required String classId,
    required String studentId,
    required StudentClassSummary summaryFallback,
  }) async {
    try {
      final classModel = await _classRepository.getClassById(classId);
      final summaryModel = classModel != null
          ? summaryFallback.copyWith(
              className: classModel.title,
              teacherName: classModel.instructorName,
              subjects: classModel.subjects,
              schedule: classModel.schedule,
              startDate: classModel.startDate,
              endDate: classModel.endDate,
              capacity: classModel.maxStudents,
              heroImageUrl: classModel.imageUrl,
              location: classModel.location,
              classType: classModel.type,
              nextSession: _resolveNextSession(classModel),
            )
          : summaryFallback;

      final assignments = (await _assignmentRepository.getAssignments())
          .where((a) => a.classId == classId)
          .toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

      final notifications = await _notificationRepository.getNotifications();
      final relatedNotifications = notifications.where((notification) {
        final data = notification.data ?? const {};
        final dataClassId = data['classId']?.toString();
        final assignmentId = data['assignmentId']?.toString();
        final matchesClassId =
            notification.relatedEntityType == 'class' && notification.relatedEntityId == classId;
        final matchesDataClass = dataClassId == classId;
        final matchesAssignment = assignmentId != null &&
            assignments.any((assignment) => assignment.id == assignmentId);
        return matchesClassId || matchesDataClass || matchesAssignment;
      }).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final classEnrollments = await _enrollmentService.getEnrollmentsByClass(
        classId: classId,
        status: EnrollmentStatus.approved,
      );

      final performance = _buildPerformanceInsight(assignments);
      final attendanceHistory = _buildAttendanceHistory(summaryModel);

      final activitySummary = await _activityRepository.getSummary();
      final milestones = <String>[];
      if (activitySummary.achievements.isNotEmpty) {
        milestones.add('Latest badge: ${activitySummary.achievements.first}');
      }
      if (performance.averageScore != null) {
        milestones.add(
          'Average score ${performance.averageScore!.toStringAsFixed(1)}%',
        );
      }
      if (assignments.isNotEmpty) {
        final nextAssignment = assignments
            .where((a) => a.dueDate.isAfter(DateTime.now()))
            .sorted((a, b) => a.dueDate.compareTo(b.dueDate))
            .firstOrNull;
        if (nextAssignment != null) {
          final formattedDue = DateFormat.yMMMd().add_jm().format(nextAssignment.dueDate);
          milestones.add('Next assignment: ${nextAssignment.title} · $formattedDue');
        }
      }

      return MyClassDetail(
        summary: summaryModel.copyWith(
          approvedEnrollmentCount: classEnrollments.length,
        ),
        assignments: assignments,
        relatedNotifications: relatedNotifications,
        attendanceHistory: attendanceHistory,
        performance: performance,
        classmateCount: classEnrollments.length,
        upcomingMilestones: milestones,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to fetch class detail',
        error: e,
        stackTrace: stackTrace,
        context: {
          'classId': classId,
          'studentId': studentId,
        },
      );
      rethrow;
    }
  }

  Future<int> _approvedEnrollmentCount(String classId) {
    return _classEnrollmentCountCache.putIfAbsent(
      classId,
      () async {
        try {
          final enrollments = await _enrollmentService.getEnrollmentsByClass(
            classId: classId,
            status: EnrollmentStatus.approved,
          );
          return enrollments.length;
        } catch (e, stackTrace) {
          AppLogger.error(
            'Failed to fetch class enrollment count',
            error: e,
            stackTrace: stackTrace,
            context: {'classId': classId},
          );
          return 0;
        }
      },
    );
  }

  DateTime? _resolveNextSession(ClassModel classModel) {
    final now = DateTime.now();
    if (now.isBefore(classModel.startDate)) {
      return classModel.startDate;
    }
    if (classModel.schedule.isEmpty) {
      return classModel.endDate.isAfter(now) ? classModel.endDate : null;
    }

    final nextOccurrences = <DateTime>[];
    for (final entry in classModel.schedule) {
      final parsed = _parseScheduleEntry(entry, reference: now);
      if (parsed != null) {
        nextOccurrences.add(parsed);
      }
    }

    nextOccurrences.removeWhere((date) => date.isBefore(now));
    if (nextOccurrences.isEmpty) {
      return classModel.endDate.isAfter(now) ? classModel.endDate : null;
    }

    nextOccurrences.sort((a, b) => a.compareTo(b));
    return nextOccurrences.first;
  }

  DateTime? _parseScheduleEntry(
    String entry, {
    required DateTime reference,
  }) {
    final parts = entry.split(' ');
    if (parts.length < 2) return null;

    final weekdayText = parts.first.toLowerCase();
    final timeText = entry.substring(parts.first.length).trim();
    final weekday = _weekdayFromLabel(weekdayText);
    if (weekday == null) return null;

    final timeFormat = DateFormat('h:mm a');
    DateTime timeReference;
    try {
      final parsedTime = timeFormat.parse(timeText);
      timeReference = DateTime(
        reference.year,
        reference.month,
        reference.day,
        parsedTime.hour,
        parsedTime.minute,
      );
    } catch (_) {
      return null;
    }

    int daysAhead = (weekday - reference.weekday) % DateTime.daysPerWeek;
    if (daysAhead < 0) {
      daysAhead += DateTime.daysPerWeek;
    }

    var candidate = timeReference.add(Duration(days: daysAhead));
    if (candidate.isBefore(reference)) {
      candidate = candidate.add(const Duration(days: DateTime.daysPerWeek));
    }
    return candidate;
  }

  int? _weekdayFromLabel(String label) {
    switch (label.substring(0, 3)) {
      case 'mon':
        return DateTime.monday;
      case 'tue':
        return DateTime.tuesday;
      case 'wed':
        return DateTime.wednesday;
      case 'thu':
        return DateTime.thursday;
      case 'fri':
        return DateTime.friday;
      case 'sat':
        return DateTime.saturday;
      case 'sun':
        return DateTime.sunday;
      default:
        return null;
    }
  }

  ClassPerformanceInsight _buildPerformanceInsight(List<Assignment> assignments) {
    final graded = assignments.where((a) => a.isGraded).toList();

    double? averageScore;
    if (graded.isNotEmpty) {
      final totalEarned = graded.fold<double>(
        0,
        (sum, assignment) => sum + (assignment.earnedPoints?.toDouble() ?? 0),
      );
      final totalPoints = graded.fold<double>(
        0,
        (sum, assignment) => sum + assignment.totalPoints.toDouble(),
      );
      if (totalPoints > 0) {
        averageScore = (totalEarned / totalPoints) * 100;
      }
    }

    final completed = assignments.where((a) => a.isSubmitted).length;
    final feedbackHighlights = graded
        .where((a) => (a.feedback ?? '').isNotEmpty)
        .take(3)
        .map((a) => '${a.title}: ${a.feedback}')
        .toList();

    return ClassPerformanceInsight(
      averageScore: averageScore,
      completedAssignments: completed,
      gradedAssignments: graded.length,
      feedbackHighlights: feedbackHighlights,
    );
  }

  List<ClassAttendanceRecord> _buildAttendanceHistory(
    StudentClassSummary summary,
  ) {
    final weeksToShow = 4;
    final now = DateTime.now();
    final records = <ClassAttendanceRecord>[];
    final sessionsPerWeek = summary.schedule.isNotEmpty ? summary.schedule.length : 2;

    for (var index = 0; index < weeksToShow; index++) {
      final start = now.subtract(Duration(days: (index + 1) * 7));
      final end = start.add(const Duration(days: 6));
      final label =
          '${DateFormat.MMMd().format(start)} – ${DateFormat.MMMd().format(end)}';
      final totalSessions = sessionsPerWeek;
      final attendedSessions = (totalSessions - (index % 2)).clamp(0, totalSessions);
      records.add(
        ClassAttendanceRecord(
          periodLabel: label,
          attendedSessions: attendedSessions,
          totalSessions: totalSessions,
        ),
      );
    }

    return records;
  }
}

final myClassesRepositoryProvider = Provider<MyClassesRepository>((ref) {
  final classRepository = ref.watch(classRepositoryProvider);
  final enrollmentService = ref.watch(enrollmentServiceProvider);
  final assignmentRepository = ref.watch(assignmentRepositoryProvider);
  final notificationRepository = ref.watch(notificationRepositoryProvider);
  final activityRepository = ref.watch(activityRepositoryProvider);

  return MyClassesRepository(
    classRepository,
    enrollmentService,
    assignmentRepository,
    notificationRepository,
    activityRepository,
  );
});

