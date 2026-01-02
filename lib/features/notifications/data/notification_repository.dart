import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/asset_data_provider.dart';
import '../../../../core/domain/notification.dart';

final assetDataProviderProvider = Provider<AssetDataProvider>((ref) => const AssetDataProvider());

class NotificationRepository {
  const NotificationRepository(this._assetDataProvider);

  final AssetDataProvider _assetDataProvider;

  Future<List<AppNotification>> getNotifications() async {
    try {
      final data = await _assetDataProvider.loadList('assets/data/notifications.json');
      return data.map((json) => AppNotification.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load notifications: $e');
    }
  }

  Future<List<AppNotification>> getNotificationsByType(NotificationType type) async {
    try {
      final notifications = await getNotifications();
      return notifications.where((n) => n.type == type).toList();
    } catch (e) {
      throw Exception('Failed to load notifications by type: $e');
    }
  }

  Future<List<AppNotification>> getUnreadNotifications() async {
    try {
      final notifications = await getNotifications();
      return notifications.where((n) => n.isUnread).toList();
    } catch (e) {
      throw Exception('Failed to load unread notifications: $e');
    }
  }

  Future<NotificationSettings> getNotificationSettings(String userId) async {
    try {
      final data = await _assetDataProvider.loadMap('assets/data/notification_settings.json');
      return NotificationSettings.fromJson(data);
    } catch (e) {
      throw Exception('Failed to load notification settings: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    // TODO: Implement mark as read functionality
    // This would typically update the backend
  }

  Future<void> markAllAsRead() async {
    // TODO: Implement mark all as read functionality
    // This would typically update the backend
  }

  Future<void> archiveNotification(String notificationId) async {
    // TODO: Implement archive notification functionality
    // This would typically update the backend
  }

  Future<void> deleteNotification(String notificationId) async {
    // TODO: Implement delete notification functionality
    // This would typically update the backend
  }

  Future<void> updateNotificationSettings(NotificationSettings settings) async {
    // TODO: Implement update notification settings functionality
    // This would typically update the backend
  }

  Future<void> sendNotification(AppNotification notification) async {
    // TODO: Implement send notification functionality
    // This would typically send to backend and trigger push notification
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final assetDataProvider = ref.watch(assetDataProviderProvider);
  return NotificationRepository(assetDataProvider);
});

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getNotifications();
});

final unreadNotificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getUnreadNotifications();
});

final notificationsByTypeProvider = FutureProvider.family<List<AppNotification>, NotificationType>((ref, type) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getNotificationsByType(type);
});

final notificationSettingsProvider = FutureProvider.family<NotificationSettings, String>((ref, userId) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getNotificationSettings(userId);
});
