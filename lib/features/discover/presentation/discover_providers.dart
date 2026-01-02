import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/class_repository.dart';
import '../data/class_model.dart';

final classesProvider = FutureProvider<List<ClassItem>>((ref) async {
  final repo = ref.watch(classRepositoryProvider);
  return repo.fetchClasses();
});
