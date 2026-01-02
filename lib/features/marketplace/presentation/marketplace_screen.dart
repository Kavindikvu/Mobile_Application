import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Marketplace',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Buy and sell family-friendly learning supplies. Listings, offers, and chat will appear here soon.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _MarketplacePlaceholderGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketplacePlaceholderGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cards = [
      _PlaceholderCard(
        icon: Icons.book_outlined,
        title: 'Used textbooks',
        description: 'Find affordable books from other families.',
      ),
      _PlaceholderCard(
        icon: Icons.science_outlined,
        title: 'STEM kits',
        description: 'Hands-on kits and experiments coming soon.',
      ),
      _PlaceholderCard(
        icon: Icons.color_lens_outlined,
        title: 'Creative supplies',
        description: 'Art materials, instruments, and more.',
      ),
      _PlaceholderCard(
        icon: Icons.sports_esports_outlined,
        title: 'Learning devices',
        description: 'Tablets, accessories, and smart tools.',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 0.9,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: cards,
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _PlaceholderCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              description,
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

