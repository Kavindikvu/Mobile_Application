import '../../providers/logger_provider.dart';

/// API response model for Class from class-service
class ApiClassModel {
  final String id;
  final String name;
  final List<ApiSchedule> schedules;
  final double fees;
  final String privacyLevel;
  final ApiLocation? location;
  final List<String> homeVisitCities;
  final String medium;
  final String? posterUrl;
  final String teacherId;
  final String? calendarId;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;

  ApiClassModel({
    required this.id,
    required this.name,
    required this.schedules,
    required this.fees,
    required this.privacyLevel,
    this.location,
    required this.homeVisitCities,
    required this.medium,
    this.posterUrl,
    required this.teacherId,
    this.calendarId,
    required this.createdAt,
    required this.lastUpdatedAt,
  });

  factory ApiClassModel.fromJson(Map<String, dynamic> json) {
    // Parse schedules with defensive type checking
    final List<ApiSchedule> parsedSchedules = [];
    final schedulesList = json['schedules'] as List<dynamic>?;
    
    if (schedulesList != null) {
      for (int i = 0; i < schedulesList.length; i++) {
        final item = schedulesList[i];
        if (item is Map<String, dynamic>) {
          try {
            parsedSchedules.add(ApiSchedule.fromJson(item));
          } catch (e, stackTrace) {
            AppLogger.warning(
              'Failed to parse schedule at index $i',
              error: e,
              stackTrace: stackTrace,
              context: {
                'classId': json['id'] as String?,
                'scheduleIndex': i,
                'scheduleData': item.toString(),
              },
            );
            // Continue parsing other schedules
          }
        } else {
          AppLogger.warning(
            'Invalid schedule type at index $i: expected Map, got ${item.runtimeType}',
            context: {
              'classId': json['id'] as String?,
              'scheduleIndex': i,
              'itemType': item.runtimeType.toString(),
            },
          );
        }
      }
    }
    
    return ApiClassModel(
      id: json['id'] as String,
      name: json['name'] as String,
      schedules: parsedSchedules,
      fees: (json['fees'] as num).toDouble(),
      privacyLevel: json['privacyLevel'] as String? ?? 'PUBLIC',
      location: json['location'] != null
          ? ApiLocation.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      homeVisitCities:
          (json['homeVisitCities'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      medium: json['medium'] as String? ?? 'ENGLISH',
      posterUrl: json['posterUrl'] as String?,
      teacherId: json['teacherId'] as String,
      calendarId: json['calendarId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'schedules': schedules.map<Map<String, dynamic>>((e) => e.toJson()).toList(),
      'fees': fees,
      'privacyLevel': privacyLevel,
      'location': location?.toJson(),
      'homeVisitCities': homeVisitCities,
      'medium': medium,
      'posterUrl': posterUrl,
      'teacherId': teacherId,
      'calendarId': calendarId,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
    };
  }
}

class ApiSchedule {
  final String id;
  final String type; // ONE_TIME, RECURRING
  final String? date;
  final String? startDate;
  final String? endDate;
  final List<String>? daysOfWeek;
  final int? weekOfMonth;
  final ApiTimeOfDay? startTime;
  final ApiTimeOfDay? endTime;
  final String? frequency; // DAILY, WEEKLY, MONTHLY, YEARLY
  final String? subjectId;
  final String? createdAt;
  final String? lastUpdatedAt;

  ApiSchedule({
    required this.id,
    required this.type,
    this.date,
    this.startDate,
    this.endDate,
    this.daysOfWeek,
    this.weekOfMonth,
    this.startTime,
    this.endTime,
    this.frequency,
    this.subjectId,
    this.createdAt,
    this.lastUpdatedAt,
  });

  factory ApiSchedule.fromJson(Map<String, dynamic> json) {
    // Parse startTime - handle both string (HH:mm) and object formats
    ApiTimeOfDay? startTime;
    if (json['startTime'] != null) {
      try {
        if (json['startTime'] is String) {
          // Parse string format "HH:mm"
          startTime = ApiTimeOfDay.fromTimeString(json['startTime'] as String);
        } else if (json['startTime'] is Map<String, dynamic>) {
          startTime = ApiTimeOfDay.fromJson(json['startTime'] as Map<String, dynamic>);
        }
      } catch (e, stackTrace) {
        AppLogger.warning(
          'Failed to parse startTime',
          error: e,
          stackTrace: stackTrace,
          context: {'startTimeValue': json['startTime'].toString()},
        );
      }
    }
    
    // Parse endTime - handle both string (HH:mm) and object formats
    ApiTimeOfDay? endTime;
    if (json['endTime'] != null) {
      try {
        if (json['endTime'] is String) {
          // Parse string format "HH:mm"
          endTime = ApiTimeOfDay.fromTimeString(json['endTime'] as String);
        } else if (json['endTime'] is Map<String, dynamic>) {
          endTime = ApiTimeOfDay.fromJson(json['endTime'] as Map<String, dynamic>);
        }
      } catch (e, stackTrace) {
        AppLogger.warning(
          'Failed to parse endTime',
          error: e,
          stackTrace: stackTrace,
          context: {'endTimeValue': json['endTime'].toString()},
        );
      }
    }
    
    return ApiSchedule(
      id: json['scheduleId'] as String? ?? json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'ONE_TIME',
      date: json['date'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      weekOfMonth: json['weekOfMonth'] as int?,
      startTime: startTime,
      endTime: endTime,
      frequency: json['frequency'] as String?,
      subjectId: json['subjectId'] as String?,
      createdAt: json['createdAt'] as String?,
      lastUpdatedAt: json['lastUpdatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'date': date,
      'startDate': startDate,
      'endDate': endDate,
      'daysOfWeek': daysOfWeek,
      'weekOfMonth': weekOfMonth,
      'startTime': startTime?.toJson(),
      'endTime': endTime?.toJson(),
      'frequency': frequency,
      'subjectId': subjectId,
      'createdAt': createdAt,
      'lastUpdatedAt': lastUpdatedAt,
    };
  }

  String formatTime() {
    if (startTime == null || endTime == null) return '';
    final start = '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}';
    final end = '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }

  String formatSchedule() {
    if (type == 'ONE_TIME' && date != null) {
      final formattedTime = formatTime();
      return '$date $formattedTime';
    } else if (type == 'RECURRING' && daysOfWeek != null && daysOfWeek!.isNotEmpty) {
      final days = daysOfWeek!.join(', ');
      final formattedTime = formatTime();
      return '$days $formattedTime';
    }
    return formatTime();
  }
}

class ApiTimeOfDay {
  final int hour;
  final int minute;
  final int second;
  final int nano;

  ApiTimeOfDay({
    required this.hour,
    required this.minute,
    this.second = 0,
    this.nano = 0,
  });

  factory ApiTimeOfDay.fromJson(Map<String, dynamic> json) {
    return ApiTimeOfDay(
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      second: json['second'] as int? ?? 0,
      nano: json['nano'] as int? ?? 0,
    );
  }
  
  /// Parse time from string format "HH:mm" or "HH:mm:ss"
  factory ApiTimeOfDay.fromTimeString(String timeString) {
    final parts = timeString.split(':');
    if (parts.length < 2) {
      throw FormatException('Invalid time format: $timeString. Expected HH:mm or HH:mm:ss');
    }
    
    return ApiTimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
      second: parts.length > 2 ? int.parse(parts[2]) : 0,
      nano: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'minute': minute,
      'second': second,
      'nano': nano,
    };
  }
}

class ApiLocation {
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final double? latitude;
  final double? longitude;

  ApiLocation({
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.latitude,
    this.longitude,
  });

  factory ApiLocation.fromJson(Map<String, dynamic> json) {
    return ApiLocation(
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      postalCode: json['postalCode'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  String get displayAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    return parts.join(', ');
  }
}

