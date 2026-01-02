import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enrollment_model.dart';
import '../../../core/domain/student_profile.dart';
import '../../../core/domain/user_profile.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/logger_provider.dart';
import '../../profile/application/parent_children_controller.dart';
import '../data/my_classes_repository.dart';
import '../domain/student_class_summary.dart';

class MyClassesState {
  const MyClassesState({
    required this.isParentContext,
    required this.classes,
    required this.children,
    this.focusedStudent,
  });

  final bool isParentContext;
  final List<StudentClassSummary> classes;
  final List<StudentProfile> children;
  final StudentProfile? focusedStudent;

  static const empty = MyClassesState(
    isParentContext: false,
    classes: [],
    children: [],
    focusedStudent: null,
  );

  int get totalClasses => classes.length;

  int get activeClasses => classes
      .where((summary) => summary.enrollmentStatus == EnrollmentStatus.approved)
      .length;

  int get pendingEnrollments => classes
      .where((summary) => summary.enrollmentStatus == EnrollmentStatus.pending)
      .length;

  int get totalPendingAssignments =>
      classes.fold<int>(0, (sum, summary) => sum + summary.pendingAssignments);

  bool get hasChildren => children.isNotEmpty;

  Map<String, List<StudentClassSummary>> get classesGroupedByStudent {
    final grouped = <String, List<StudentClassSummary>>{};
    for (final summary in classes) {
      grouped.putIfAbsent(summary.studentId, () => []).add(summary);
    }
    return grouped;
  }

  List<StudentClassSummary> classesForStudent(String studentId) =>
      classes.where((summary) => summary.studentId == studentId).toList();

  StudentClassSummary? classById(String classId, String studentId) {
    return classes.firstWhere(
      (summary) => summary.classId == classId && summary.studentId == studentId,
      orElse: () => classes.firstWhere(
        (summary) => summary.classId == classId,
        orElse: () => classes.first,
      ),
    );
  }

  MyClassesState copyWith({
    bool? isParentContext,
    List<StudentClassSummary>? classes,
    List<StudentProfile>? children,
    StudentProfile? focusedStudent,
  }) {
    return MyClassesState(
      isParentContext: isParentContext ?? this.isParentContext,
      classes: classes ?? this.classes,
      children: children ?? this.children,
      focusedStudent: focusedStudent ?? this.focusedStudent,
    );
  }
}

class MyClassesController extends AsyncNotifier<MyClassesState> {
  @override
  Future<MyClassesState> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return MyClassesState.empty;
    }

    final repository = ref.watch(myClassesRepositoryProvider);
    final selectedChild = ref.watch(selectedChildProvider);

    if (user.isParent && selectedChild == null) {
      final parentState =
          await ref.watch(parentChildrenControllerProvider.future);
      if (parentState.children.isEmpty) {
        return const MyClassesState(
          isParentContext: true,
          classes: [],
          children: [],
        );
      }

      final results = await Future.wait(
        parentState.children.map(
          (child) => repository
              .fetchClassesForStudent(child)
              .catchError((error, stackTrace) {
            AppLogger.error(
              'Failed to load classes for child',
              error: error,
              stackTrace: stackTrace,
              context: {'studentId': child.id},
            );
            return <StudentClassSummary>[];
          }),
        ),
      );

      final classes = <StudentClassSummary>[];
      for (final childClasses in results) {
        classes.addAll(childClasses);
      }

      return MyClassesState(
        isParentContext: true,
        classes: classes,
        children: parentState.children,
      );
    }

    final studentProfile = selectedChild ?? _studentFromUser(user);
    if (studentProfile == null) {
      return MyClassesState.empty;
    }

    final classes = await repository.fetchClassesForStudent(studentProfile);

    return MyClassesState(
      isParentContext: false,
      classes: classes,
      children: selectedChild != null ? [selectedChild] : const [],
      focusedStudent: studentProfile,
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  StudentProfile? _studentFromUser(UserProfile user) {
    if (!user.isStudent) return null;
    final academicInfo = user.academicInfo ?? const {};
    final gradeRaw = academicInfo['grade'];
    final grade = gradeRaw is int
        ? gradeRaw
        : gradeRaw is String
            ? int.tryParse(gradeRaw)
            : null;

    final medium = academicInfo['medium']?.toString();

    return StudentProfile(
      id: user.id,
      name: user.displayName,
      grade: grade,
      medium: medium,
      address: user.address,
      cities: const [],
      profileImageUrl: user.profileImageUrl,
      parentId: user.parentId,
      createdAt: user.createdAt,
      lastUpdatedAt: user.updatedAt,
      hasLinkedLogin: true,
    );
  }
}

final myClassesControllerProvider =
    AsyncNotifierProvider<MyClassesController, MyClassesState>(
  MyClassesController.new,
);

