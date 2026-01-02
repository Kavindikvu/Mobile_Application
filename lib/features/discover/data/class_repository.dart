import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/services/class_service.dart';
import '../../../../core/data/services/subject_service.dart';
import '../../../../core/data/services/user_service.dart';
import '../../../../core/data/models/api_class_model.dart';
import '../../../../core/data/models/api_subject_model.dart';
import '../../../../core/domain/class_model.dart';
import '../../../../core/domain/class_filter.dart';
import '../../../../core/data/cache/in_memory_cache.dart';
import '../../../../core/data/cache/request_deduplicator.dart';
import '../../../../core/data/cache/subjects_cache_provider.dart';
import '../../../../core/providers/logger_provider.dart';
import '../../../../core/data/api_client.dart';

class ClassRepository {
  const ClassRepository(
    this._classService,
    this._subjectService,
    this._userService,
    this._cache,
    this._deduplicator,
  );

  final ClassService _classService;
  final SubjectService _subjectService;
  final UserService _userService;
  final InMemoryCache _cache;
  final RequestDeduplicator _deduplicator;

  Future<List<ClassModel>> getClasses({ClassFilter? filter}) async {
    // Create cache key based on filter
    final cacheKey = 'classes_${filter?.hashCode ?? 'all'}';
    
    // Use deduplication to prevent multiple simultaneous requests
    return _deduplicator.deduplicate(
      cacheKey,
      () async {
        try {
          // Check cache first
          final cached = _cache.get<List<ClassModel>>(cacheKey);
          if (cached != null) {
            AppLogger.debug('Classes served from cache', context: {'count': cached.length});
            // Refresh in background without blocking
            _refreshClassesInBackground(cacheKey, filter);
            return cached;
          }

          // Fetch classes from API
          final apiClasses = await _classService.getAllClasses(
            homeVisitCities: filter?.location != null ? [filter!.location!] : null,
          );

          // Extract unique IDs needed
          final teacherIds = <String>{};
          final subjectIds = <String>{};
          
          for (final apiClass in apiClasses) {
            teacherIds.add(apiClass.teacherId);
            final classSubjectIds = apiClass.schedules
                .where((s) => s.subjectId != null && s.subjectId!.isNotEmpty)
                .map((s) => s.subjectId!)
                .toSet();
            subjectIds.addAll(classSubjectIds);
          }

          // Fetch subjects and teachers in parallel (optimized)
          final results = await Future.wait([
            getSubjectsByIds(subjectIds.toList(), _subjectService, _cache),
            _userService.getUsersByIds(teacherIds.toList()),
          ]);

          final subjectMap = results[0] as Map<String, String>;
          final teacherNamesMap = results[1] as Map<String, String>;

          // Convert API classes to domain models
          final classes = <ClassModel>[];
          for (final apiClass in apiClasses) {
            final teacherName = teacherNamesMap[apiClass.teacherId];
            
            // Extract subject IDs from schedules
            final classSubjectIds = apiClass.schedules
                .where((s) => s.subjectId != null && s.subjectId!.isNotEmpty)
                .map((s) => s.subjectId!)
                .toSet()
                .toList();
            
            // Get subject names from map
            final subjectNames = classSubjectIds
                .map((id) => subjectMap[id])
                .whereType<String>()
                .where((name) => name.isNotEmpty)
                .toList();

            final classModel = ClassModel.fromApiClass(
              apiClass,
              subjectNames: subjectMap,
              instructorName: teacherName,
            );
            
            // If subjects are still empty after mapping, use the fetched subject names
            if (classModel.subjects.isEmpty && subjectNames.isNotEmpty) {
              classes.add(classModel.copyWith(subjects: subjectNames));
            } else {
              classes.add(classModel);
            }
          }

          // Apply client-side filters if needed
          final filteredClasses = (filter == null || !filter.hasActiveFilters)
              ? classes
              : _applyFilters(classes, filter);

          // Cache the result (5 minutes TTL)
          _cache.set(cacheKey, filteredClasses, ttl: const Duration(minutes: 5));

          AppLogger.debug(
            'Classes fetched and cached',
            context: {
              'count': filteredClasses.length,
              'teachers': teacherIds.length,
              'subjects': subjectIds.length,
            },
          );

          return filteredClasses;
        } catch (e, stackTrace) {
          AppLogger.error(
            'Failed to load classes',
            error: e,
            stackTrace: stackTrace,
          );
          throw Exception('Failed to load classes: $e');
        }
      },
    );
  }

  /// Refresh classes in background without blocking
  void _refreshClassesInBackground(String cacheKey, ClassFilter? filter) {
    Future.microtask(() async {
      try {
        final apiClasses = await _classService.getAllClasses(
          homeVisitCities: filter?.location != null ? [filter!.location!] : null,
        );

        final teacherIds = <String>{};
        final subjectIds = <String>{};
        
        for (final apiClass in apiClasses) {
          teacherIds.add(apiClass.teacherId);
          final classSubjectIds = apiClass.schedules
              .where((s) => s.subjectId != null && s.subjectId!.isNotEmpty)
              .map((s) => s.subjectId!)
              .toSet();
          subjectIds.addAll(classSubjectIds);
        }

        final results = await Future.wait([
          getSubjectsByIds(subjectIds.toList(), _subjectService, _cache),
          _userService.getUsersByIds(teacherIds.toList()),
        ]);

        final subjectMap = results[0] as Map<String, String>;
        final teacherNamesMap = results[1] as Map<String, String>;

        final classes = <ClassModel>[];
        for (final apiClass in apiClasses) {
          final teacherName = teacherNamesMap[apiClass.teacherId];
          final classSubjectIds = apiClass.schedules
              .where((s) => s.subjectId != null && s.subjectId!.isNotEmpty)
              .map((s) => s.subjectId!)
              .toSet()
              .toList();
          
          final subjectNames = classSubjectIds
              .map((id) => subjectMap[id])
              .whereType<String>()
              .where((name) => name.isNotEmpty)
              .toList();

          final classModel = ClassModel.fromApiClass(
            apiClass,
            subjectNames: subjectMap,
            instructorName: teacherName,
          );
          
          if (classModel.subjects.isEmpty && subjectNames.isNotEmpty) {
            classes.add(classModel.copyWith(subjects: subjectNames));
          } else {
            classes.add(classModel);
          }
        }

        final filteredClasses = (filter == null || !filter.hasActiveFilters)
            ? classes
            : _applyFilters(classes, filter);

        _cache.set(cacheKey, filteredClasses, ttl: const Duration(minutes: 5));
        
        AppLogger.debug('Classes refreshed in background');
      } catch (e) {
        // Silent fail - cache still valid
        AppLogger.debug('Background refresh failed', context: {'error': e.toString()});
      }
    });
  }

  Future<ClassModel?> getClassById(String id) async {
    // Check cache first
    final cacheKey = 'class_$id';
    final cached = _cache.get<ClassModel>(cacheKey);
    if (cached != null) {
      AppLogger.debug('Class served from cache', context: {'classId': id});
      return cached;
    }

    // Use deduplication
    return _deduplicator.deduplicate(
      cacheKey,
      () async {
        try {
          final apiClass = await _classService.getClassById(id);

          // Extract subject IDs from schedules
          final subjectIds = apiClass.schedules
              .where((s) => s.subjectId != null && s.subjectId!.isNotEmpty)
              .map((s) => s.subjectId!)
              .toSet()
              .toList();

          // Fetch subject names and teacher name in parallel
          final results = await Future.wait([
            getSubjectsByIds(subjectIds, _subjectService, _cache),
            _userService.getUserById(apiClass.teacherId),
          ]);

          final subjectMap = results[0] as Map<String, String>;
          final teacherData = results[1] as Map<String, String>?;
          
          final fullTeacherName = teacherData != null
              ? '${teacherData['firstName']} ${teacherData['lastName']}'.trim()
              : null;

          // Get subject names from map
          final subjectNames = subjectIds
              .map((id) => subjectMap[id])
              .whereType<String>()
              .where((name) => name.isNotEmpty)
              .toList();

          final classModel = ClassModel.fromApiClass(
            apiClass,
            subjectNames: subjectMap,
            instructorName: fullTeacherName,
          );

          // If subjects are still empty after mapping, use the fetched subject names
          final result = classModel.subjects.isEmpty && subjectNames.isNotEmpty
              ? classModel.copyWith(subjects: subjectNames)
              : classModel;

          // Cache the result (5 minutes TTL)
          _cache.set(cacheKey, result, ttl: const Duration(minutes: 5));

          return result;
        } on ApiException catch (e, stackTrace) {
          // Handle 404 (class not found) gracefully - return null instead of throwing
          if (e.statusCode == 404) {
            AppLogger.warning(
              'Class not found (404) - skipping orphaned enrollment',
              context: {
                'classId': id,
                'message': e.message,
              },
            );
            return null;
          }
          // For other API errors, log and rethrow
          AppLogger.error(
            'Failed to load class',
            error: e,
            stackTrace: stackTrace,
            context: {'classId': id},
          );
          rethrow;
        } catch (e, stackTrace) {
          AppLogger.error(
            'Failed to load class',
            error: e,
            stackTrace: stackTrace,
            context: {'classId': id},
          );
          rethrow;
        }
      },
    );
  }

  Future<List<ClassModel>> searchClasses(String query) async {
    try {
      final classes = await getClasses();
      return classes.where((c) => 
        c.title.toLowerCase().contains(query.toLowerCase()) ||
        c.description.toLowerCase().contains(query.toLowerCase()) ||
        c.instructorName.toLowerCase().contains(query.toLowerCase()) ||
        c.subjects.any((s) => s.toLowerCase().contains(query.toLowerCase()))
      ).toList();
    } catch (e) {
      throw Exception('Failed to search classes: $e');
    }
  }

  List<ClassModel> _applyFilters(List<ClassModel> classes, ClassFilter filter) {
    return classes.where((classModel) {
      // Search query filter
      if (filter.searchQuery?.isNotEmpty == true) {
        final query = filter.searchQuery!.toLowerCase();
        if (!classModel.title.toLowerCase().contains(query) &&
            !classModel.description.toLowerCase().contains(query) &&
            !classModel.instructorName.toLowerCase().contains(query) &&
            !classModel.subjects.any((s) => s.toLowerCase().contains(query))) {
          return false;
        }
      }

      // Subject filter
      if (filter.subjects.isNotEmpty) {
        if (!filter.subjects.any((subject) => classModel.subjects.contains(subject))) {
          return false;
        }
      }

      // Type filter
      if (filter.types.isNotEmpty) {
        if (!filter.types.contains(classModel.type)) {
          return false;
        }
      }

      // Location filter
      if (filter.location?.isNotEmpty == true) {
        if (classModel.location?.toLowerCase().contains(filter.location!.toLowerCase()) != true) {
          return false;
        }
      }

      // Grade level filter
      if (filter.gradeLevel?.isNotEmpty == true) {
        if (!classModel.gradeLevel.toLowerCase().contains(filter.gradeLevel!.toLowerCase())) {
          return false;
        }
      }

      // Price filter
      if (filter.minPrice != null && classModel.price < filter.minPrice!) {
        return false;
      }
      if (filter.maxPrice != null && classModel.price > filter.maxPrice!) {
        return false;
      }

      // Rating filter
      if (filter.minRating != null && classModel.rating < filter.minRating!) {
        return false;
      }

      // Schedule filter
      if (filter.scheduleDays.isNotEmpty) {
        final classDays = classModel.schedule.map((s) => s.split(' ')[0]).toSet();
        if (!filter.scheduleDays.any((day) => classDays.contains(day))) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}

final classRepositoryProvider = Provider<ClassRepository>((ref) {
  final classService = ref.watch(classServiceProvider);
  final subjectService = ref.watch(subjectServiceProvider);
  final userService = ref.watch(userServiceProvider);
  final cache = InMemoryCache();
  final deduplicator = RequestDeduplicator();
  return ClassRepository(classService, subjectService, userService, cache, deduplicator);
});

final classesProvider = FutureProvider<List<ClassModel>>((ref) async {
  final repository = ref.watch(classRepositoryProvider);
  return repository.getClasses();
});

final classSearchProvider = FutureProvider.family<List<ClassModel>, String>((ref, query) async {
  final repository = ref.watch(classRepositoryProvider);
  return repository.searchClasses(query);
});

final classByIdProvider = FutureProvider.family<ClassModel?, String>((ref, id) async {
  final repository = ref.watch(classRepositoryProvider);
  return repository.getClassById(id);
});

// Provider for subjects list
final subjectsProvider = FutureProvider<List<String>>((ref) async {
  final subjectService = ref.watch(subjectServiceProvider);
  final subjects = await subjectService.getAllSubjects();
  return subjects.map((s) => s.name).toList()..sort();
});