class ClassItem {
  final String id;
  final String title;
  final String teacher;
  final String level;
  final double rating;
  final num price;
  final String mode;

  const ClassItem({
    required this.id,
    required this.title,
    required this.teacher,
    required this.level,
    required this.rating,
    required this.price,
    required this.mode,
  });

  factory ClassItem.fromJson(Map<String, dynamic> map) => ClassItem(
        id: map['id'] as String,
        title: map['title'] as String,
        teacher: map['teacher'] as String,
        level: map['level'] as String,
        rating: (map['rating'] as num).toDouble(),
        price: map['price'] as num,
        mode: map['mode'] as String,
      );
}
