import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../theme/tokens.dart';
import '../domain/student_profile.dart';
import '../domain/user_profile.dart';
import 'child_switcher.dart';
import '../../features/profile/application/parent_children_controller.dart';
import 'profile_avatar.dart';

class ChildContextBar extends ConsumerWidget {
  const ChildContextBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (!authState.isParent) {
      return const SizedBox.shrink();
    }

    final childrenAsync = ref.watch(parentChildrenControllerProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: childrenAsync.when(
          loading: () => const _ChildContextLoading(),
          error: (error, stackTrace) => _ChildContextError(
            message: error.toString(),
            onRetry: () =>
                ref.read(parentChildrenControllerProvider.notifier).refresh(),
          ),
          data: (state) {
            final selectedChild = authState.selectedChild;
            final parent = authState.user;
            final hasChildren = state.children.isNotEmpty;
            if (!hasChildren) {
              // No children yet – surface a quick action to add/link a child
              return _ChildContextCallout(
                pendingCount: state.pendingRequests.length,
                errorMessage: state.errorMessage,
              );
            }

            if (selectedChild == null && parent != null) {
              return _ParentContextChip(
                parent: parent,
                previewChild: state.children.first,
                onTap: () => _showChildSwitcher(context),
              );
            }

            return _ChildContextChip(
              child: selectedChild ?? state.children.first,
              onTap: () => _showChildSwitcher(context),
            );
          },
        ),
      ),
    );
  }

  void _showChildSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return const SafeArea(
          child: ChildSwitcher(),
        );
      },
    );
  }
}

class _ChildContextLoading extends StatelessWidget {
  const _ChildContextLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Loading children...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ChildContextError extends StatelessWidget {
  const _ChildContextError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 18,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Unable to load children',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _ChildContextChip extends StatelessWidget {
  const _ChildContextChip({
    required this.child,
    required this.onTap,
  });

  final StudentProfile child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        splashColor: theme.colorScheme.primary.withOpacity(0.12),
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.18),
                theme.colorScheme.primaryContainer.withOpacity(0.45),
              ],
            ),
            border: Border.all(
              color: theme.colorScheme.primary,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.15),
                offset: const Offset(0, 6),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ProfileAvatar(
                    initials: child.initials,
                    imageUrl: child.profileImageUrl,
                    radius: 26,
                    backgroundColor: theme.colorScheme.primaryContainer,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                      child: Container(
                        key: const ValueKey<String>('child-active-pill'),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.check,
                          size: 16,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      child.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${child.gradeDisplay} • ${child.mediumDisplay}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParentContextChip extends StatelessWidget {
  const _ParentContextChip({
    required this.parent,
    required this.previewChild,
    required this.onTap,
  });

  final UserProfile parent;
  final StudentProfile previewChild;
  final VoidCallback onTap;

  String get _parentInitials {
    final initials = parent.initials.trim();
    return initials.isNotEmpty ? initials : '?';
  }

  String? get _parentImage {
    return parent.profileImageUrl;
  }

  String get _parentName {
    final name = parent.displayName.trim();
    return name.isNotEmpty ? name : 'Parent view';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        splashColor: theme.colorScheme.secondary.withOpacity(0.12),
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.secondaryContainer.withOpacity(0.55),
                theme.colorScheme.surface.withOpacity(0.95),
              ],
            ),
            border: Border.all(
              color: theme.colorScheme.secondary,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.secondary.withOpacity(0.15),
                offset: const Offset(0, 6),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ProfileAvatar(
                    initials: _parentInitials,
                    imageUrl: _parentImage,
                    radius: 26,
                    backgroundColor: theme.colorScheme.secondaryContainer,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.onSecondary,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.shield_outlined,
                        size: 14,
                        color: theme.colorScheme.onSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _parentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Tap to open ${previewChild.displayName}\'s dashboard',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.touch_app_outlined,
                color: theme.colorScheme.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildContextCallout extends StatelessWidget {
  const _ChildContextCallout({
    required this.pendingCount,
    this.errorMessage,
  });

  final int pendingCount;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.6),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.family_restroom,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Link your child',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (pendingCount > 0)
                  Text(
                    '$pendingCount pending approval(s)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  Text(
                    'Add your child to view dashboards and progress.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => GoRouter.of(context).go('/profile'),
            child: const Text('Manage'),
          ),
        ],
      ),
    );
  }
}
