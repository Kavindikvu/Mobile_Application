import 'package:flutter/material.dart';

enum NotificationType {
  assignment,
  grade,
  attendance,
  message,
  payment,
  system,
  reminder,
  achievement,
}

enum NotificationPriority {
  low,
  medium,
  high,
  urgent,
}

enum NotificationStatus {
  unread,
  read,
  archived,
  deleted,
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final NotificationStatus status;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? data;
  final String? actionUrl;
  final String? imageUrl;
  final String? senderId;
  final String? senderName;
  final String? relatedEntityId; // ID of related assignment, class, etc.
  final String? relatedEntityType; // Type of related entity

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.readAt,
    this.data,
    this.actionUrl,
    this.imageUrl,
    this.senderId,
    this.senderName,
    this.relatedEntityId,
    this.relatedEntityType,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: NotificationType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => NotificationType.system,
      ),
      priority: NotificationPriority.values.firstWhere(
        (priority) => priority.name == json['priority'],
        orElse: () => NotificationPriority.medium,
      ),
      status: NotificationStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => NotificationStatus.unread,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] != null 
          ? DateTime.parse(json['readAt'] as String) 
          : null,
      data: json['data'] as Map<String, dynamic>?,
      actionUrl: json['actionUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      senderId: json['senderId'] as String?,
      senderName: json['senderName'] as String?,
      relatedEntityId: json['relatedEntityId'] as String?,
      relatedEntityType: json['relatedEntityType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'priority': priority.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'data': data,
      'actionUrl': actionUrl,
      'imageUrl': imageUrl,
      'senderId': senderId,
      'senderName': senderName,
      'relatedEntityId': relatedEntityId,
      'relatedEntityType': relatedEntityType,
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    NotificationPriority? priority,
    NotificationStatus? status,
    DateTime? createdAt,
    DateTime? readAt,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? imageUrl,
    String? senderId,
    String? senderName,
    String? relatedEntityId,
    String? relatedEntityType,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      data: data ?? this.data,
      actionUrl: actionUrl ?? this.actionUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
    );
  }

  bool get isUnread => status == NotificationStatus.unread;
  bool get isRead => status == NotificationStatus.read;
  bool get isArchived => status == NotificationStatus.archived;
  bool get isDeleted => status == NotificationStatus.deleted;
  
  String get timeText => _formatTime(createdAt);
  String get priorityText => priority.name.toUpperCase();
  
  IconData get typeIcon {
    switch (type) {
      case NotificationType.assignment:
        return Icons.assignment;
      case NotificationType.grade:
        return Icons.grade;
      case NotificationType.attendance:
        return Icons.person_pin;
      case NotificationType.message:
        return Icons.message;
      case NotificationType.payment:
        return Icons.payment;
      case NotificationType.system:
        return Icons.info;
      case NotificationType.reminder:
        return Icons.schedule;
      case NotificationType.achievement:
        return Icons.emoji_events;
    }
  }

  Color get priorityColor {
    switch (priority) {
      case NotificationPriority.low:
        return const Color(0xFF4CAF50); // Green
      case NotificationPriority.medium:
        return const Color(0xFF2196F3); // Blue
      case NotificationPriority.high:
        return const Color(0xFFFF9800); // Orange
      case NotificationPriority.urgent:
        return const Color(0xFFF44336); // Red
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }
}

class NotificationSettings {
  final String userId;
  final Map<NotificationType, bool> typeSettings;
  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final bool quietHoursEnabled;
  final TimeOfDay? quietHoursStart;
  final TimeOfDay? quietHoursEnd;
  final List<String> mutedSenders;
  final DateTime updatedAt;

  const NotificationSettings({
    required this.userId,
    required this.typeSettings,
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.smsEnabled = false,
    this.quietHoursEnabled = false,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.mutedSenders = const [],
    required this.updatedAt,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      userId: json['userId'] as String,
      typeSettings: (json['typeSettings'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(
                NotificationType.values.firstWhere(
                  (type) => type.name == key,
                  orElse: () => NotificationType.system,
                ),
                value as bool,
              )),
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      emailEnabled: json['emailEnabled'] as bool? ?? true,
      smsEnabled: json['smsEnabled'] as bool? ?? false,
      quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? false,
      quietHoursStart: json['quietHoursStart'] != null
          ? TimeOfDay.fromDateTime(DateTime.parse(json['quietHoursStart'] as String))
          : null,
      quietHoursEnd: json['quietHoursEnd'] != null
          ? TimeOfDay.fromDateTime(DateTime.parse(json['quietHoursEnd'] as String))
          : null,
      mutedSenders: (json['mutedSenders'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'typeSettings': typeSettings.map((key, value) => MapEntry(key.name, value)),
      'pushEnabled': pushEnabled,
      'emailEnabled': emailEnabled,
      'smsEnabled': smsEnabled,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': quietHoursStart?.toDateTime().toIso8601String(),
      'quietHoursEnd': quietHoursEnd?.toDateTime().toIso8601String(),
      'mutedSenders': mutedSenders,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  NotificationSettings copyWith({
    String? userId,
    Map<NotificationType, bool>? typeSettings,
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
    bool? quietHoursEnabled,
    TimeOfDay? quietHoursStart,
    TimeOfDay? quietHoursEnd,
    List<String>? mutedSenders,
    DateTime? updatedAt,
  }) {
    return NotificationSettings(
      userId: userId ?? this.userId,
      typeSettings: typeSettings ?? this.typeSettings,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      mutedSenders: mutedSenders ?? this.mutedSenders,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool isTypeEnabled(NotificationType type) {
    return typeSettings[type] ?? true;
  }

  bool isSenderMuted(String senderId) {
    return mutedSenders.contains(senderId);
  }

  bool isInQuietHours() {
    if (!quietHoursEnabled || quietHoursStart == null || quietHoursEnd == null) {
      return false;
    }
    
    final now = TimeOfDay.now();
    final start = quietHoursStart!;
    final end = quietHoursEnd!;
    
    // Handle case where quiet hours span midnight
    if (start.hour > end.hour) {
      return now.hour >= start.hour || now.hour < end.hour;
    } else {
      return now.hour >= start.hour && now.hour < end.hour;
    }
  }
}

extension TimeOfDayExtension on TimeOfDay {
  DateTime toDateTime() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }
}