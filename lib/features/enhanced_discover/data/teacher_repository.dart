import 'package:riverpod/riverpod.dart';
import '../../../core/data/asset_data_provider.dart';

class TeacherProfile {
  final String id;
  final String name;
  final double rating;
  final int reviewCount;
  final List<String> subjects;
  final List<Map<String, dynamic>> classes;

  const TeacherProfile({
    required this.id,
    required this.name,
    required this.rating,
    required this.reviewCount,
    required this.subjects,
    required this.classes,
  });
}

final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  return TeacherRepository(const AssetDataProvider());
});

class TeacherRepository {
  final AssetDataProvider assetDataProvider;
  static const String _classesAsset = 'assets/data/classes.json';

  const TeacherRepository(this.assetDataProvider);

  Future<TeacherProfile?> getById(String instructorId) async {
    final list = await assetDataProvider.loadList(_classesAsset);
    final teacherClasses = list.where((c) => c['instructorId'] == instructorId).toList();
    if (teacherClasses.isEmpty) return null;
    final name = teacherClasses.first['instructorName'] as String? ?? 'Unknown';
    final rating = (teacherClasses.map((c) => (c['rating'] as num?)?.toDouble() ?? 0.0).fold<double>(0.0, (a, b) => a + b)) / teacherClasses.length;
    final reviewCount = teacherClasses.map((c) => (c['reviewCount'] as int?) ?? 0).fold(0, (a, b) => a + b);
    final subjects = <String>{};
    for (final c in teacherClasses) {
      subjects.addAll(((c['subjects'] as List?)?.cast<String>()) ?? const []);
    }
    return TeacherProfile(
      id: instructorId,
      name: name,
      rating: double.parse(rating.toStringAsFixed(1)),
      reviewCount: reviewCount,
      subjects: subjects.toList(),
      classes: teacherClasses.cast<Map<String, dynamic>>(),
    );
  }
}


