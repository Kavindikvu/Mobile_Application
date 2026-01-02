enum EnrollmentStatus {
  pending,
  approved,
  rejected,
  cancelled;

  static EnrollmentStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return EnrollmentStatus.pending;
      case 'APPROVED':
        return EnrollmentStatus.approved;
      case 'REJECTED':
        return EnrollmentStatus.rejected;
      case 'CANCELLED':
        return EnrollmentStatus.cancelled;
      default:
        return EnrollmentStatus.pending;
    }
  }

  String toApiString() {
    switch (this) {
      case EnrollmentStatus.pending:
        return 'PENDING';
      case EnrollmentStatus.approved:
        return 'APPROVED';
      case EnrollmentStatus.rejected:
        return 'REJECTED';
      case EnrollmentStatus.cancelled:
        return 'CANCELLED';
    }
  }
}

class Enrollment {
  final String id;
  final String studentId;
  final String classId;
  final String subjectId;
  final EnrollmentStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;

  const Enrollment({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.subjectId,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    required this.lastUpdatedAt,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    return Enrollment(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      classId: json['classId'] as String,
      subjectId: json['subjectId'] as String,
      status: EnrollmentStatus.fromString(json['status'] as String),
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'classId': classId,
      'subjectId': subjectId,
      'status': status.toApiString(),
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
    };
  }

  Enrollment copyWith({
    String? id,
    String? studentId,
    String? classId,
    String? subjectId,
    EnrollmentStatus? status,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
  }) {
    return Enrollment(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      subjectId: subjectId ?? this.subjectId,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  bool get isPending => status == EnrollmentStatus.pending;
  bool get isApproved => status == EnrollmentStatus.approved;
  bool get isRejected => status == EnrollmentStatus.rejected;
  bool get isCancelled => status == EnrollmentStatus.cancelled;
}

