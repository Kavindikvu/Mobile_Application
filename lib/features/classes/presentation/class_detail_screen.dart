import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/domain/assignment.dart';
import '../../../core/domain/notification.dart';
import '../../../core/theme/tokens.dart';
import '../application/class_detail_controller.dart';
import '../domain/my_class_detail.dart';
import '../domain/student_class_summary.dart';

class ClassDetailScreen extends ConsumerWidget {
  const ClassDetailScreen({
    super.key,
    required this.summary,
  });

  final StudentClassSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = ClassDetailRequest(
      classId: summary.classId,
      summary: summary,
    );
    final detailAsync = ref.watch(classDetailProvider(request));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Class details'),
      ),
      body: detailAsync.when(
        data: (detail) => _ClassDetailView(detail: detail),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _DetailError(
          onRetry: () {
            ref.invalidate(classDetailProvider(request));
          },
        ),
      ),
    );
  }
}

class _ClassDetailView extends StatelessWidget {
  const _ClassDetailView({required this.detail});

  final MyClassDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = detail.summary;
    final dateFormat = DateFormat.yMMMMd();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        _ClassHero(summary: summary),
        const SizedBox(height: AppSpacing.lg),
        _QuickHighlights(detail: detail),
        const SizedBox(height: AppSpacing.xl),
        SectionCard(
          title: 'Overview',
          subtitle: 'Key information about this class',
          children: [
            _OverviewRow(
              icon: Icons.person_outline,
              label: 'Instructor',
              value: summary.teacherName,
            ),
            _OverviewRow(
              icon: Icons.schedule_outlined,
              label: 'Schedule',
              value: summary.scheduleLabel,
            ),
            if (summary.location != null && summary.location!.isNotEmpty)
              _OverviewRow(
                icon: Icons.location_on_outlined,
                label: 'Location',
                value: summary.location!,
              ),
            _OverviewRow(
              icon: Icons.calendar_today_outlined,
              label: 'Course timeline',
              value: '${dateFormat.format(summary.startDate)} → ${dateFormat.format(summary.endDate)}',
            ),
            _OverviewRow(
              icon: Icons.class_rounded,
              label: 'Subjects',
              value: summary.subjectsLabel,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionCard(
          title: 'Assignments',
          subtitle: detail.assignments.isEmpty
              ? 'Assignments will appear here when they are published.'
              : 'Stay ahead by reviewing what’s due next.',
          trailing: detail.assignments.length > 3
              ? TextButton(
                  onPressed: () => Navigator.of(context).pushNamed('/assignments'),
                  child: const Text('View all'),
                )
              : null,
          children: detail.assignments.isEmpty
              ? const [_SectionPlaceholder(message: 'No assignments yet.')]
              : detail.assignments.take(3).map((assignment) {
                  return _AssignmentTile(assignment: assignment);
                }).toList(),
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionCard(
          title: 'Performance insights',
          subtitle: 'Monitor grades, feedback, and completed work.',
          children: [
            _PerformanceSummary(performance: detail.performance),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionCard(
          title: 'Attendance history',
          subtitle: 'Snapshot of attendance by billing period.',
          children: detail.attendanceHistory
              .map(
                (record) => _AttendanceRow(record: record),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionCard(
          title: 'Notifications',
          subtitle: 'Important updates shared for this class.',
          children: detail.relatedNotifications.isEmpty
              ? const [_SectionPlaceholder(message: 'No class notifications yet.')]
              : detail.relatedNotifications
                  .take(4)
                  .map(
                    (notification) => _NotificationTile(notification: notification),
                  )
                  .toList(),
        ),
        if (detail.upcomingMilestones.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          SectionCard(
            title: 'Upcoming milestones',
            subtitle: 'Keep an eye on what’s coming next.',
            children: detail.upcomingMilestones
                .map(
                  (milestone) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Icon(Icons.check_circle_outline, size: 18),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            milestone,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.title,
    required this.subtitle,
    required this.children,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ClassHero extends StatelessWidget {
  const _ClassHero({required this.summary});

  final StudentClassSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.className,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Student: ${summary.studentName}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onPrimary.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              _HeroChip(
                label: summary.statusLabel,
                icon: Icons.check_circle,
              ),
              _HeroChip(
                label: summary.subjectsLabel,
                icon: Icons.menu_book_outlined,
              ),
              if (summary.nextSession != null)
                _HeroChip(
                  label: 'Next: ${TimeOfDay.fromDateTime(summary.nextSession!).format(context)}',
                  icon: Icons.timer_outlined,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

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
        color: theme.colorScheme.onPrimary.withOpacity(0.15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onPrimary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickHighlights extends StatelessWidget {
  const _QuickHighlights({required this.detail});

  final MyClassDetail detail;

  @override
  Widget build(BuildContext context) {
    final summary = detail.summary;
    final theme = Theme.of(context);
    final pendingAssignments = detail.assignments
        .where((assignment) => !(assignment.isSubmitted || assignment.isGraded))
        .length;

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        _HighlightTile(
          icon: Icons.people_alt_outlined,
          title: 'Classmates',
          value: '${detail.classmateCount}',
          tone: HighlightTone.primary,
        ),
        _HighlightTile(
          icon: Icons.assignment_outlined,
          title: 'Pending assignments',
          value: '$pendingAssignments',
          tone: pendingAssignments > 0 ? HighlightTone.warning : HighlightTone.primary,
        ),
        _HighlightTile(
          icon: Icons.timelapse,
          title: 'Occupancy',
          value: '${(summary.occupancy * 100).toStringAsFixed(0)}%',
          tone: summary.isAtCapacity ? HighlightTone.warning : HighlightTone.primary,
        ),
        if (detail.performance.averageScore != null)
          _HighlightTile(
            icon: Icons.grade_outlined,
            title: 'Average grade',
            value: '${detail.performance.averageScore!.toStringAsFixed(1)}%',
            tone: HighlightTone.primary,
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.md),
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grades',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Grades will appear once assignments are evaluated.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _HighlightTile extends StatelessWidget {
  const _HighlightTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.tone,
  });

  final IconData icon;
  final String title;
  final String value;
  final HighlightTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color background;
    Color foreground;
    switch (tone) {
      case HighlightTone.primary:
        background = theme.colorScheme.primaryContainer.withOpacity(0.4);
        foreground = theme.colorScheme.onPrimaryContainer;
        break;
      case HighlightTone.warning:
        background = theme.colorScheme.errorContainer.withOpacity(0.4);
        foreground = theme.colorScheme.onErrorContainer;
        break;
      case HighlightTone.muted:
        background = theme.colorScheme.surfaceVariant.withOpacity(0.6);
        foreground = theme.colorScheme.onSurfaceVariant;
        break;
    }

    return Container(
      width: 170,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        color: background,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: 22),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: foreground.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentTile extends StatelessWidget {
  const _AssignmentTile({required this.assignment});

  final Assignment assignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueDate = DateFormat.yMMMd().add_jm().format(assignment.dueDate);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.assignment, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Due $dueDate • ${assignment.typeText}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (assignment.feedback != null && assignment.feedback!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    assignment.feedback!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceSummary extends StatelessWidget {
  const _PerformanceSummary({required this.performance});

  final ClassPerformanceInsight performance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _PerformanceMetric(
                label: 'Completed',
                value: '${performance.completedAssignments}',
              ),
            ),
            Expanded(
              child: _PerformanceMetric(
                label: 'Graded',
                value: '${performance.gradedAssignments}',
              ),
            ),
            Expanded(
              child: _PerformanceMetric(
                label: 'Average',
                value: performance.averageScore != null
                    ? '${performance.averageScore!.toStringAsFixed(1)}%'
                    : 'Pending',
              ),
            ),
          ],
        ),
        if (performance.feedbackHighlights.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Recent feedback',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          ...performance.feedbackHighlights.map(
            (feedback) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Text(
                '• $feedback',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PerformanceMetric extends StatelessWidget {
  const _PerformanceMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({required this.record});

  final ClassAttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rate = (record.attendanceRate * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.periodLabel,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${record.attendedSessions} of ${record.totalSessions} sessions attended',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Chip(
            label: Text('$rate%'),
            backgroundColor: theme.colorScheme.primaryContainer,
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(notification.typeIcon, color: notification.priorityColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  notification.body,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  notification.timeText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionPlaceholder extends StatelessWidget {
  const _SectionPlaceholder({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: AppSpacing.md),
            const Text('Unable to load class details.'),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

enum HighlightTone { primary, warning, muted }

