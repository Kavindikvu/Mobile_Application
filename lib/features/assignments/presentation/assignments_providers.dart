import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/assignment_repository.dart';
import '../data/assignment_model.dart';

final assignmentsProvider = FutureProvider<List<AssignmentItem>>((ref) async {
  final repo = ref.watch(assignmentRepositoryProvider);
  return repo.fetchAssignments();
});
