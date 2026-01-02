import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/asset_data_provider.dart';
import '../../../../core/domain/assignment.dart';

final assetDataProviderProvider = Provider<AssetDataProvider>((ref) => const AssetDataProvider());

class AssignmentRepository {
  const AssignmentRepository(this._assetDataProvider);

  final AssetDataProvider _assetDataProvider;

  Future<List<Assignment>> getAssignments({String? classId}) async {
    try {
      final data = await _assetDataProvider.loadList('assets/data/assignments.json');
      final assignments = data.map((json) => Assignment.fromJson(json)).toList();
      
      if (classId != null) {
        return assignments.where((a) => a.classId == classId).toList();
      }
      
      return assignments;
    } catch (e) {
      throw Exception('Failed to load assignments: $e');
    }
  }

  Future<Assignment?> getAssignmentById(String id) async {
    try {
      final assignments = await getAssignments();
      return assignments.where((a) => a.id == id).firstOrNull;
    } catch (e) {
      throw Exception('Failed to load assignment: $e');
    }
  }

  Future<List<Assignment>> getAssignmentsByStatus(AssignmentStatus status) async {
    try {
      final assignments = await getAssignments();
      return assignments.where((a) => a.status == status).toList();
    } catch (e) {
      throw Exception('Failed to load assignments by status: $e');
    }
  }

  Future<List<Assignment>> getOverdueAssignments() async {
    try {
      final assignments = await getAssignments();
      return assignments.where((a) => a.isOverdue).toList();
    } catch (e) {
      throw Exception('Failed to load overdue assignments: $e');
    }
  }

  Future<List<Assignment>> getDueSoonAssignments() async {
    try {
      final assignments = await getAssignments();
      return assignments.where((a) => a.isDueSoon).toList();
    } catch (e) {
      throw Exception('Failed to load due soon assignments: $e');
    }
  }
}

final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  final assetDataProvider = ref.watch(assetDataProviderProvider);
  return AssignmentRepository(assetDataProvider);
});

final assignmentsProvider = FutureProvider<List<Assignment>>((ref) async {
  final repository = ref.watch(assignmentRepositoryProvider);
  return repository.getAssignments();
});

final assignmentByIdProvider = FutureProvider.family<Assignment?, String>((ref, id) async {
  final repository = ref.watch(assignmentRepositoryProvider);
  return repository.getAssignmentById(id);
});

final assignmentsByStatusProvider = FutureProvider.family<List<Assignment>, AssignmentStatus>((ref, status) async {
  final repository = ref.watch(assignmentRepositoryProvider);
  return repository.getAssignmentsByStatus(status);
});

final overdueAssignmentsProvider = FutureProvider<List<Assignment>>((ref) async {
  final repository = ref.watch(assignmentRepositoryProvider);
  return repository.getOverdueAssignments();
});

final dueSoonAssignmentsProvider = FutureProvider<List<Assignment>>((ref) async {
  final repository = ref.watch(assignmentRepositoryProvider);
  return repository.getDueSoonAssignments();
});