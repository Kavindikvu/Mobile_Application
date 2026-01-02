import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/subject_service.dart';
import '../../providers/logger_provider.dart';
import 'in_memory_cache.dart';

/// Cached subjects map provider
/// Subjects rarely change, so we cache them globally with a long TTL
/// This prevents fetching all subjects on every class list request
final subjectsMapProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final cache = InMemoryCache();
  const cacheKey = 'subjects_map_all';
  
  // Check cache first
  final cached = cache.get<Map<String, String>>(cacheKey);
  if (cached != null) {
    AppLogger.debug('Subjects map served from cache');
    return cached;
  }

  // Fetch from API
  final subjectService = ref.watch(subjectServiceProvider);
  final subjects = await subjectService.getAllSubjects();
  
  // Create map
  final subjectsMap = <String, String>{};
  for (final subject in subjects) {
    subjectsMap[subject.subjectId] = subject.name;
  }

  // Cache for 1 hour (subjects don't change often)
  cache.set(cacheKey, subjectsMap, ttl: const Duration(hours: 1));
  
  AppLogger.debug(
    'Subjects map fetched and cached',
    context: {'count': subjectsMap.length},
  );

  return subjectsMap;
});

/// Get subjects by IDs (only fetches needed subjects)
/// Uses the cached subjects map if available, otherwise fetches individually
Future<Map<String, String>> getSubjectsByIds(
  List<String> subjectIds,
  SubjectService subjectService,
  InMemoryCache cache,
) async {
  if (subjectIds.isEmpty) return {};

  final Map<String, String> result = {};
  
  // Try to get from cached subjects map first
  final cachedMap = cache.get<Map<String, String>>('subjects_map_all');
  if (cachedMap != null) {
    // Use cached map
    for (final subjectId in subjectIds) {
      final name = cachedMap[subjectId];
      if (name != null && name.isNotEmpty) {
        result[subjectId] = name;
      }
    }
    
    // If we got all subjects from cache, return
    if (result.length == subjectIds.length) {
      return result;
    }
  }

  // Fetch missing subjects individually
  final missingIds = subjectIds.where((id) => !result.containsKey(id)).toList();
  if (missingIds.isNotEmpty) {
    // If only a few missing, fetch individually
    if (missingIds.length <= 5) {
      for (final subjectId in missingIds) {
        try {
          final subject = await subjectService.getSubjectById(subjectId);
          if (subject.name.isNotEmpty) {
            result[subjectId] = subject.name;
          }
        } catch (e) {
          AppLogger.debug(
            'Subject not found',
            context: {'subjectId': subjectId},
          );
        }
      }
    } else {
      // If many missing, fetch all subjects (more efficient)
      final allSubjects = await subjectService.getAllSubjects();
      final allSubjectsMap = <String, String>{};
      for (final subject in allSubjects) {
        allSubjectsMap[subject.subjectId] = subject.name;
      }
      
      // Update cache
      cache.set('subjects_map_all', allSubjectsMap, ttl: const Duration(hours: 1));
      
      // Add missing subjects to result
      for (final subjectId in missingIds) {
        final name = allSubjectsMap[subjectId];
        if (name != null && name.isNotEmpty) {
          result[subjectId] = name;
        }
      }
    }
  }

  return result;
}

