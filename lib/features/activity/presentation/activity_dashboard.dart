import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/activity_repository.dart';

final activitySummaryProvider = FutureProvider((ref) {
  return ref.read(activityRepositoryProvider).getSummary();
});

class ActivityDashboard extends ConsumerWidget {
  const ActivityDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(activitySummaryProvider);
    return summary.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (s) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StatCard(title: 'GPA', value: s.gpa.toStringAsFixed(2), icon: Icons.grade),
            const SizedBox(height: 12),
            _StatCard(title: 'Attendance', value: '${s.attendanceRate.toStringAsFixed(1)}%', icon: Icons.event_available),
            const SizedBox(height: 12),
            _StatCard(title: 'Assignments', value: '${s.completedAssignments}/${s.totalAssignments}', icon: Icons.assignment_turned_in),
            const SizedBox(height: 24),
            Text('Recent Achievements', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...s.achievements.map((a) => ListTile(leading: const Icon(Icons.emoji_events), title: Text(a))).toList(),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}


