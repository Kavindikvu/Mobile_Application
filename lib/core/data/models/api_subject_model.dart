/// API response model for Subject from subject-service
class ApiSubjectModel {
  final String subjectId;
  final String name;
  final String classId;
  final String? teacherId;
  final String? createdAt;
  final String? updatedAt;

  ApiSubjectModel({
    required this.subjectId,
    required this.name,
    required this.classId,
    this.teacherId,
    this.createdAt,
    this.updatedAt,
  });

  factory ApiSubjectModel.fromJson(Map<String, dynamic> json) {
    return ApiSubjectModel(
      subjectId: json['subjectId'] as String,
      name: json['name'] as String,
      classId: json['classId'] as String,
      teacherId: json['teacherId'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subjectId': subjectId,
      'name': name,
      'classId': classId,
      'teacherId': teacherId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

