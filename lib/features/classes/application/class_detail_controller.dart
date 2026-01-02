import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/my_classes_repository.dart';
import '../domain/my_class_detail.dart';
import '../domain/student_class_summary.dart';

@immutable
class ClassDetailRequest {
  const ClassDetailRequest({
    required this.classId,
    required this.summary,
  });

  final String classId;
  final StudentClassSummary summary;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ClassDetailRequest) return false;
    return classId == other.classId &&
        summary.studentId == other.summary.studentId &&
        summary.enrollmentId == other.summary.enrollmentId;
  }

  @override
  int get hashCode =>
      Object.hash(classId, summary.studentId, summary.enrollmentId);
}

final classDetailProvider =
    FutureProvider.autoDispose.family<MyClassDetail, ClassDetailRequest>(
  (ref, request) async {
    final repository = ref.watch(myClassesRepositoryProvider);
    return repository.fetchClassDetail(
      classId: request.classId,
      studentId: request.summary.studentId,
      summaryFallback: request.summary,
    );
  },
);

