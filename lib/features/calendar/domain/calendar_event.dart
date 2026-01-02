import 'package:meta/meta.dart';

@immutable
class CalendarEvent {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? childId;
  final String? classId;
  final String? location;
  final String? description;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.childId,
    this.classId,
    this.location,
    this.description,
  });

  bool overlaps(CalendarEvent other) {
    return startTime.isBefore(other.endTime) && endTime.isAfter(other.startTime);
  }
}


