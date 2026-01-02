import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../application/my_classes_controller.dart';
import '../domain/student_class_summary.dart';

class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesState = ref.watch(myClassesControllerProvider);

    return SafeArea(
      child: classesState.when(
        data: (state) => RefreshIndicator(
          onRefresh: () => ref.read(myClassesControllerProvider.notifier).refresh(),
          child: _MyClassesBody(state: state),
        ),
        loading: () => const _LoadingState(),
        error: (error, _) => _ErrorState(
          message: 'We couldn’t load your classes right now.',
          onRetry: () => ref.read(myClassesControllerProvider.notifier).refresh(),
        ),
      ),
    );
  }
}

class _MyClassesBody extends StatelessWidget {
  const _MyClassesBody({required this.state});

  final MyClassesState state;

  @override
  Widget build(BuildContext context) {
    if (state.classes.isEmpty && !state.isParentContext) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          _EmptyMyClasses(),
        ],
      );
    }

    if (state.isParentContext) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          _MyClassesHeader(
            title: 'My Classes',
            subtitle: 'All enrolled classes across your children',
            totalClasses: state.totalClasses,
            totalAssignments: state.totalPendingAssignments,
            pendingEnrollments: state.pendingEnrollments,
          ),
          const SizedBox(height: AppSpacing.lg),
          ...state.children.map(
            (child) {
              final childClasses = state.classesForStudent(child.id);
              return _ChildClassesSection(
                studentName: child.displayName,
                studentId: child.id,
                classes: childClasses,
              );
            },
          ),
        ],
      );
    }

    final focused = state.focusedStudent;
    return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        _MyClassesHeader(
          title: 'My Classes',
          subtitle: focused != null
              ? 'Personalized for ${focused.displayName}'
              : 'Upcoming sessions and class progress',
          totalClasses: state.totalClasses,
          totalAssignments: state.totalPendingAssignments,
          pendingEnrollments: state.pendingEnrollments,
        ),
        const SizedBox(height: AppSpacing.lg),
        ...state.classes.map(
          (summary) => _ClassCard(
            summary: summary,
            highlightStudent: state.isParentContext,
          ),
        ),
      ],
    );
  }
}

class _ChildClassesSection extends StatelessWidget {
  const _ChildClassesSection({
    required this.studentName,
    required this.studentId,
    required this.classes,
  });

  final String studentName;
  final String studentId;
  final List<StudentClassSummary> classes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          studentName,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (classes.isEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.xl),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.md),
              color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
            ),
            child: Text(
              '$studentName has no active class enrollments yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ...classes.map(
            (summary) => _ClassCard(
              summary: summary,
              highlightStudent: true,
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _MyClassesHeader extends StatelessWidget {
  const _MyClassesHeader({
    required this.title,
    required this.subtitle,
    required this.totalClasses,
    required this.totalAssignments,
    required this.pendingEnrollments,
  });

  final String title;
  final String subtitle;
  final int totalClasses;
  final int totalAssignments;
  final int pendingEnrollments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _SummaryMetricChip(
              label: 'Active classes',
              value: '$totalClasses',
              icon: Icons.auto_stories_outlined,
            ),
            _SummaryMetricChip(
              label: 'Assignments due',
              value: '$totalAssignments',
              icon: Icons.assignment_outlined,
              tone: ChipTone.warning,
            ),
            _SummaryMetricChip(
              label: 'Awaiting approval',
              value: '$pendingEnrollments',
              icon: Icons.hourglass_bottom,
              tone: ChipTone.muted,
            ),
          ],
        ),
      ],
    );
  }
}

enum ChipTone { primary, warning, muted }

class _SummaryMetricChip extends StatelessWidget {
  const _SummaryMetricChip({
    required this.label,
    required this.value,
    required this.icon,
    this.tone = ChipTone.primary,
  });

  final String label;
  final String value;
  final IconData icon;
  final ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color background;
    Color foreground;
    switch (tone) {
      case ChipTone.primary:
        background = theme.colorScheme.primaryContainer.withOpacity(0.5);
        foreground = theme.colorScheme.onPrimaryContainer;
        break;
      case ChipTone.warning:
        background = theme.colorScheme.errorContainer.withOpacity(0.4);
        foreground = theme.colorScheme.onErrorContainer;
        break;
      case ChipTone.muted:
        background = theme.colorScheme.surfaceVariant.withOpacity(0.6);
        foreground = theme.colorScheme.onSurfaceVariant;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.md),
        color: background,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: foreground),
          const SizedBox(width: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: foreground.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.summary,
    required this.highlightStudent,
  });

  final StudentClassSummary summary;
  final bool highlightStudent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceColor = theme.colorScheme.surface;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: () => context.push(
          '/classes/${summary.classId}',
          extra: summary,
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            color: surfaceColor,
          ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                            summary.className,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'with ${summary.teacherName}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Chip(
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      label: Text(
                        summary.statusLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _InfoPill(
                      icon: Icons.menu_book_outlined,
                      text: summary.subjectsLabel,
                    ),
                    _InfoPill(
                      icon: Icons.schedule_outlined,
                      text: summary.scheduleLabel,
                    ),
                    if (summary.nextSession != null)
                      _InfoPill(
                        icon: Icons.event_available,
                        text:
                            'Next: ${TimeOfDay.fromDateTime(summary.nextSession!).format(context)}',
                      ),
                  ],
                ),
                if (highlightStudent) ...[
                    const SizedBox(height: AppSpacing.sm),
                  _InfoPill(
                    icon: Icons.person_outline,
                    text: summary.studentName,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                _OccupancyIndicator(summary: summary),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      summary.assignmentsLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (summary.hasAssignments)
                      FilledButton.tonalIcon(
                        onPressed: () => context.push('/assignments'),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Review'),
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
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.md),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _OccupancyIndicator extends StatelessWidget {
  const _OccupancyIndicator({required this.summary});

  final StudentClassSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final occupancy = summary.occupancy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              summary.capacityLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${(occupancy * 100).toStringAsFixed(0)}% full',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: occupancy.clamp(0, 1),
            backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            valueColor: AlwaysStoppedAnimation(
              summary.isAtCapacity
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyMyClasses extends StatelessWidget {
  const _EmptyMyClasses();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Classes',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No classes yet',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Once you enroll in a class, you will see schedules, assignments, and progress tracking here.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () => context.go('/discover'),
                icon: const Icon(Icons.search),
                label: const Text('Discover classes'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 44,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
