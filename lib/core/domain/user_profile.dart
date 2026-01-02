enum UserRole {
  parent,
  student,
  teacher,
  admin,
}

enum UserStatus {
  active,
  inactive,
  suspended,
  pending,
}

class UserProfile {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? address;
  final String? profileImageUrl;
  final UserRole role;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? preferences;
  final List<String> childrenIds; // For parents
  final String? parentId; // For students
  final Map<String, dynamic>? academicInfo; // For students
  final Map<String, dynamic>? parentInfo; // For parents

  const UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.address,
    this.profileImageUrl,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.preferences,
    this.childrenIds = const [],
    this.parentId,
    this.academicInfo,
    this.parentInfo,
  });

  UserProfile copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profileImageUrl,
    String? address,
    UserRole? role,
    UserStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? preferences,
    List<String>? childrenIds,
    String? parentId,
    Map<String, dynamic>? academicInfo,
    Map<String, dynamic>? parentInfo,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
      childrenIds: childrenIds ?? this.childrenIds,
      parentId: parentId ?? this.parentId,
      academicInfo: academicInfo ?? this.academicInfo,
      parentInfo: parentInfo ?? this.parentInfo,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final roleValue = (json['role'] as String?)?.toLowerCase();
    final statusValue = (json['status'] as String?)?.toLowerCase();

    return UserProfile(
      id: (json['id'] ?? json['userId']) as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phoneNumber: (json['phoneNumber'] ?? json['mobileNumber']) as String?,
      address: json['address'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      role: UserRole.values.firstWhere(
        (role) => role.name.toLowerCase() == roleValue,
        orElse: () => UserRole.student,
      ),
      status: UserStatus.values.firstWhere(
        (status) => status.name.toLowerCase() == statusValue,
        orElse: () => UserStatus.active,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      preferences: json['preferences'] as Map<String, dynamic>?,
      childrenIds: (json['childrenIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      parentId: json['parentId'] as String?,
      academicInfo: json['academicInfo'] as Map<String, dynamic>?,
      parentInfo: json['parentInfo'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'address': address,
      'role': role.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'preferences': preferences,
      'childrenIds': childrenIds,
      'parentId': parentId,
      'academicInfo': academicInfo,
      'parentInfo': parentInfo,
    };
  }

  String get fullName => '$firstName $lastName';
  String get displayName => fullName;
  String get initials => '${firstName[0]}${lastName[0]}'.toUpperCase();
  bool get isParent => role == UserRole.parent;
  bool get isStudent => role == UserRole.student;
  bool get isTeacher => role == UserRole.teacher;
  bool get isAdmin => role == UserRole.admin;
  bool get isActive => status == UserStatus.active;
}

class AcademicInfo {
  final String studentId;
  final String grade;
  final String school;
  final double gpa;
  final List<String> subjects;
  final Map<String, double> subjectGrades;
  final int totalCredits;
  final int completedCredits;
  final List<String> achievements;
  final Map<String, dynamic>? additionalInfo;

  const AcademicInfo({
    required this.studentId,
    required this.grade,
    required this.school,
    required this.gpa,
    required this.subjects,
    required this.subjectGrades,
    required this.totalCredits,
    required this.completedCredits,
    required this.achievements,
    this.additionalInfo,
  });

  factory AcademicInfo.fromJson(Map<String, dynamic> json) {
    return AcademicInfo(
      studentId: json['studentId'] as String,
      grade: json['grade'] as String,
      school: json['school'] as String,
      gpa: (json['gpa'] as num).toDouble(),
      subjects:
          (json['subjects'] as List<dynamic>).map((e) => e as String).toList(),
      subjectGrades: (json['subjectGrades'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, (value as num).toDouble())),
      totalCredits: json['totalCredits'] as int,
      completedCredits: json['completedCredits'] as int,
      achievements: (json['achievements'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      additionalInfo: json['additionalInfo'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'grade': grade,
      'school': school,
      'gpa': gpa,
      'subjects': subjects,
      'subjectGrades': subjectGrades,
      'totalCredits': totalCredits,
      'completedCredits': completedCredits,
      'achievements': achievements,
      'additionalInfo': additionalInfo,
    };
  }

  double get progressPercentage =>
      totalCredits > 0 ? (completedCredits / totalCredits) * 100 : 0.0;
  String get gpaText => gpa.toStringAsFixed(2);
  bool get isHighAchiever => gpa >= 3.5;
}
