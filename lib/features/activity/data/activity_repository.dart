import 'package:riverpod/riverpod.dart';
import '../../../core/data/asset_data_provider.dart';

class ActivitySummary {
  final double gpa;
  final double attendanceRate;
  final int completedAssignments;
  final int totalAssignments;
  final List<String> achievements;

  const ActivitySummary({
    required this.gpa,
    required this.attendanceRate,
    required this.completedAssignments,
    required this.totalAssignments,
    required this.achievements,
  });
}

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository(const AssetDataProvider());
});

class ActivityRepository {
  final AssetDataProvider assetDataProvider;
  static const String _academicAsset = 'assets/data/academic_info.json';
  static const String _assignmentsAsset = 'assets/data/assignments.json';

  const ActivityRepository(this.assetDataProvider);

  Future<ActivitySummary> getSummary() async {
    final academic = await assetDataProvider.loadMap(_academicAsset);
    final assignments = await assetDataProvider.loadList(_assignmentsAsset);

    final gpa = (academic['gpa'] as num?)?.toDouble() ?? 0.0;
    final attendanceRate = (academic['additionalInfo']?['attendanceRate'] as num?)?.toDouble() ?? 0.0;
    int completed = 0;
    for (final a in assignments) {
      if ((a['status'] as String?) == 'graded' || (a['status'] as String?) == 'submitted') {
        completed++;
      }
    }
    final total = assignments.length;
    final achievements = (academic['achievements'] as List?)?.cast<String>() ?? const [];

    return ActivitySummary(
      gpa: gpa,
      attendanceRate: attendanceRate,
      completedAssignments: completed,
      totalAssignments: total,
      achievements: achievements,
    );
  }
}


