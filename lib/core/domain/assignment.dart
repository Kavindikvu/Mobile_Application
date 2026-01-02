enum AssignmentStatus {
  notStarted,
  inProgress,
  submitted,
  graded,
  late,
  overdue,
}

enum AssignmentType {
  homework,
  project,
  quiz,
  exam,
  essay,
  lab,
  presentation,
}

class Assignment {
  final String id;
  final String title;
  final String description;
  final String classId;
  final String className;
  final String instructorName;
  final AssignmentType type;
  final AssignmentStatus status;
  final DateTime dueDate;
  final DateTime? submittedAt;
  final DateTime? gradedAt;
  final int totalPoints;
  final int? earnedPoints;
  final String? grade;
  final String? feedback;
  final List<String> attachments;
  final List<String> submissionAttachments;
  final String? submissionText;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const Assignment({
    required this.id,
    required this.title,
    required this.description,
    required this.classId,
    required this.className,
    required this.instructorName,
    required this.type,
    required this.status,
    required this.dueDate,
    this.submittedAt,
    this.gradedAt,
    required this.totalPoints,
    this.earnedPoints,
    this.grade,
    this.feedback,
    this.attachments = const [],
    this.submissionAttachments = const [],
    this.submissionText,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      classId: json['classId'] as String,
      className: json['className'] as String,
      instructorName: json['instructorName'] as String,
      type: AssignmentType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => AssignmentType.homework,
      ),
      status: AssignmentStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => AssignmentStatus.notStarted,
      ),
      dueDate: DateTime.parse(json['dueDate'] as String),
      submittedAt: json['submittedAt'] != null 
          ? DateTime.parse(json['submittedAt'] as String) 
          : null,
      gradedAt: json['gradedAt'] != null 
          ? DateTime.parse(json['gradedAt'] as String) 
          : null,
      totalPoints: json['totalPoints'] as int,
      earnedPoints: json['earnedPoints'] as int?,
      grade: json['grade'] as String?,
      feedback: json['feedback'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      submissionAttachments: (json['submissionAttachments'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      submissionText: json['submissionText'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'classId': classId,
      'className': className,
      'instructorName': instructorName,
      'type': type.name,
      'status': status.name,
      'dueDate': dueDate.toIso8601String(),
      'submittedAt': submittedAt?.toIso8601String(),
      'gradedAt': gradedAt?.toIso8601String(),
      'totalPoints': totalPoints,
      'earnedPoints': earnedPoints,
      'grade': grade,
      'feedback': feedback,
      'attachments': attachments,
      'submissionAttachments': submissionAttachments,
      'submissionText': submissionText,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  Assignment copyWith({
    String? id,
    String? title,
    String? description,
    String? classId,
    String? className,
    String? instructorName,
    AssignmentType? type,
    AssignmentStatus? status,
    DateTime? dueDate,
    DateTime? submittedAt,
    DateTime? gradedAt,
    int? totalPoints,
    int? earnedPoints,
    String? grade,
    String? feedback,
    List<String>? attachments,
    List<String>? submissionAttachments,
    String? submissionText,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Assignment(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      instructorName: instructorName ?? this.instructorName,
      type: type ?? this.type,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      submittedAt: submittedAt ?? this.submittedAt,
      gradedAt: gradedAt ?? this.gradedAt,
      totalPoints: totalPoints ?? this.totalPoints,
      earnedPoints: earnedPoints ?? this.earnedPoints,
      grade: grade ?? this.grade,
      feedback: feedback ?? this.feedback,
      attachments: attachments ?? this.attachments,
      submissionAttachments: submissionAttachments ?? this.submissionAttachments,
      submissionText: submissionText ?? this.submissionText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isOverdue => DateTime.now().isAfter(dueDate) && status != AssignmentStatus.submitted && status != AssignmentStatus.graded;
  bool get isDueSoon => DateTime.now().add(const Duration(days: 1)).isAfter(dueDate) && !isOverdue && status != AssignmentStatus.submitted && status != AssignmentStatus.graded;
  bool get isGraded => status == AssignmentStatus.graded;
  bool get isSubmitted => status == AssignmentStatus.submitted || status == AssignmentStatus.graded;
  bool get canSubmit => status == AssignmentStatus.notStarted || status == AssignmentStatus.inProgress;
  
  String get statusText {
    switch (status) {
      case AssignmentStatus.notStarted:
        return 'Not Started';
      case AssignmentStatus.inProgress:
        return 'In Progress';
      case AssignmentStatus.submitted:
        return 'Submitted';
      case AssignmentStatus.graded:
        return 'Graded';
      case AssignmentStatus.late:
        return 'Late';
      case AssignmentStatus.overdue:
        return 'Overdue';
    }
  }

  String get typeText {
    switch (type) {
      case AssignmentType.homework:
        return 'Homework';
      case AssignmentType.project:
        return 'Project';
      case AssignmentType.quiz:
        return 'Quiz';
      case AssignmentType.exam:
        return 'Exam';
      case AssignmentType.essay:
        return 'Essay';
      case AssignmentType.lab:
        return 'Lab';
      case AssignmentType.presentation:
        return 'Presentation';
    }
  }

  String get dueDateText {
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    
    if (difference.inDays > 0) {
      return 'Due in ${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
    } else if (difference.inHours > 0) {
      return 'Due in ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inMinutes > 0) {
      return 'Due in ${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'}';
    } else if (isOverdue) {
      return 'Overdue by ${now.difference(dueDate).inDays} day${now.difference(dueDate).inDays == 1 ? '' : 's'}';
    } else {
      return 'Due now';
    }
  }

  double get progressPercentage {
    switch (status) {
      case AssignmentStatus.notStarted:
        return 0.0;
      case AssignmentStatus.inProgress:
        return 0.5; // This could be calculated based on actual progress
      case AssignmentStatus.submitted:
        return 1.0;
      case AssignmentStatus.graded:
        return 1.0;
      case AssignmentStatus.late:
        return 1.0;
      case AssignmentStatus.overdue:
        return 0.0;
    }
  }
}
