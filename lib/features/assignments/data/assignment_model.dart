class AssignmentItem {
  final String id;
  final String title;
  final String subject;
  final DateTime dueDate;
  final String status;

  const AssignmentItem({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    required this.status,
  });

  factory AssignmentItem.fromJson(Map<String, dynamic> map) => AssignmentItem(
        id: map['id'] as String,
        title: map['title'] as String,
        subject: map['subject'] as String,
        dueDate: DateTime.parse(map['dueDate'] as String),
        status: map['status'] as String,
      );
}
