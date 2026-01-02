import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/domain/assignment.dart';
import '../../../../core/theme/tokens.dart';
import '../data/assignment_repository.dart';

class AssignmentsScreen extends ConsumerStatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  ConsumerState<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends ConsumerState<AssignmentsScreen> {
  AssignmentStatus? _selectedFilter;
  final List<AssignmentStatus> _filterOptions = [
    AssignmentStatus.notStarted,
    AssignmentStatus.inProgress,
    AssignmentStatus.submitted,
    AssignmentStatus.graded,
    AssignmentStatus.late,
    AssignmentStatus.overdue,
  ];

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(assignmentsProvider);
    
    return Column(
      children: [
        if (_selectedFilter != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: _FilterChip(filter: _selectedFilter!),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filter',
              onPressed: () => _showFilterBottomSheet(context),
            ),
          ),
        ),
        Expanded(
          child: assignmentsAsync.when(
            loading: () => const _LoadingState(),
            error: (error, stackTrace) => _ErrorState(error: error.toString()),
            data: (assignments) {
              final filtered = _selectedFilter != null
                  ? assignments.where((a) => a.status == _selectedFilter).toList()
                  : assignments;
              if (filtered.isEmpty) {
                return _EmptyState(
                  hasFilter: _selectedFilter != null,
                  onClearFilter: () {
                    setState(() { _selectedFilter = null; });
                  },
                );
              }
              return _AssignmentList(assignments: filtered);
            },
          ),
        ),
      ],
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _FilterBottomSheet(
        currentFilter: _selectedFilter,
        onFilterSelected: (filter) {
          setState(() {
            _selectedFilter = filter;
          });
          Navigator.pop(context);
        },
        onClearFilter: () {
          setState(() {
            _selectedFilter = null;
          });
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final AssignmentStatus filter;

  const _FilterChip({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Chip(
            label: Text(_getFilterText(filter)),
            onDeleted: () {
              // This would be handled by the parent widget
            },
          ),
        ],
      ),
    );
  }

  String _getFilterText(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.notStarted:
        return 'Not Started';
      case AssignmentStatus.inProgress:
        return 'In Progress';
      case AssignmentStatus.submitted:
        return 'Submitted';
      case AssignmentStatus.graded:
        return 'Graded';
      case AssignmentStatus.late:
        return 'Late';
      case AssignmentStatus.overdue:
        return 'Overdue';
    }
  }
}

class _FilterBottomSheet extends StatelessWidget {
  final AssignmentStatus? currentFilter;
  final ValueChanged<AssignmentStatus?> onFilterSelected;
  final VoidCallback onClearFilter;

  const _FilterBottomSheet({
    required this.currentFilter,
    required this.onFilterSelected,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Assignments',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...AssignmentStatus.values.map((status) => ListTile(
            leading: Icon(_getStatusIcon(status)),
            title: Text(_getStatusText(status)),
            trailing: currentFilter == status ? const Icon(Icons.check) : null,
            onTap: () => onFilterSelected(status),
          )),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.clear_all),
            title: const Text('Clear Filter'),
            onTap: onClearFilter,
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.notStarted:
        return Icons.assignment_outlined;
      case AssignmentStatus.inProgress:
        return Icons.assignment_turned_in;
      case AssignmentStatus.submitted:
        return Icons.check_circle_outline;
      case AssignmentStatus.graded:
        return Icons.grade;
      case AssignmentStatus.late:
        return Icons.schedule;
      case AssignmentStatus.overdue:
        return Icons.warning;
    }
  }

  String _getStatusText(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.notStarted:
        return 'Not Started';
      case AssignmentStatus.inProgress:
        return 'In Progress';
      case AssignmentStatus.submitted:
        return 'Submitted';
      case AssignmentStatus.graded:
        return 'Graded';
      case AssignmentStatus.late:
        return 'Late';
      case AssignmentStatus.overdue:
        return 'Overdue';
    }
  }
}

class _AssignmentList extends StatelessWidget {
  final List<Assignment> assignments;

  const _AssignmentList({required this.assignments});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: assignments.length,
      itemBuilder: (context, index) {
        final assignment = assignments[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _AssignmentCard(assignment: assignment),
        );
      },
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Assignment assignment;

  const _AssignmentCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => _showAssignmentDetails(context, assignment),
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getTypeIcon(assignment.type),
                    color: _getStatusColor(context, assignment.status),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      assignment.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _StatusChip(status: assignment.status),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '📚 ${assignment.className}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '👨‍🏫 ${assignment.instructorName}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: _getDueDateColor(context, assignment),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    assignment.dueDateText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getDueDateColor(context, assignment),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '🎯 ${assignment.totalPoints} points',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (assignment.isGraded) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.grade,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Grade: ${assignment.grade} (${assignment.earnedPoints}/${assignment.totalPoints})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
              if (assignment.status == AssignmentStatus.inProgress) ...[
                const SizedBox(height: AppSpacing.sm),
                _ProgressIndicator(assignment: assignment),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showAssignmentDetails(context, assignment),
                      child: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (assignment.canSubmit)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _startAssignment(context, assignment),
                        child: Text(assignment.status == AssignmentStatus.notStarted ? 'Start' : 'Continue'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(AssignmentType type) {
    switch (type) {
      case AssignmentType.homework:
        return Icons.assignment;
      case AssignmentType.project:
        return Icons.work;
      case AssignmentType.quiz:
        return Icons.quiz;
      case AssignmentType.exam:
        return Icons.school;
      case AssignmentType.essay:
        return Icons.edit;
      case AssignmentType.lab:
        return Icons.science;
      case AssignmentType.presentation:
        return Icons.present_to_all;
    }
  }

  Color _getStatusColor(BuildContext context, AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.notStarted:
        return Theme.of(context).colorScheme.onSurfaceVariant;
      case AssignmentStatus.inProgress:
        return Theme.of(context).colorScheme.primary;
      case AssignmentStatus.submitted:
        return Theme.of(context).colorScheme.secondary;
      case AssignmentStatus.graded:
        return Theme.of(context).colorScheme.tertiary;
      case AssignmentStatus.late:
        return Theme.of(context).colorScheme.secondary;
      case AssignmentStatus.overdue:
        return Theme.of(context).colorScheme.error;
    }
  }

  Color _getDueDateColor(BuildContext context, Assignment assignment) {
    if (assignment.isOverdue) {
      return Theme.of(context).colorScheme.error;
    } else if (assignment.isDueSoon) {
      return Theme.of(context).colorScheme.secondary;
    } else {
      return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  void _showAssignmentDetails(BuildContext context, Assignment assignment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AssignmentDetailsScreen(assignment: assignment),
      ),
    );
  }

  void _startAssignment(BuildContext context, Assignment assignment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AssignmentSubmissionScreen(assignment: assignment),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final AssignmentStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _getStatusColor(context, status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(
          color: _getStatusColor(context, status),
          width: 1,
        ),
      ),
      child: Text(
        _getStatusText(status),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: _getStatusColor(context, status),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor(BuildContext context, AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.notStarted:
        return Theme.of(context).colorScheme.onSurfaceVariant;
      case AssignmentStatus.inProgress:
        return Theme.of(context).colorScheme.primary;
      case AssignmentStatus.submitted:
        return Theme.of(context).colorScheme.secondary;
      case AssignmentStatus.graded:
        return Theme.of(context).colorScheme.tertiary;
      case AssignmentStatus.late:
        return Theme.of(context).colorScheme.secondary;
      case AssignmentStatus.overdue:
        return Theme.of(context).colorScheme.error;
    }
  }

  String _getStatusText(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.notStarted:
        return 'Not Started';
      case AssignmentStatus.inProgress:
        return 'In Progress';
      case AssignmentStatus.submitted:
        return 'Submitted';
      case AssignmentStatus.graded:
        return 'Graded';
      case AssignmentStatus.late:
        return 'Late';
      case AssignmentStatus.overdue:
        return 'Overdue';
    }
  }
}

class _ProgressIndicator extends StatelessWidget {
  final Assignment assignment;

  const _ProgressIndicator({required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(assignment.progressPercentage * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        LinearProgressIndicator(
          value: assignment.progressPercentage,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _AssignmentDetailsScreen extends StatelessWidget {
  final Assignment assignment;

  const _AssignmentDetailsScreen({required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment Details'),
        actions: [
          if (assignment.canSubmit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => _AssignmentSubmissionScreen(assignment: assignment),
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AssignmentHeader(assignment: assignment),
            const SizedBox(height: AppSpacing.lg),
            _AssignmentDescription(assignment: assignment),
            const SizedBox(height: AppSpacing.lg),
            _AssignmentAttachments(assignment: assignment),
            if (assignment.isGraded) ...[
              const SizedBox(height: AppSpacing.lg),
              _AssignmentGrade(assignment: assignment),
            ],
            if (assignment.isSubmitted && !assignment.isGraded) ...[
              const SizedBox(height: AppSpacing.lg),
              _SubmissionStatus(assignment: assignment),
            ],
            if (assignment.canSubmit) ...[
              const SizedBox(height: AppSpacing.lg),
              _ActionButtons(assignment: assignment),
            ],
          ],
        ),
      ),
    );
  }
}

class _AssignmentHeader extends StatelessWidget {
  final Assignment assignment;

  const _AssignmentHeader({required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getTypeIcon(assignment.type),
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                assignment.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '📚 ${assignment.className}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '👨‍🏫 ${assignment.instructorName}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _StatusChip(status: assignment.status),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '🎯 ${assignment.totalPoints} points',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getTypeIcon(AssignmentType type) {
    switch (type) {
      case AssignmentType.homework:
        return Icons.assignment;
      case AssignmentType.project:
        return Icons.work;
      case AssignmentType.quiz:
        return Icons.quiz;
      case AssignmentType.exam:
        return Icons.school;
      case AssignmentType.essay:
        return Icons.edit;
      case AssignmentType.lab:
        return Icons.science;
      case AssignmentType.presentation:
        return Icons.present_to_all;
    }
  }
}

class _AssignmentDescription extends StatelessWidget {
  final Assignment assignment;

  const _AssignmentDescription({required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          assignment.description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Due: ${_formatDate(assignment.dueDate)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _AssignmentAttachments extends StatelessWidget {
  final Assignment assignment;

  const _AssignmentAttachments({required this.assignment});

  @override
  Widget build(BuildContext context) {
    if (assignment.attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachments',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...assignment.attachments.map((attachment) => ListTile(
          leading: const Icon(Icons.attach_file),
          title: Text(attachment),
          trailing: const Icon(Icons.download),
          onTap: () {
            // TODO: Implement download functionality
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Downloading $attachment...')),
            );
          },
        )),
      ],
    );
  }
}

class _AssignmentGrade extends StatelessWidget {
  final Assignment assignment;

  const _AssignmentGrade({required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.grade,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Grade: ${assignment.grade}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Score: ${assignment.earnedPoints}/${assignment.totalPoints} points',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (assignment.feedback?.isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Feedback:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                assignment.feedback!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SubmissionStatus extends StatelessWidget {
  final Assignment assignment;

  const _SubmissionStatus({required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assignment Submitted',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Submitted on ${_formatDate(assignment.submittedAt!)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _ActionButtons extends StatelessWidget {
  final Assignment assignment;

  const _ActionButtons({required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => _AssignmentSubmissionScreen(assignment: assignment),
                ),
              );
            },
            icon: Icon(assignment.status == AssignmentStatus.notStarted ? Icons.play_arrow : Icons.edit),
            label: Text(assignment.status == AssignmentStatus.notStarted ? 'Start Assignment' : 'Continue'),
          ),
        ),
      ],
    );
  }
}

class _AssignmentSubmissionScreen extends StatefulWidget {
  final Assignment assignment;

  const _AssignmentSubmissionScreen({required this.assignment});

  @override
  State<_AssignmentSubmissionScreen> createState() => _AssignmentSubmissionScreenState();
}

class _AssignmentSubmissionScreenState extends State<_AssignmentSubmissionScreen> {
  final TextEditingController _submissionController = TextEditingController();
  List<String> _submissionAttachments = [];

  @override
  void initState() {
    super.initState();
    _submissionController.text = widget.assignment.submissionText ?? '';
    _submissionAttachments = List.from(widget.assignment.submissionAttachments);
  }

  @override
  void dispose() {
    _submissionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assignment.title),
        actions: [
          TextButton(
            onPressed: _saveDraft,
            child: const Text('Save Draft'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AssignmentInfo(assignment: widget.assignment),
            const SizedBox(height: AppSpacing.lg),
            _SubmissionForm(
              controller: _submissionController,
              attachments: _submissionAttachments,
              onAttachmentsChanged: (attachments) {
                setState(() {
                  _submissionAttachments = attachments;
                });
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _SubmissionButtons(
              onSaveDraft: _saveDraft,
              onSubmit: _submitAssignment,
            ),
          ],
        ),
      ),
    );
  }

  void _saveDraft() {
    // TODO: Implement save draft functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft saved successfully')),
    );
  }

  void _submitAssignment() {
    // TODO: Implement submit assignment functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Assignment'),
        content: const Text('Are you sure you want to submit this assignment? You won\'t be able to make changes after submission.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Assignment submitted successfully')),
              );
              Navigator.pop(context);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class _AssignmentInfo extends StatelessWidget {
  final Assignment assignment;

  const _AssignmentInfo({required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assignment Instructions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              assignment.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Due: ${_formatDate(assignment.dueDate)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _SubmissionForm extends StatelessWidget {
  final TextEditingController controller;
  final List<String> attachments;
  final ValueChanged<List<String>> onAttachmentsChanged;

  const _SubmissionForm({
    required this.controller,
    required this.attachments,
    required this.onAttachmentsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Submission',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          maxLines: 10,
          decoration: const InputDecoration(
            hintText: 'Enter your submission here...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Attachments',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (attachments.isNotEmpty)
          ...attachments.map((attachment) => ListTile(
            leading: const Icon(Icons.attach_file),
            title: Text(attachment),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                final newAttachments = List<String>.from(attachments);
                newAttachments.remove(attachment);
                onAttachmentsChanged(newAttachments);
              },
            ),
          )),
        OutlinedButton.icon(
          onPressed: () {
            // TODO: Implement file picker
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File picker not implemented')),
            );
          },
          icon: const Icon(Icons.attach_file),
          label: const Text('Add Attachment'),
        ),
      ],
    );
  }
}

class _SubmissionButtons extends StatelessWidget {
  final VoidCallback onSaveDraft;
  final VoidCallback onSubmit;

  const _SubmissionButtons({
    required this.onSaveDraft,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onSaveDraft,
            child: const Text('Save Draft'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ElevatedButton(
            onPressed: onSubmit,
            child: const Text('Submit'),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.md),
          Text('Loading assignments...'),
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
  final VoidCallback onClearFilter;

  const _EmptyState({
    required this.hasFilter,
    required this.onClearFilter,
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
              Icons.assignment_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              hasFilter ? 'No assignments match your filter' : 'No assignments available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              hasFilter
                  ? 'Try adjusting your filter criteria'
                  : 'Check back later for new assignments',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFilter) ...[
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: onClearFilter,
                child: const Text('Clear Filter'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
