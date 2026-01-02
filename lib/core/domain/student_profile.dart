import 'package:characters/characters.dart';

/// Lightweight domain model that mirrors the student-service payload while
/// exposing UI-friendly helpers (display name, grade labels, etc.).
class StudentProfile {
  final String id; // studentId from API
  final String name;
  final int? grade;
  final String? medium;
  final String? address;
  final List<String> cities;
  final String? profileImageUrl;
  final String? qrCodeUrl;
  final String? parentId;
  final String? calendarId;
  final DateTime? createdAt;
  final DateTime? lastUpdatedAt;
  final bool hasLinkedLogin;

  const StudentProfile({
    required this.id,
    required this.name,
    this.grade,
    this.medium,
    this.address,
    this.cities = const [],
    this.profileImageUrl,
    this.qrCodeUrl,
    this.parentId,
    this.calendarId,
    this.createdAt,
    this.lastUpdatedAt,
    this.hasLinkedLogin = false,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    final studentId = (json['studentId'] ?? json['id'])?.toString();
    final gradeValue = json['grade'];
    final grade = gradeValue is int
        ? gradeValue
        : gradeValue is String
            ? int.tryParse(gradeValue)
            : null;

    final createdAtRaw = json['createdAt'];
    final updatedAtRaw = json['lastUpdatedAt'] ?? json['updatedAt'];

    return StudentProfile(
      id: studentId ?? '',
      name: (json['name'] ?? '').toString(),
      grade: grade,
      medium: json['medium'] as String?,
      address: json['address'] as String?,
      cities: (json['cities'] as List<dynamic>?)
              ?.map((city) => city.toString())
              .toList() ??
          const [],
      profileImageUrl: json['profileImageUrl'] as String?,
      qrCodeUrl: json['qrCodeUrl'] as String?,
      parentId: json['parentId']?.toString(),
      calendarId: json['calendarId']?.toString(),
      createdAt:
          createdAtRaw is String ? DateTime.tryParse(createdAtRaw) : null,
      lastUpdatedAt:
          updatedAtRaw is String ? DateTime.tryParse(updatedAtRaw) : null,
      hasLinkedLogin: (json['hasLinkedLogin'] as bool?) ??
          (json['linkedLogin'] as bool?) ??
          false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': id,
      'name': name,
      if (grade != null) 'grade': grade,
      if (medium != null) 'medium': medium,
      if (address != null) 'address': address,
      if (cities.isNotEmpty) 'cities': cities,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (qrCodeUrl != null) 'qrCodeUrl': qrCodeUrl,
      if (parentId != null) 'parentId': parentId,
      if (calendarId != null) 'calendarId': calendarId,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (lastUpdatedAt != null)
        'lastUpdatedAt': lastUpdatedAt!.toIso8601String(),
      'hasLinkedLogin': hasLinkedLogin,
    };
  }

  StudentProfile copyWith({
    String? id,
    String? name,
    int? grade,
    String? medium,
    String? address,
    List<String>? cities,
    String? profileImageUrl,
    String? qrCodeUrl,
    String? parentId,
    String? calendarId,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    bool? hasLinkedLogin,
  }) {
    return StudentProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      medium: medium ?? this.medium,
      address: address ?? this.address,
      cities: cities ?? List<String>.from(this.cities),
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      parentId: parentId ?? this.parentId,
      calendarId: calendarId ?? this.calendarId,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      hasLinkedLogin: hasLinkedLogin ?? this.hasLinkedLogin,
    );
  }

  String get displayName => name.isNotEmpty ? name : 'Unnamed Child';

  String get gradeDisplay => grade != null ? 'Grade $grade' : 'Grade not set';

  String get mediumDisplay =>
      medium != null ? _titleCase(medium!) : 'Medium not set';

  String get initials {
    final parts = name.trim().split(' ').where((part) => part.isNotEmpty);
    final firstTwo = parts.take(2).map((word) => word.characters.first);
    final joined = firstTwo.join().toUpperCase();
    if (joined.isNotEmpty) {
      return joined;
    }
    return name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
  }

  bool get hasProfileOnly => !hasLinkedLogin;

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value.split('_').map((piece) {
      if (piece.isEmpty) return piece;
      final lower = piece.toLowerCase();
      return lower[0].toUpperCase() + lower.substring(1);
    }).join(' ');
  }
}

/// Pending requests returned by parent-child linking workflows.
class PendingChildRequest {
  final String requestId;
  final StudentProfile student;
  final String teacherName;
  final String instituteName;
  final String classDetails;
  final DateTime requestedAt;

  const PendingChildRequest({
    required this.requestId,
    required this.student,
    required this.teacherName,
    required this.instituteName,
    required this.classDetails,
    required this.requestedAt,
  });
}

/// Duplicate profile row used by parent-child merge flows.
class DuplicateStudentProfile {
  final String duplicateId;
  final StudentProfile student;
  final int enrollmentCount;
  final String createdBy;
  final DateTime createdAt;

  const DuplicateStudentProfile({
    required this.duplicateId,
    required this.student,
    required this.enrollmentCount,
    required this.createdBy,
    required this.createdAt,
  });
}
