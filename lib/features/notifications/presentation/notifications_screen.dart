import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/domain/notification.dart';
import '../../../../core/theme/tokens.dart';
import '../data/notification_repository.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotificationType? _selectedFilter;
  bool _showUnreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    
    return Column(
      children: [
        _FilterBar(
          selectedFilter: _selectedFilter,
          showUnreadOnly: _showUnreadOnly,
          onFilterChanged: (filter) {
            setState(() {
              _selectedFilter = filter;
            });
          },
          onUnreadOnlyChanged: (showUnreadOnly) {
            setState(() {
              _showUnreadOnly = showUnreadOnly;
            });
          },
        ),
        Expanded(
          child: notificationsAsync.when(
            loading: () => const _LoadingState(),
            error: (error, stackTrace) => _ErrorState(error: error.toString()),
            data: (notifications) {
              final filteredNotifications = _filterNotifications(notifications);
              if (filteredNotifications.isEmpty) {
                return _EmptyState(
                  hasFilter: _selectedFilter != null || _showUnreadOnly,
                  onClearFilters: () {
                    setState(() {
                      _selectedFilter = null;
                      _showUnreadOnly = false;
                    });
                  },
                );
              }
              return _NotificationList(notifications: filteredNotifications);
            },
          ),
        ),
      ],
    );
  }

  List<AppNotification> _filterNotifications(List<AppNotification> notifications) {
    var filtered = notifications;
    
    if (_selectedFilter != null) {
      filtered = filtered.where((n) => n.type == _selectedFilter).toList();
    }
    
    if (_showUnreadOnly) {
      filtered = filtered.where((n) => n.isUnread).toList();
    }
    
    // Sort by priority (urgent first) and then by creation time (newest first)
    filtered.sort((a, b) {
      if (a.priority != b.priority) {
        return b.priority.index.compareTo(a.priority.index);
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    
    return filtered;
  }

  void _showNotificationSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsScreen(),
      ),
    );
  }

  void _markAllAsRead(BuildContext context) {
    // TODO: Implement mark all as read
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mark all as read not yet implemented')),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final NotificationType? selectedFilter;
  final bool showUnreadOnly;
  final ValueChanged<NotificationType?> onFilterChanged;
  final ValueChanged<bool> onUnreadOnlyChanged;

  const _FilterBar({
    required this.selectedFilter,
    required this.showUnreadOnly,
    required this.onFilterChanged,
    required this.onUnreadOnlyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: selectedFilter == null,
                        onTap: () => onFilterChanged(null),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ...NotificationType.values.map((type) => Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: _FilterChip(
                          label: _getTypeLabel(type),
                          isSelected: selectedFilter == type,
                          onTap: () => onFilterChanged(type),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              FilterChip(
                label: const Text('Unread Only'),
                selected: showUnreadOnly,
                onSelected: onUnreadOnlyChanged,
              ),
              const Spacer(),
              Text(
                '${_getNotificationCount(context)} notifications',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.assignment:
        return 'Assignments';
      case NotificationType.grade:
        return 'Grades';
      case NotificationType.attendance:
        return 'Attendance';
      case NotificationType.message:
        return 'Messages';
      case NotificationType.payment:
        return 'Payments';
      case NotificationType.system:
        return 'System';
      case NotificationType.reminder:
        return 'Reminders';
      case NotificationType.achievement:
        return 'Achievements';
    }
  }

  String _getNotificationCount(BuildContext context) {
    // This would be calculated based on current filters
    return '0';
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
    );
  }
}

class _NotificationList extends StatelessWidget {
  final List<AppNotification> notifications;

  const _NotificationList({required this.notifications});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _NotificationCard(notification: notification);
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: InkWell(
        onTap: () => _handleNotificationTap(context, notification),
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: notification.isUnread 
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NotificationIcon(notification: notification),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: notification.isUnread 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (notification.isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        notification.body,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: notification.priorityColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                            ),
                            child: Text(
                              notification.priorityText,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: notification.priorityColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              notification.timeText,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Spacer(),
                          if (notification.senderName != null)
                            Flexible(
                              child: Text(
                                'from ${notification.senderName}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(context, notification, value),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'mark_read',
                      child: Row(
                        children: [
                          Icon(
                            notification.isUnread ? Icons.mark_email_read : Icons.mark_email_unread,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(notification.isUnread ? 'Mark as Read' : 'Mark as Unread'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'archive',
                      child: Row(
                        children: [
                          const Icon(Icons.archive, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          const Text('Archive'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Theme.of(context).colorScheme.error),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, AppNotification notification) {
    if (notification.actionUrl != null) {
      // TODO: Navigate to the action URL
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Navigate to: ${notification.actionUrl}')),
      );
    }
    
    if (notification.isUnread) {
      // TODO: Mark as read
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marked as read')),
      );
    }
  }

  void _handleMenuAction(BuildContext context, AppNotification notification, String action) {
    switch (action) {
      case 'mark_read':
        // TODO: Implement mark as read/unread
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(notification.isUnread ? 'Marked as read' : 'Marked as unread')),
        );
        break;
      case 'archive':
        // TODO: Implement archive
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Archived')),
        );
        break;
      case 'delete':
        // TODO: Implement delete
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deleted')),
        );
        break;
    }
  }
}

class _NotificationIcon extends StatelessWidget {
  final AppNotification notification;

  const _NotificationIcon({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: notification.priorityColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        notification.typeIcon,
        color: notification.priorityColor,
        size: 20,
      ),
    );
  }
}

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(notificationSettingsProvider('user_123'));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        actions: [
          TextButton(
            onPressed: () => _saveSettings(context),
            child: const Text('Save'),
          ),
        ],
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error loading settings: $error'),
        ),
        data: (settings) => _SettingsContent(settings: settings),
      ),
    );
  }

  void _saveSettings(BuildContext context) {
    // TODO: Implement save settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }
}

class _SettingsContent extends StatefulWidget {
  final NotificationSettings settings;

  const _SettingsContent({required this.settings});

  @override
  State<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<_SettingsContent> {
  late NotificationSettings _currentSettings;

  @override
  void initState() {
    super.initState();
    _currentSettings = widget.settings;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NotificationChannelsSection(
            settings: _currentSettings,
            onChanged: (settings) {
              setState(() {
                _currentSettings = settings;
              });
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _NotificationTypesSection(
            settings: _currentSettings,
            onChanged: (settings) {
              setState(() {
                _currentSettings = settings;
              });
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _QuietHoursSection(
            settings: _currentSettings,
            onChanged: (settings) {
              setState(() {
                _currentSettings = settings;
              });
            },
          ),
        ],
      ),
    );
  }
}

class _NotificationChannelsSection extends StatelessWidget {
  final NotificationSettings settings;
  final ValueChanged<NotificationSettings> onChanged;

  const _NotificationChannelsSection({
    required this.settings,
    required this.onChanged,
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
              'Notification Channels',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive notifications on your device'),
              value: settings.pushEnabled,
              onChanged: (value) {
                onChanged(settings.copyWith(pushEnabled: value));
              },
            ),
            SwitchListTile(
              title: const Text('Email Notifications'),
              subtitle: const Text('Receive notifications via email'),
              value: settings.emailEnabled,
              onChanged: (value) {
                onChanged(settings.copyWith(emailEnabled: value));
              },
            ),
            SwitchListTile(
              title: const Text('SMS Notifications'),
              subtitle: const Text('Receive notifications via SMS'),
              value: settings.smsEnabled,
              onChanged: (value) {
                onChanged(settings.copyWith(smsEnabled: value));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTypesSection extends StatelessWidget {
  final NotificationSettings settings;
  final ValueChanged<NotificationSettings> onChanged;

  const _NotificationTypesSection({
    required this.settings,
    required this.onChanged,
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
              'Notification Types',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...NotificationType.values.map((type) => SwitchListTile(
              title: Text(_getTypeLabel(type)),
              subtitle: Text(_getTypeDescription(type)),
              value: settings.isTypeEnabled(type),
              onChanged: (value) {
                final newTypeSettings = Map<NotificationType, bool>.from(settings.typeSettings);
                newTypeSettings[type] = value;
                onChanged(settings.copyWith(typeSettings: newTypeSettings));
              },
            )),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.assignment:
        return 'Assignments';
      case NotificationType.grade:
        return 'Grades';
      case NotificationType.attendance:
        return 'Attendance';
      case NotificationType.message:
        return 'Messages';
      case NotificationType.payment:
        return 'Payments';
      case NotificationType.system:
        return 'System';
      case NotificationType.reminder:
        return 'Reminders';
      case NotificationType.achievement:
        return 'Achievements';
    }
  }

  String _getTypeDescription(NotificationType type) {
    switch (type) {
      case NotificationType.assignment:
        return 'New assignments and updates';
      case NotificationType.grade:
        return 'Grade postings and feedback';
      case NotificationType.attendance:
        return 'Attendance alerts and updates';
      case NotificationType.message:
        return 'New messages and conversations';
      case NotificationType.payment:
        return 'Payment reminders and confirmations';
      case NotificationType.system:
        return 'System updates and maintenance';
      case NotificationType.reminder:
        return 'Assignment and event reminders';
      case NotificationType.achievement:
        return 'Achievements and badges';
    }
  }
}

class _QuietHoursSection extends StatelessWidget {
  final NotificationSettings settings;
  final ValueChanged<NotificationSettings> onChanged;

  const _QuietHoursSection({
    required this.settings,
    required this.onChanged,
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
              'Quiet Hours',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              title: const Text('Enable Quiet Hours'),
              subtitle: const Text('Pause notifications during specified hours'),
              value: settings.quietHoursEnabled,
              onChanged: (value) {
                onChanged(settings.copyWith(quietHoursEnabled: value));
              },
            ),
            if (settings.quietHoursEnabled) ...[
              ListTile(
                title: const Text('Start Time'),
                subtitle: Text(settings.quietHoursStart?.format(context) ?? 'Not set'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _selectTime(context, true),
              ),
              ListTile(
                title: const Text('End Time'),
                subtitle: Text(settings.quietHoursEnd?.format(context) ?? 'Not set'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _selectTime(context, false),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _selectTime(BuildContext context, bool isStartTime) async {
    final currentTime = isStartTime 
        ? settings.quietHoursStart ?? const TimeOfDay(hour: 22, minute: 0)
        : settings.quietHoursEnd ?? const TimeOfDay(hour: 7, minute: 0);
    
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );
    
    if (selectedTime != null) {
      if (isStartTime) {
        onChanged(settings.copyWith(quietHoursStart: selectedTime));
      } else {
        onChanged(settings.copyWith(quietHoursEnd: selectedTime));
      }
    }
  }
}

// Loading and Error States
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.md),
          Text('Loading notifications...'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onClearFilters;

  const _EmptyState({
    required this.hasFilter,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              hasFilter ? 'No notifications found' : 'No notifications yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              hasFilter
                  ? 'Try adjusting your filters'
                  : 'You\'ll receive notifications about assignments, grades, and more',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFilter) ...[
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: onClearFilters,
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
