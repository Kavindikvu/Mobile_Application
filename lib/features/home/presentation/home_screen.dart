import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/domain/dashboard_stats.dart';
import '../../../../core/domain/notification.dart';
import '../../../../core/domain/user_profile.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/dashboard_provider.dart';
import '../../../../core/theme/tokens.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final selectedChild = ref.watch(selectedChildProvider);
    final dashboardStats = ref.watch(dashboardStatsProvider);
    final notifications = ref.watch(notificationsProvider);
    final formattedDate = DateFormat('EEEE, MMM d').format(DateTime.now());

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(notificationsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DashboardHeader(
              greeting: _greetingForTimeOfDay(),
              userName: user.displayName,
              formattedDate: formattedDate,
              childName: selectedChild?.displayName,
              userRole: user.role,
            ),
            const SizedBox(height: AppSpacing.md),
            dashboardStats.when(
              data: (stats) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TodayAtAGlanceSection(
                    stats: stats,
                    userRole: user.role,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _QuickStatsSection(stats: stats, userRole: user.role),
                ],
              ),
              loading: () => const _LoadingStatsSection(),
              error: (error, _) => _ErrorSection(error: error.toString()),
            ),
            const SizedBox(height: AppSpacing.lg),
            _TodayScheduleSection(),
            const SizedBox(height: AppSpacing.lg),
            notifications.when(
              data: (list) => _RecentNotificationsSection(
                  notifications: list.take(2).toList()),
              loading: () => const _LoadingNotificationsSection(),
              error: (error, _) => _ErrorSection(error: error.toString()),
            ),
            const SizedBox(height: AppSpacing.lg),
            _QuickActionsSection(userRole: user.role),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String greeting;
  final String userName;
  final String formattedDate;
  final String? childName;
  final UserRole userRole;

  const _DashboardHeader({
    required this.greeting,
    required this.userName,
    required this.formattedDate,
    required this.childName,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceTint = theme.colorScheme.primaryContainer.withOpacity(0.35);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formattedDate,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            color: surfaceTint,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(0.12),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, $userName',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      userRole == UserRole.parent && childName != null
                          ? 'Viewing $childName\'s dashboard'
                          : 'Here\'s what\'s happening today',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.tonal(
                onPressed: () => context.go('/profile'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.dashboard_customize, size: 18),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      'Dashboard',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TodayAtAGlanceSection extends StatelessWidget {
  final DashboardStats stats;
  final UserRole userRole;

  const _TodayAtAGlanceSection({
    required this.stats,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _buildItems();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today at a glance',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: items
              .map(
                (item) => _GlancePill(
                  emoji: item.emoji,
                  title: item.title,
                  message: item.subtitle,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  List<_GlanceItem> _buildItems() {
    if (userRole == UserRole.parent) {
      return [
        _GlanceItem(
          emoji: '📝',
          title: 'Assignments',
          subtitle: stats.pendingAssignments > 0
              ? '${stats.pendingAssignments} pending'
              : 'All caught up',
        ),
        _GlanceItem(
          emoji: '💬',
          title: 'Messages',
          subtitle: stats.unreadMessages > 0
              ? '${stats.unreadMessages} unread'
              : 'Inbox is clear',
        ),
        _GlanceItem(
          emoji: '💳',
          title: 'Payments',
          subtitle: stats.upcomingPayments > 0
              ? '${stats.upcomingPayments} upcoming'
              : 'No dues today',
        ),
      ];
    }

    return [
      _GlanceItem(
        emoji: '✅',
        title: 'Assignments',
        subtitle: stats.completedAssignments > 0
            ? '${stats.completedAssignments} completed'
            : 'Start your first task',
      ),
      _GlanceItem(
        emoji: '⭐',
        title: 'Average grade',
        subtitle:
            stats.averageGrade > 0 ? '${stats.averageGrade.toStringAsFixed(1)} GPA' : 'Keep working!',
      ),
      _GlanceItem(
        emoji: '📊',
        title: 'Attendance',
        subtitle: stats.attendancePercentage > 0
            ? '${stats.attendancePercentage.toInt()}% this week'
            : 'Attendance tracking soon',
      ),
    ];
  }
}

class _GlancePill extends StatelessWidget {
  final String emoji;
  final String title;
  final String message;

  const _GlancePill({
    required this.emoji,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlanceItem {
  final String emoji;
  final String title;
  final String subtitle;

  const _GlanceItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });
}

String _greetingForTimeOfDay() {
  final hour = DateTime.now().hour;
  if (hour < 12) {
    return 'Good morning';
  } else if (hour < 17) {
    return 'Good afternoon';
  } else {
    return 'Good evening';
  }
}

class _QuickStatsSection extends StatelessWidget {
  final DashboardStats stats;
  final UserRole userRole;

  const _QuickStatsSection({
    required this.stats,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userRole == UserRole.parent ? 'Quick Stats' : 'My Progress',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (userRole == UserRole.parent) ...[
              _StatItem(
                icon: '📚',
                label: 'Active Classes',
                value: stats.activeClasses.toString(),
                helperText: stats.activeClasses == 0
                    ? 'Browse classes to get started'
                    : 'Keep the momentum going',
              ),
              _StatItem(
                icon: '📝',
                label: 'Pending Assignments',
                value: stats.pendingAssignments.toString(),
                helperText: stats.pendingAssignments == 0
                    ? 'Nothing needs attention'
                    : 'Let\'s review today',
              ),
              _StatItem(
                icon: '💬',
                label: 'Unread Messages',
                value: stats.unreadMessages.toString(),
                helperText: stats.unreadMessages == 0
                    ? 'Inbox is all clear'
                    : 'Catch up on new updates',
              ),
              _StatItem(
                icon: '💳',
                label: 'Upcoming Payments',
                value: stats.upcomingPayments.toString(),
                helperText: stats.upcomingPayments == 0
                    ? 'No dues for now'
                    : 'Plan ahead for payments',
              ),
            ] else ...[
              _StatItem(
                icon: '📚',
                label: 'Enrolled Classes',
                value: stats.activeClasses.toString(),
                helperText: stats.activeClasses == 0
                    ? 'Add a class to begin'
                    : 'Stay curious!',
              ),
              _StatItem(
                icon: '✅',
                label: 'Completed Assignments',
                value: stats.completedAssignments.toString(),
                helperText: stats.completedAssignments == 0
                    ? 'Complete your first assignment'
                    : 'Nice work! Keep it up',
              ),
              _StatItem(
                icon: '⭐',
                label: 'Average Grade',
                value: _formatGrade(stats.averageGrade),
                helperText: stats.averageGrade == 0
                    ? 'Grades will appear here'
                    : 'Track your progress',
              ),
              _StatItem(
                icon: '📊',
                label: 'Attendance',
                value: '${stats.attendancePercentage.toInt()}%',
                helperText: stats.attendancePercentage == 0
                    ? 'We\'ll start tracking soon'
                    : 'Aim for 95%+ attendance',
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatGrade(double grade) {
    if (grade == 0) return 'N/A';
    return grade.toStringAsFixed(1);
  }
}

class _StatItem extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final String? helperText;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
          if (helperText != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              helperText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TodayScheduleSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Schedule',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            _ScheduleItem(
              time: '10:00 AM',
              subject: 'Math Class',
              location: 'Room 101',
              isNext: true,
            ),
            const Divider(height: 16),
            _ScheduleItem(
              time: '2:00 PM',
              subject: 'Science Lab',
              location: 'Lab 2',
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'All classes wrapped for today',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleItem extends StatelessWidget {
  final String time;
  final String subject;
  final String location;
  final bool isNext;

  const _ScheduleItem({
    required this.time,
    required this.subject,
    required this.location,
    this.isNext = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              time,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        location,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isNext) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.12),
                        ),
                        child: Text(
                          'Up next',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentNotificationsSection extends StatelessWidget {
  final List<AppNotification> notifications;

  const _RecentNotificationsSection({required this.notifications});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent Notifications',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/notifications'),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (notifications.isEmpty)
              const _EmptyNotificationsState()
            else
              ...notifications.map((notification) => _NotificationItem(
                    title: notification.title,
                    message: notification.body,
                    time: _formatTime(notification.createdAt),
                    isUnread: !notification.isRead,
                  )),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class _NotificationItem extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final bool isUnread;

  const _NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isUnread
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            isUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                ),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNotificationsState extends StatelessWidget {
  const _EmptyNotificationsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'You\'re all caught up',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'We\'ll let you know when something needs your attention.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  final UserRole userRole;

  const _QuickActionsSection({required this.userRole});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🚀 Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.8,
              children: [
                _ActionButton(
                  icon: Icons.search,
                  label: 'View Classes',
                  onTap: () => context.go('/discover'),
                ),
                _ActionButton(
                  icon: Icons.message,
                  label: 'Messages',
                  onTap: () => context.go('/messages'),
                ),
                if (userRole == UserRole.parent)
                  _ActionButton(
                    icon: Icons.payment,
                    label: 'Payments',
                    onTap: () => context.go('/payments'),
                  ),
                _ActionButton(
                  icon: Icons.calendar_today,
                  label: 'Calendar',
                  onTap: () => context.go('/calendar'),
                ),
                _ActionButton(
                  icon: Icons.assignment,
                  label: 'Assignments',
                  onTap: () => context.go('/assignments'),
                ),
                _ActionButton(
                  icon: Icons.notifications,
                  label: 'Notifications',
                  onTap: () => context.go('/notifications'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            color:
                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingStatsSection extends StatelessWidget {
  const _LoadingStatsSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loading...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class _LoadingNotificationsSection extends StatelessWidget {
  const _LoadingNotificationsSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loading...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class _ErrorSection extends StatelessWidget {
  final String error;

  const _ErrorSection({required this.error});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
