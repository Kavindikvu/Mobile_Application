import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/domain/student_profile.dart';
import '../../../core/domain/attendance_model.dart';
import '../../../core/domain/enrollment_model.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/components/app_card.dart';
import '../../../core/ui/components/app_section_header.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/providers/auth_provider.dart';
import '../application/student_activity_controller.dart';
import 'package:intl/intl.dart';

class StudentActivityScreen extends ConsumerWidget {
  final String studentId;

  const StudentActivityScreen({
    super.key,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final activityState = ref.watch(studentActivityControllerProvider(studentId));
    final controller = ref.read(studentActivityControllerProvider(studentId).notifier);

    // Verify access: parent viewing child or student viewing self
    final isParent = authState.isParent;
    final selectedChild = authState.selectedChild;
    final currentUser = authState.user;
    
    bool hasAccess = false;
    if (isParent && selectedChild != null && selectedChild.id == studentId) {
      hasAccess = true;
    } else if (currentUser != null && currentUser.isStudent && currentUser.id == studentId) {
      hasAccess = true;
    }

    if (!hasAccess) {
      return Scaffold(
        appBar: AppBar(title: const Text('Student Activity')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Access Denied',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  isParent
                      ? 'Please select a child to view their activity'
                      : 'You do not have permission to view this student\'s activity',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (isParent) ...[
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: () => context.go('/profile'),
                    child: const Text('Go to Profile'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Activity'),
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.refresh(),
        child: activityState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : activityState.error != null
                ? _ErrorView(
                    error: activityState.error!,
                    onRetry: () => controller.refresh(),
                  )
                : activityState.student == null
                    ? const Center(child: Text('No student data available'))
                    : _StudentActivityContent(
                        student: activityState.student!,
                        attendanceSummary: activityState.attendanceSummary,
                        recentAttendance: activityState.recentAttendance,
                        enrollments: activityState.enrollments,
                      ),
      ),
    );
  }
}

class _StudentActivityContent extends StatelessWidget {
  const _StudentActivityContent({
    required this.student,
    required this.attendanceSummary,
    required this.recentAttendance,
    required this.enrollments,
  });

  final StudentProfile student;
  final AttendanceSummary? attendanceSummary;
  final List<Attendance> recentAttendance;
  final List<Enrollment> enrollments;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: SliverToBoxAdapter(
            child: _StudentHeaderCard(student: student),
          ),
        ),
        if (student.qrCodeUrl != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            sliver: SliverToBoxAdapter(
              child: _QRCodeCard(
                qrCodeUrl: student.qrCodeUrl!,
                studentName: student.displayName,
              ),
            ),
          ),
        if (attendanceSummary != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            sliver: SliverToBoxAdapter(
              child: _AttendanceSummaryCard(summary: attendanceSummary!),
            ),
          ),
        if (recentAttendance.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            sliver: SliverToBoxAdapter(
              child: _RecentAttendanceSection(attendances: recentAttendance),
            ),
          ),
        if (enrollments.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            sliver: SliverToBoxAdapter(
              child: _EnrolledClassesSection(enrollments: enrollments),
            ),
          ),
      ],
    );
  }
}

class _StudentHeaderCard extends StatelessWidget {
  const _StudentHeaderCard({required this.student});

  final StudentProfile student;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileAvatar(
                initials: student.initials,
                imageUrl: student.profileImageUrl,
                radius: 40,
                backgroundColor: theme.colorScheme.secondaryContainer,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.displayName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${student.gradeDisplay} • ${student.mediumDisplay}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (student.address != null && student.address!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              student.address!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QRCodeCard extends StatelessWidget {
  const _QRCodeCard({
    required this.qrCodeUrl,
    required this.studentName,
  });

  final String qrCodeUrl;
  final String studentName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        children: [
          AppSectionHeader(
            title: 'Student QR Code',
            action: TextButton.icon(
              onPressed: () => _showFullQRCode(context, qrCodeUrl, studentName),
              icon: const Icon(Icons.fullscreen),
              label: const Text('View Full'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            child: _QRCodeImage(qrCodeUrl: qrCodeUrl),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            studentName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => _shareQRCode(context, qrCodeUrl),
                icon: const Icon(Icons.share),
                label: const Text('Share QR Code'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFullQRCode(
    BuildContext context,
    String qrCodeUrl,
    String studentName,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                studentName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: _QRCodeImage(qrCodeUrl: qrCodeUrl, size: 250),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareQRCode(BuildContext context, String qrCodeUrl) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }
}

class _QRCodeImage extends StatelessWidget {
  const _QRCodeImage({
    required this.qrCodeUrl,
    this.size = 200,
  });

  final String qrCodeUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Check if URL is base64 data
    if (qrCodeUrl.startsWith('data:image') || qrCodeUrl.startsWith('data:image/png;base64,')) {
      // Handle base64 image
      final base64String = qrCodeUrl.contains('base64,')
          ? qrCodeUrl.split('base64,')[1]
          : qrCodeUrl;
      // For now, show a placeholder - would need base64 decoding package
      return Container(
        width: size,
        height: size,
        color: Colors.grey[300],
        child: const Icon(Icons.qr_code, size: 100),
      );
    }

    // Network image
    return Image.network(
      qrCodeUrl,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: size,
          height: size,
          color: Colors.grey[300],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code, size: size * 0.5),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'QR Code unavailable',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          width: size,
          height: size,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }
}

class _AttendanceSummaryCard extends StatelessWidget {
  const _AttendanceSummaryCard({required this.summary});

  final AttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Attendance Summary',
            action: TextButton(
              onPressed: () {
                // TODO: Navigate to full attendance screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Full attendance view coming soon')),
                );
              },
              child: const Text('View All'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _AttendanceStatCard(
                  label: 'Present',
                  value: summary.presentCount.toString(),
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _AttendanceStatCard(
                  label: 'Absent',
                  value: summary.absentCount.toString(),
                  icon: Icons.cancel_outlined,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _AttendanceStatCard(
                  label: 'Late',
                  value: summary.lateCount.toString(),
                  icon: Icons.schedule,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Attendance',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${summary.attendancePercentage.toStringAsFixed(1)}%',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: summary.attendancePercentage / 100,
                    strokeWidth: 6,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
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

class _AttendanceStatCard extends StatelessWidget {
  const _AttendanceStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentAttendanceSection extends StatelessWidget {
  const _RecentAttendanceSection({required this.attendances});

  final List<Attendance> attendances;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Recent Attendance',
            action: TextButton(
              onPressed: () {
                // TODO: Navigate to full attendance history
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Full attendance history coming soon')),
                );
              },
              child: const Text('View All'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...attendances.map((attendance) => _AttendanceListItem(
                attendance: attendance,
              )),
        ],
      ),
    );
  }
}

class _AttendanceListItem extends StatelessWidget {
  const _AttendanceListItem({required this.attendance});

  final Attendance attendance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (attendance.status) {
      case AttendanceStatus.present:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusLabel = 'Present';
        break;
      case AttendanceStatus.absent:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusLabel = 'Absent';
        break;
      case AttendanceStatus.late:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusLabel = 'Late';
        break;
      case AttendanceStatus.excused:
        statusColor = Colors.blue;
        statusIcon = Icons.info;
        statusLabel = 'Excused';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attendance.className,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${dateFormat.format(attendance.sessionDate)} • ${timeFormat.format(attendance.markedAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (attendance.notes != null && attendance.notes!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    attendance.notes!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(
              statusLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnrolledClassesSection extends StatelessWidget {
  const _EnrolledClassesSection({required this.enrollments});

  final List<Enrollment> enrollments;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Enrolled Classes',
            action: TextButton(
              onPressed: () {
                context.go('/classes');
              },
              child: const Text('View All'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (enrollments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.class_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'No enrolled classes',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...enrollments.take(5).map((enrollment) => _EnrollmentListItem(
                  enrollment: enrollment,
                )),
        ],
      ),
    );
  }
}

class _EnrollmentListItem extends StatelessWidget {
  const _EnrollmentListItem({required this.enrollment});

  final Enrollment enrollment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () {
          context.go('/classes/${enrollment.classId}');
        },
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(
                  Icons.class_outlined,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Class ID: ${enrollment.classId.substring(0, 8)}...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Subject ID: ${enrollment.subjectId.substring(0, 8)}...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Text(
                  'Approved',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

