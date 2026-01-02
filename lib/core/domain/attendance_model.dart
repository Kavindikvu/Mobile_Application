enum AttendanceStatus {
  present,
  absent,
  late,
  excused;

  static AttendanceStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'PRESENT':
        return AttendanceStatus.present;
      case 'ABSENT':
        return AttendanceStatus.absent;
      case 'LATE':
        return AttendanceStatus.late;
      case 'EXCUSED':
        return AttendanceStatus.excused;
      default:
        return AttendanceStatus.absent;
    }
  }

  String toApiString() {
    switch (this) {
      case AttendanceStatus.present:
        return 'PRESENT';
      case AttendanceStatus.absent:
        return 'ABSENT';
      case AttendanceStatus.late:
        return 'LATE';
      case AttendanceStatus.excused:
        return 'EXCUSED';
    }
  }
}

enum AttendanceMarkingMethod {
  qrScan,
  manual,
  automatic;

  static AttendanceMarkingMethod fromString(String method) {
    switch (method.toUpperCase().replaceAll('_', '')) {
      case 'QRSCAN':
        return AttendanceMarkingMethod.qrScan;
      case 'MANUAL':
        return AttendanceMarkingMethod.manual;
      case 'AUTOMATIC':
        return AttendanceMarkingMethod.automatic;
      default:
        return AttendanceMarkingMethod.manual;
    }
  }
}

class Attendance {
  final String id;
  final String studentId;
  final String studentName;
  final String classId;
  final String className;
  final String subjectId;
  final String sessionId;
  final AttendanceStatus status;
  final AttendanceMarkingMethod markingMethod;
  final String? markedBy;
  final DateTime markedAt;
  final DateTime sessionDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;

  const Attendance({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.sessionId,
    required this.status,
    required this.markingMethod,
    this.markedBy,
    required this.markedAt,
    required this.sessionDate,
    this.notes,
    required this.createdAt,
    required this.lastUpdatedAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String? ?? '',
      classId: json['classId'] as String,
      className: json['className'] as String? ?? '',
      subjectId: json['subjectId'] as String,
      sessionId: json['sessionId'] as String,
      status: AttendanceStatus.fromString(json['status'] as String),
      markingMethod: json['markingMethod'] != null
          ? AttendanceMarkingMethod.fromString(json['markingMethod'] as String)
          : AttendanceMarkingMethod.manual,
      markedBy: json['markedBy'] as String?,
      markedAt: DateTime.parse(json['markedAt'] as String),
      sessionDate: DateTime.parse(json['sessionDate'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'classId': classId,
      'className': className,
      'subjectId': subjectId,
      'sessionId': sessionId,
      'status': status.toApiString(),
      'markingMethod': markingMethod.name.toUpperCase(),
      if (markedBy != null) 'markedBy': markedBy,
      'markedAt': markedAt.toIso8601String(),
      'sessionDate': sessionDate.toIso8601String(),
      if (notes != null) 'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
    };
  }

  Attendance copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? classId,
    String? className,
    String? subjectId,
    String? sessionId,
    AttendanceStatus? status,
    AttendanceMarkingMethod? markingMethod,
    String? markedBy,
    DateTime? markedAt,
    DateTime? sessionDate,
    String? notes,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
  }) {
    return Attendance(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      subjectId: subjectId ?? this.subjectId,
      sessionId: sessionId ?? this.sessionId,
      status: status ?? this.status,
      markingMethod: markingMethod ?? this.markingMethod,
      markedBy: markedBy ?? this.markedBy,
      markedAt: markedAt ?? this.markedAt,
      sessionDate: sessionDate ?? this.sessionDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  bool get isPresent => status == AttendanceStatus.present;
  bool get isAbsent => status == AttendanceStatus.absent;
  bool get isLate => status == AttendanceStatus.late;
  bool get isExcused => status == AttendanceStatus.excused;
}

class AttendanceSummary {
  final int totalSessions;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int excusedCount;
  final double attendancePercentage;

  const AttendanceSummary({
    required this.totalSessions,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.excusedCount,
    required this.attendancePercentage,
  });

  factory AttendanceSummary.fromAttendanceList(List<Attendance> attendances) {
    if (attendances.isEmpty) {
      return const AttendanceSummary(
        totalSessions: 0,
        presentCount: 0,
        absentCount: 0,
        lateCount: 0,
        excusedCount: 0,
        attendancePercentage: 0.0,
      );
    }

    final present = attendances.where((a) => a.isPresent).length;
    final absent = attendances.where((a) => a.isAbsent).length;
    final late = attendances.where((a) => a.isLate).length;
    final excused = attendances.where((a) => a.isExcused).length;
    final total = attendances.length;

    // Calculate percentage: (present + excused) / total * 100
    final percentage = total > 0
        ? ((present + excused) / total * 100).clamp(0.0, 100.0)
        : 0.0;

    return AttendanceSummary(
      totalSessions: total,
      presentCount: present,
      absentCount: absent,
      lateCount: late,
      excusedCount: excused,
      attendancePercentage: percentage,
    );
  }

  AttendanceSummary copyWith({
    int? totalSessions,
    int? presentCount,
    int? absentCount,
    int? lateCount,
    int? excusedCount,
    double? attendancePercentage,
  }) {
    return AttendanceSummary(
      totalSessions: totalSessions ?? this.totalSessions,
      presentCount: presentCount ?? this.presentCount,
      absentCount: absentCount ?? this.absentCount,
      lateCount: lateCount ?? this.lateCount,
      excusedCount: excusedCount ?? this.excusedCount,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
    );
  }
}

