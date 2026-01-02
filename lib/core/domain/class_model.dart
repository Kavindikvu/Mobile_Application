enum ClassType {
  online,
  inPerson,
  hybrid,
}

enum ClassStatus {
  active,
  inactive,
  full,
  cancelled,
}

class ClassModel {
  final String id;
  final String title;
  final String description;
  final String instructorName;
  final String instructorId;
  final double rating;
  final int reviewCount;
  final ClassType type;
  final ClassStatus status;
  final String? location;
  final List<String> schedule; // e.g., ["Mon 10:00 AM", "Wed 10:00 AM"]
  final double price;
  final String currency;
  final String gradeLevel;
  final int maxStudents;
  final int currentEnrollment;
  final DateTime startDate;
  final DateTime endDate;
  final String? imageUrl;
  final List<String> subjects;
  final Map<String, dynamic>? metadata;

  const ClassModel({
    required this.id,
    required this.title,
    required this.description,
    required this.instructorName,
    required this.instructorId,
    required this.rating,
    required this.reviewCount,
    required this.type,
    required this.status,
    this.location,
    required this.schedule,
    required this.price,
    this.currency = 'USD',
    required this.gradeLevel,
    required this.maxStudents,
    required this.currentEnrollment,
    required this.startDate,
    required this.endDate,
    this.imageUrl,
    this.subjects = const [],
    this.metadata,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      instructorName: json['instructorName'] as String,
      instructorId: json['instructorId'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
      type: ClassType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => ClassType.online,
      ),
      status: ClassStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => ClassStatus.active,
      ),
      location: json['location'] as String?,
      schedule: (json['schedule'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      gradeLevel: json['gradeLevel'] as String,
      maxStudents: json['maxStudents'] as int,
      currentEnrollment: json['currentEnrollment'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      imageUrl: json['imageUrl'] as String?,
      subjects: (json['subjects'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Factory method to convert from API model
  /// Note: This requires subject names to be passed in since API only provides subjectIds
  factory ClassModel.fromApiClass(
    dynamic apiClass, {
    Map<String, String>? subjectNames,
    String? instructorName,
  }) {
    // Determine class type based on location and homeVisitCities
    final hasLocation = apiClass.location != null &&
        (apiClass.location?.address != null ||
            apiClass.location?.city != null);
    final hasHomeVisit = apiClass.homeVisitCities != null &&
        apiClass.homeVisitCities.isNotEmpty;

    ClassType classType;
    if (hasLocation && hasHomeVisit) {
      classType = ClassType.hybrid;
    } else if (hasLocation) {
      classType = ClassType.inPerson;
    } else if (hasHomeVisit) {
      classType = ClassType.inPerson; // Home visit is also in-person
    } else {
      classType = ClassType.online;
    }

    // Extract schedule strings from API schedules
    // Cast to List<dynamic> first, then map with proper type
    final schedulesList = apiClass.schedules as List<dynamic>;
    final scheduleStrings = schedulesList
        .map<String>((schedule) {
          // schedule is dynamic, so we need to call formatSchedule() on it
          return (schedule as dynamic).formatSchedule() as String;
        })
        .toList();

    // Extract unique subject names from schedules
    final subjectIds = schedulesList
        .where((s) => (s as dynamic).subjectId != null)
        .map((s) => (s as dynamic).subjectId as String)
        .toSet()
        .toList();
    final subjects = subjectIds
        .map((id) => subjectNames?[id] ?? id)
        .where((name) => name.isNotEmpty)
        .toList();

    // Determine start and end dates from schedules
    DateTime? startDate;
    DateTime? endDate;
    for (final schedule in schedulesList) {
      final s = schedule as dynamic;
      if (s.startDate != null) {
        final date = DateTime.parse(s.startDate as String);
        if (startDate == null || date.isBefore(startDate!)) {
          startDate = date;
        }
      }
      if (s.endDate != null) {
        final date = DateTime.parse(s.endDate as String);
        if (endDate == null || date.isAfter(endDate!)) {
          endDate = date;
        }
      }
      if (s.date != null && s.type == 'ONE_TIME') {
        final date = DateTime.parse(s.date as String);
        if (startDate == null || date.isBefore(startDate!)) {
          startDate = date;
        }
        if (endDate == null || date.isAfter(endDate!)) {
          endDate = date;
        }
      }
    }

    // Use current date as fallback
    startDate ??= DateTime.now();
    endDate ??= DateTime.now().add(const Duration(days: 365));

    return ClassModel(
      id: apiClass.id,
      title: apiClass.name,
      description: 'Class: ${apiClass.name}', // API doesn't provide description
      instructorName: instructorName ?? 'Teacher ${apiClass.teacherId.length > 8 ? apiClass.teacherId.substring(0, 8) : apiClass.teacherId}',
      instructorId: apiClass.teacherId,
      rating: 4.5, // Default rating - API doesn't provide this
      reviewCount: 0, // Default review count - API doesn't provide this
      type: classType,
      status: ClassStatus.active, // Default status
      location: apiClass.location?.displayAddress,
      schedule: scheduleStrings,
      price: apiClass.fees,
      currency: 'USD',
      gradeLevel: '8-12', // Default - API doesn't provide grade level
      maxStudents: 30, // Default - API doesn't provide this
      currentEnrollment: 0, // Default - API doesn't provide this
      startDate: startDate,
      endDate: endDate,
      imageUrl: apiClass.posterUrl,
      subjects: subjects,
      metadata: {
        'privacyLevel': apiClass.privacyLevel,
        'medium': apiClass.medium,
        'homeVisitCities': apiClass.homeVisitCities,
        'calendarId': apiClass.calendarId,
      },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'instructorName': instructorName,
      'instructorId': instructorId,
      'rating': rating,
      'reviewCount': reviewCount,
      'type': type.name,
      'status': status.name,
      'location': location,
      'schedule': schedule,
      'price': price,
      'currency': currency,
      'gradeLevel': gradeLevel,
      'maxStudents': maxStudents,
      'currentEnrollment': currentEnrollment,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'imageUrl': imageUrl,
      'subjects': subjects,
      'metadata': metadata,
    };
  }

  ClassModel copyWith({
    String? id,
    String? title,
    String? description,
    String? instructorName,
    String? instructorId,
    double? rating,
    int? reviewCount,
    ClassType? type,
    ClassStatus? status,
    String? location,
    List<String>? schedule,
    double? price,
    String? currency,
    String? gradeLevel,
    int? maxStudents,
    int? currentEnrollment,
    DateTime? startDate,
    DateTime? endDate,
    String? imageUrl,
    List<String>? subjects,
    Map<String, dynamic>? metadata,
  }) {
    return ClassModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      instructorName: instructorName ?? this.instructorName,
      instructorId: instructorId ?? this.instructorId,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      type: type ?? this.type,
      status: status ?? this.status,
      location: location ?? this.location,
      schedule: schedule ?? this.schedule,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      maxStudents: maxStudents ?? this.maxStudents,
      currentEnrollment: currentEnrollment ?? this.currentEnrollment,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      imageUrl: imageUrl ?? this.imageUrl,
      subjects: subjects ?? this.subjects,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isAvailable => status == ClassStatus.active && currentEnrollment < maxStudents;
  bool get isFull => currentEnrollment >= maxStudents;
  String get availabilityText => isFull ? 'Full' : '${maxStudents - currentEnrollment} spots left';
  String get priceText => '\$${price.toStringAsFixed(0)}/month';
  String get ratingText => '${rating.toStringAsFixed(1)} ($reviewCount reviews)';
  String? get medium => metadata?['medium'] as String?;
}
