import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/domain/student_profile.dart';
import '../../../core/domain/user_profile.dart';
import '../../profile/application/parent_children_controller.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final selectedChild = authState.selectedChild;
    final isParent = authState.isParent;
    final childrenAsync = ref.watch(parentChildrenControllerProvider);
    final children = childrenAsync.maybeWhen(
      data: (state) => state.children,
      orElse: () => const <StudentProfile>[],
    );

    final menuItems = _buildMenuItems(context, ref);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.08),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MenuHeader(),
                    if (user != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _ProfileSummaryCard(
                          user: user, selectedChild: selectedChild),
                    ],
                    if (isParent) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _ShortcutsSection(
                        childrenAsync: childrenAsync,
                        user: user,
                        children: children,
                        selectedChild: selectedChild,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Application Menu',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: menuItems.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: AppSpacing.sm,
                        crossAxisSpacing: AppSpacing.sm,
                        childAspectRatio: 1.35,
                      ),
                      itemBuilder: (context, index) {
                        final item = menuItems[index];
                        return _MenuTile(item: item);
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Center(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                        onPressed: () => _showComingSoon(context),
                        icon: const Icon(Icons.expand_more),
                        label: const Text('See more'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: authState.isLoading
                            ? null
                            : () async {
                                await ref.read(authProvider.notifier).logout();
                                if (context.mounted) {
                                  context.go('/login');
                                }
                              },
                        icon: const Icon(Icons.logout),
                        label: const Text('Log out'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_MenuTileData> _buildMenuItems(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isParent = authState.isParent;
    final selectedChild = authState.selectedChild;
    final currentUser = authState.user;
    
    // Determine which student's activity to show
    String? studentId;
    if (isParent && selectedChild != null) {
      studentId = selectedChild.id;
    } else if (currentUser != null && currentUser.isStudent) {
      studentId = currentUser.id;
    }
    
    return [
      _MenuTileData(
        label: 'Feeds',
        icon: Icons.dynamic_feed_outlined,
        onTap: () => context.go('/home'),
      ),
      _MenuTileData(
        label: 'Memories',
        icon: Icons.history,
        onTap: () => _showComingSoon(context),
      ),
      _MenuTileData(
        label: 'Saved',
        icon: Icons.bookmark_border,
        onTap: () => _showComingSoon(context),
      ),
      _MenuTileData(
        label: 'Groups',
        icon: Icons.groups_outlined,
        onTap: () => context.go('/classes'),
      ),
      if (studentId != null)
        _MenuTileData(
          label: 'Student Activity',
          icon: Icons.insights_outlined,
          onTap: () => context.go('/student-activity/$studentId'),
        ),
      _MenuTileData(
        label: 'Reels',
        icon: Icons.play_circle_outline,
        onTap: () => _showComingSoon(context),
      ),
      _MenuTileData(
        label: 'Marketplace',
        icon: Icons.storefront_outlined,
        onTap: () => context.go('/marketplace'),
      ),
      _MenuTileData(
        label: 'Friends',
        icon: Icons.people_alt_outlined,
        onTap: () => _showComingSoon(context),
      ),
      _MenuTileData(
        label: 'Events',
        icon: Icons.event_outlined,
        onTap: () => context.go('/calendar'),
      ),
    ];
  }
}

class _MenuHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          'Menu',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Search',
          onPressed: () => _showComingSoon(context),
          icon: const Icon(Icons.search),
        ),
        IconButton(
          tooltip: 'Settings',
          onPressed: () => _showComingSoon(context),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }
}

class _ProfileSummaryCard extends ConsumerWidget {
  const _ProfileSummaryCard({
    required this.user,
    required this.selectedChild,
  });

  final UserProfile user;
  final StudentProfile? selectedChild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isParentView = selectedChild == null;
    final imageUrl =
        isParentView ? user.profileImageUrl : selectedChild?.profileImageUrl;
    final initials =
        isParentView ? user.initials : (selectedChild?.initials ?? '?');

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      elevation: 0,
      color: theme.colorScheme.surface,
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        leading: _AvatarBadge(
          imageUrl: imageUrl,
          initials: initials,
        ),
        title: Text(
          isParentView ? user.displayName : selectedChild!.displayName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          isParentView
              ? user.email
              : '${selectedChild!.gradeDisplay} • ${selectedChild!.mediumDisplay}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: FilledButton.icon(
          onPressed: () => context.go('/profile'),
          icon: const Icon(Icons.person_outline),
          label: const Text('Profile'),
        ),
      ),
    );
  }
}

class _ShortcutsSection extends ConsumerWidget {
  const _ShortcutsSection({
    required this.childrenAsync,
    required this.user,
    required this.children,
    required this.selectedChild,
  });

  final AsyncValue<ParentChildrenState> childrenAsync;
  final UserProfile? user;
  final List<StudentProfile> children;
  final StudentProfile? selectedChild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final parentNotifier = ref.read(authProvider.notifier);
    final parentUser = user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your shortcuts',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 120,
          child: childrenAsync.when(
            data: (_) {
              final shortcuts = <_ShortcutData>[
                if (parentUser != null)
                  _ShortcutData(
                    id: 'parent',
                    label: parentUser.displayName,
                    subtitle: 'Parent view',
                    imageUrl: parentUser.profileImageUrl,
                    initials: parentUser.initials,
                    isSelected: selectedChild == null,
                    onTap: () => parentNotifier.switchToParent(),
                  ),
                ...children.map(
                  (child) => _ShortcutData(
                    id: child.id,
                    label: child.displayName,
                    subtitle: child.gradeDisplay,
                    imageUrl: child.profileImageUrl,
                    initials: child.initials,
                    isSelected: selectedChild?.id == child.id,
                    onTap: () => parentNotifier.switchToChild(child),
                  ),
                ),
              ];

              if (shortcuts.isEmpty) {
                return _ShortcutPlaceholder();
              }

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                itemCount: shortcuts.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final shortcut = shortcuts[index];
                  return _ShortcutCard(data: shortcut);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ShortcutError(message: error.toString()),
          ),
        ),
      ],
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({required this.data});

  final _ShortcutData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = data.isSelected
        ? const Color(AppColors.brandBlue)
        : theme.colorScheme.outlineVariant.withOpacity(0.4);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      onTap: data.onTap,
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border:
              Border.all(color: borderColor, width: data.isSelected ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AvatarBadge(
              imageUrl: data.imageUrl,
              initials: data.initials,
              size: 50,
            ),
            const Spacer(),
            Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (data.subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                data.subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShortcutPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.family_restroom,
              color: theme.colorScheme.onSurfaceVariant, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add child profiles to switch contexts quickly.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ShortcutError extends StatelessWidget {
  const _ShortcutError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'We couldn\'t load shortcuts. $message',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item});

  final _MenuTileData item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor:
                  theme.colorScheme.primaryContainer.withOpacity(0.4),
              child: Icon(
                item.icon,
                color: theme.colorScheme.primary,
              ),
            ),
            const Spacer(),
            Text(
              item.label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({
    this.imageUrl,
    required this.initials,
    this.size = 56,
  });

  final String? imageUrl;
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.startsWith('http');
    final theme = Theme.of(context);

    return CircleAvatar(
      radius: size / 2,
      backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
      backgroundColor:
          hasImage ? null : theme.colorScheme.primaryContainer.withOpacity(0.6),
      child: hasImage
          ? null
          : Text(
              initials,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
    );
  }
}

class _MenuTileData {
  const _MenuTileData({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _ShortcutData {
  const _ShortcutData({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.imageUrl,
    required this.initials,
    required this.isSelected,
    required this.onTap,
  });

  final String id;
  final String label;
  final String? subtitle;
  final String? imageUrl;
  final String initials;
  final bool isSelected;
  final VoidCallback onTap;
}

void _showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('This feature is coming soon.'),
      duration: Duration(seconds: 2),
    ),
  );
}
