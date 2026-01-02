import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/dashboard_stats.dart';
import '../domain/notification.dart';
import '../providers/auth_provider.dart';
import 'logger_provider.dart';

const _emptyStats = DashboardStats(
  activeClasses: 0,
  pendingAssignments: 0,
  unreadMessages: 0,
  upcomingPayments: 0,
  averageGrade: 0,
  attendancePercentage: 0,
  completedAssignments: 0,
);

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return _emptyStats;
  }

  try {
    // TODO: integrate dashboard API once available.
    return _emptyStats;
  } catch (e, stackTrace) {
    AppLogger.error(
      'Failed to load dashboard stats',
      error: e,
      stackTrace: stackTrace,
    );
    return _emptyStats;
  }
});

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return const [];
  }

  try {
    // TODO: integrate notifications API once available.
    return const [];
  } catch (e, stackTrace) {
    AppLogger.error(
      'Failed to load notifications',
      error: e,
      stackTrace: stackTrace,
    );
    return const [];
  }
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.when(
    data: (items) => items.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
