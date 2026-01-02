import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/teacher_repository.dart';

class TeacherProfileScreen extends ConsumerWidget {
  final String instructorId;
  const TeacherProfileScreen({super.key, required this.instructorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = ref.watch(FutureProvider((ref) {
      return ref.read(teacherRepositoryProvider).getById(instructorId);
    }));
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Profile')),
      body: future.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Teacher not found'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  const CircleAvatar(radius: 28, child: Icon(Icons.person)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.name, style: Theme.of(context).textTheme.titleLarge),
                        Text('⭐ ${profile.rating} (${profile.reviewCount} reviews)'),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile.subjects.map((s) => Chip(label: Text(s))).toList(),
              ),
              const SizedBox(height: 24),
              Text('Available Classes', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...profile.classes.map((c) => Card(
                    child: ListTile(
                      title: Text(c['title'] as String? ?? 'Class'),
                      subtitle: Text('${c['type']} • ${c['price']} ${c['currency']}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  )),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.chat),
                label: const Text('Send Message'),
              ),
            ],
          );
        },
      ),
    );
  }
}


