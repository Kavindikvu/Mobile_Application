class DashboardStats {
  final int activeClasses;
  final int pendingAssignments;
  final int unreadMessages;
  final int upcomingPayments;
  final double averageGrade;
  final double attendancePercentage;
  final int completedAssignments;

  const DashboardStats({
    required this.activeClasses,
    required this.pendingAssignments,
    required this.unreadMessages,
    required this.upcomingPayments,
    required this.averageGrade,
    required this.attendancePercentage,
    required this.completedAssignments,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      activeClasses: json['activeClasses'] as int? ?? 0,
      pendingAssignments: json['pendingAssignments'] as int? ?? 0,
      unreadMessages: json['unreadMessages'] as int? ?? 0,
      upcomingPayments: json['upcomingPayments'] as int? ?? 0,
      averageGrade: (json['averageGrade'] as num?)?.toDouble() ?? 0.0,
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
      completedAssignments: json['completedAssignments'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activeClasses': activeClasses,
      'pendingAssignments': pendingAssignments,
      'unreadMessages': unreadMessages,
      'upcomingPayments': upcomingPayments,
      'averageGrade': averageGrade,
      'attendancePercentage': attendancePercentage,
      'completedAssignments': completedAssignments,
    };
  }

  DashboardStats copyWith({
    int? activeClasses,
    int? pendingAssignments,
    int? unreadMessages,
    int? upcomingPayments,
    double? averageGrade,
    double? attendancePercentage,
    int? completedAssignments,
  }) {
    return DashboardStats(
      activeClasses: activeClasses ?? this.activeClasses,
      pendingAssignments: pendingAssignments ?? this.pendingAssignments,
      unreadMessages: unreadMessages ?? this.unreadMessages,
      upcomingPayments: upcomingPayments ?? this.upcomingPayments,
      averageGrade: averageGrade ?? this.averageGrade,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
      completedAssignments: completedAssignments ?? this.completedAssignments,
    );
  }
}
