import 'class_model.dart';

class ClassFilter {
  final String? searchQuery;
  final List<String> subjects;
  final List<ClassType> types;
  final String? location;
  final String? gradeLevel;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final List<String> scheduleDays; // e.g., ["Monday", "Wednesday"]
  final List<String> scheduleTimes; // e.g., ["Morning", "Afternoon"]

  const ClassFilter({
    this.searchQuery,
    this.subjects = const [],
    this.types = const [],
    this.location,
    this.gradeLevel,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.scheduleDays = const [],
    this.scheduleTimes = const [],
  });

  ClassFilter copyWith({
    String? searchQuery,
    List<String>? subjects,
    List<ClassType>? types,
    String? location,
    String? gradeLevel,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    List<String>? scheduleDays,
    List<String>? scheduleTimes,
  }) {
    return ClassFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      subjects: subjects ?? this.subjects,
      types: types ?? this.types,
      location: location ?? this.location,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      scheduleDays: scheduleDays ?? this.scheduleDays,
      scheduleTimes: scheduleTimes ?? this.scheduleTimes,
    );
  }

  bool get hasActiveFilters {
    return searchQuery?.isNotEmpty == true ||
        subjects.isNotEmpty ||
        types.isNotEmpty ||
        location?.isNotEmpty == true ||
        gradeLevel?.isNotEmpty == true ||
        minPrice != null ||
        maxPrice != null ||
        minRating != null ||
        scheduleDays.isNotEmpty ||
        scheduleTimes.isNotEmpty;
  }

  void clear() {
    // This would be used in a mutable context
    // For immutable approach, create a new instance with clear values
  }

  ClassFilter clearAll() {
    return const ClassFilter();
  }
}
