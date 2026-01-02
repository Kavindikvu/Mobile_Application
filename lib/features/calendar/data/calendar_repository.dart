import 'package:flutter/foundation.dart';
import 'package:riverpod/riverpod.dart';
import '../../../core/data/asset_data_provider.dart';
import '../domain/calendar_event.dart';

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepository(const AssetDataProvider());
});

class CalendarRepository {
  final AssetDataProvider assetDataProvider;
  static const String _classesAsset = 'assets/data/classes.json';
  static const String _assignmentsAsset = 'assets/data/assignments.json';

  const CalendarRepository(this.assetDataProvider);

  Future<List<CalendarEvent>> getEvents({String? childId}) async {
    final classes = await assetDataProvider.loadList(_classesAsset);
    final assignments = await assetDataProvider.loadList(_assignmentsAsset);

    final List<CalendarEvent> events = [];

    // Map simple class sessions as recurring weekly placeholders within course range
    for (final c in classes) {
      try {
        final startDate = DateTime.parse(c['startDate']);
        final endDate = DateTime.parse(c['endDate']);
        final schedule = (c['schedule'] as List).cast<String>();

        // Create sample instances in the current month for demo purposes
        for (final slot in schedule) {
          // slot example: "Monday 10:00 AM"
          final parts = slot.split(' ');
          if (parts.length < 2) continue;
          final dayName = parts.first;
          final timeStr = parts.sublist(1).join(' ');

          final weekday = _weekdayFromName(dayName);
          final now = DateTime.now();
          final firstOfMonth = DateTime(now.year, now.month, 1);
          final lastOfMonth = DateTime(now.year, now.month + 1, 0);

          // iterate days of month and create events on matching weekdays
          for (int d = 0; d < lastOfMonth.day; d++) {
            final date = firstOfMonth.add(Duration(days: d));
            if (date.weekday != weekday) continue;
            if (date.isBefore(startDate) || date.isAfter(endDate)) continue;
            final time = _parseTimeOfDay(timeStr);
            if (time == null) continue;
            final start = DateTime(date.year, date.month, date.day, time.$1, time.$2);
            final end = start.add(const Duration(hours: 1));
            events.add(CalendarEvent(
              id: 'class_${c['id']}_${start.toIso8601String()}',
              title: c['title'] as String,
              startTime: start,
              endTime: end,
              classId: c['id'] as String,
              location: c['location'] as String?,
              description: c['description'] as String?,
            ));
          }
        }
      } catch (_) {
        // ignore malformed entries in demo
      }
    }

    // Map assignments as due-date events
    for (final a in assignments) {
      try {
        final due = DateTime.parse(a['dueDate']);
        events.add(CalendarEvent(
          id: 'assignment_${a['id']}',
          title: a['title'] as String,
          startTime: due.subtract(const Duration(minutes: 30)),
          endTime: due,
          classId: a['classId'] as String?,
          description: a['description'] as String?,
        ));
      } catch (_) {
        // ignore
      }
    }

    events.sort((a, b) => a.startTime.compareTo(b.startTime));
    return events;
  }

  List<(CalendarEvent, CalendarEvent)> detectConflicts(List<CalendarEvent> events) {
    final List<(CalendarEvent, CalendarEvent)> conflicts = [];
    for (int i = 0; i < events.length; i++) {
      for (int j = i + 1; j < events.length; j++) {
        if (events[i].overlaps(events[j])) {
          conflicts.add((events[i], events[j]));
        }
      }
    }
    return conflicts;
  }

  static int _weekdayFromName(String name) {
    switch (name.toLowerCase()) {
      case 'monday':
        return DateTime.monday;
      case 'tuesday':
        return DateTime.tuesday;
      case 'wednesday':
        return DateTime.wednesday;
      case 'thursday':
        return DateTime.thursday;
      case 'friday':
        return DateTime.friday;
      case 'saturday':
        return DateTime.saturday;
      case 'sunday':
        return DateTime.sunday;
      default:
        return DateTime.monday;
    }
  }

  static (int, int)? _parseTimeOfDay(String time) {
    // very simple parser for examples like "10:00 AM"
    try {
      final parts = time.trim().split(' ');
      final hm = parts.first.split(':');
      var hour = int.parse(hm[0]);
      final minute = int.parse(hm[1]);
      final ampm = parts.length > 1 ? parts[1].toUpperCase() : 'AM';
      if (ampm == 'PM' && hour != 12) hour += 12;
      if (ampm == 'AM' && hour == 12) hour = 0;
      return (hour, minute);
    } catch (_) {
      return null;
    }
  }
}


