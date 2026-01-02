import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/student_profile.dart';
import '../../../../core/domain/user_profile.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/app_toast.dart';
import '../../../../core/data/api_client.dart';
import '../../../../core/theme/tokens.dart';
import '../application/parent_children_controller.dart';
import '../data/profile_repository.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../../core/domain/avatar_catalog.dart';
import 'student_avatar_picker_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);

    return SafeArea(
      child: userAsync.when(
        loading: () => const _LoadingState(),
        error: (error, stackTrace) =>
            _ErrorState(message: error.toString(), stackTrace: stackTrace),
        data: (user) {
          if (user.isParent) {
            return _ParentProfileView(user: user);
          }
          return _BasicProfileView(user: user);
        },
      ),
    );
  }
}

class _ParentProfileView extends ConsumerWidget {
  const _ParentProfileView({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final parentChildrenAsync = ref.watch(parentChildrenControllerProvider);
    final parentChildrenNotifier =
        ref.watch(parentChildrenControllerProvider.notifier);

    Future<void> handleRefresh() async {
      ref.invalidate(currentUserProfileProvider);
      await parentChildrenNotifier.refresh();
    }

    Future<void> handleChooseAvatar(StudentProfile child) async {
      final currentAvatarId =
          AvatarCatalog.resolveStudentAvatar(child.profileImageUrl)?.id;
      final result = await showStudentAvatarPicker(
        context: context,
        childName: child.displayName,
        initialAvatarId: currentAvatarId,
      );

      if (!context.mounted || result == null) {
        return;
      }

      final avatarId =
          result.resetToInitials ? null : result.avatarId ?? currentAvatarId;

      await parentChildrenNotifier.assignAvatar(
        studentId: child.id,
        avatarId: avatarId,
      );
    }

    return parentChildrenAsync.when(
      loading: () => const _LoadingState(),
      error: (error, stackTrace) =>
          _ErrorState(message: error.toString(), stackTrace: stackTrace),
      data: (state) {
        final selectedChild = authState.selectedChild;

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.35),
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: RefreshIndicator(
            onRefresh: handleRefresh,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _ParentHeader(
                      user: user,
                      selectedChild: selectedChild,
                      onCopyEmail: () async {
                        await Clipboard.setData(
                          ClipboardData(text: user.email),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Email copied')),
                          );
                        }
                      },
                      onEditProfile: () => _showEditProfileSheet(context, user),
                    ),
                  ),
                ),
                if (state.hasPendingRequests)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _ActionBanner(
                        icon: Icons.fact_check_outlined,
                        title:
                            'You have ${state.pendingRequests.length} pending enrolment requests',
                        ctaLabel: 'Review',
                        onTap: () => _showPendingRequestsSheet(
                          context,
                          state.pendingRequests,
                          parentChildrenNotifier,
                        ),
                      ),
                    ),
                  ),
                if (state.hasDuplicateProfiles)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _ActionBanner(
                        icon: Icons.compare_arrows_outlined,
                        title: 'Possible duplicate profiles detected',
                        ctaLabel: 'Resolve',
                        onTap: () => _showDuplicatesSheet(
                          context,
                          state.duplicateProfiles,
                          parentChildrenNotifier,
                        ),
                        variant: ActionBannerVariant.warning,
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _MyChildrenSection(
                      state: state,
                      isProcessing: state.isProcessing,
                      selectedChildId: selectedChild?.id,
                      onChooseAvatar: handleChooseAvatar,
                      onSwitchToChild: (child) {
                        final router = GoRouter.of(context);
                        final parentLocation = router
                            .routerDelegate.currentConfiguration.uri
                            .toString();
                        ref.read(authProvider.notifier).switchToChild(
                              child,
                              parentLocation: parentLocation,
                            );
                      },
                      onSwitchToParent: () {
                        final router = GoRouter.of(context);
                        final currentLocation = router
                            .routerDelegate.currentConfiguration.uri
                            .toString();
                        final parentLocation =
                            ref.read(authProvider).parentViewLocation;
                        ref.read(authProvider.notifier).switchToParent();
                        if (parentLocation != null &&
                            currentLocation != parentLocation) {
                          router.go(parentLocation);
                        }
                      },
                      onRemoveChild: parentChildrenNotifier.removeChild,
                      onAddChild: () => _showAddChildSheet(
                        context,
                        ref,
                        parentChildrenNotifier,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _ParentQuickLinks(
                      onManageNotifications: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notifications screen coming soon'),
                          ),
                        );
                      },
                      onOpenSettings: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Account settings coming soon'),
                          ),
                        );
                      },
                      onHelp: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Support center coming soon'),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MyChildrenSection extends StatelessWidget {
  const _MyChildrenSection({
    required this.state,
    required this.isProcessing,
    required this.selectedChildId,
    required this.onSwitchToChild,
    required this.onSwitchToParent,
    required this.onRemoveChild,
    required this.onAddChild,
    required this.onChooseAvatar,
  });

  final ParentChildrenState state;
  final bool isProcessing;
  final String? selectedChildId;
  final ValueChanged<StudentProfile> onSwitchToChild;
  final VoidCallback onSwitchToParent;
  final Future<void> Function(String studentId) onRemoveChild;
  final VoidCallback onAddChild;
  final ValueChanged<StudentProfile> onChooseAvatar;

  @override
  Widget build(BuildContext context) {
    if (state.showAddChildCallout) {
      return _EmptyChildrenCallout(onAddChild: onAddChild);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'My children',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: isProcessing ? null : onAddChild,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Add child'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Choose a profile to switch context instantly or explore family settings.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: state.children.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              if (index == state.children.length) {
                return _AddChildTile(onTap: onAddChild);
              }
              final child = state.children[index];
              return _ChildTile(
                child: child,
                isActive: selectedChildId == child.id,
                onSwitchToChild: onSwitchToChild,
                onSwitchToParent: onSwitchToParent,
                onRemoveChild: onRemoveChild,
                onChooseAvatar: onChooseAvatar,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChildTile extends StatelessWidget {
  const _ChildTile({
    required this.child,
    required this.isActive,
    required this.onSwitchToChild,
    required this.onSwitchToParent,
    required this.onRemoveChild,
    required this.onChooseAvatar,
  });

  final StudentProfile child;
  final bool isActive;
  final ValueChanged<StudentProfile> onSwitchToChild;
  final VoidCallback onSwitchToParent;
  final Future<void> Function(String studentId) onRemoveChild;
  final ValueChanged<StudentProfile> onChooseAvatar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant.withOpacity(0.4);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        gradient: LinearGradient(
          colors: isActive
              ? [
                  theme.colorScheme.primaryContainer.withOpacity(0.65),
                  theme.colorScheme.surface,
                ]
              : [
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceVariant.withOpacity(0.3),
                ],
        ),
        border: Border.all(color: borderColor, width: isActive ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(isActive ? 0.18 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: isActive ? onSwitchToParent : () => onSwitchToChild(child),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _Avatar(
                    initials: child.initials,
                    imageUrl: child.profileImageUrl,
                    radius: 30,
                    backgroundColor: theme.colorScheme.secondaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          child.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${child.gradeDisplay} • ${child.mediumDisplay}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<_ChildAction>(
                    icon: const Icon(Icons.more_horiz),
                    splashRadius: 20,
                    onSelected: (action) async {
                      switch (action) {
                        case _ChildAction.chooseAvatar:
                          onChooseAvatar(child);
                          break;
                        case _ChildAction.edit:
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Edit profile coming soon'),
                            ),
                          );
                          break;
                        case _ChildAction.remove:
                          await onRemoveChild(child.id);
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _ChildAction.chooseAvatar,
                        child: Text('Choose avatar'),
                      ),
                      PopupMenuItem(
                        value: _ChildAction.edit,
                        child: Text('Edit profile'),
                      ),
                      PopupMenuItem(
                        value: _ChildAction.remove,
                        child: Text('Remove child'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (child.address?.isNotEmpty == true)
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
                        child.address!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              const Spacer(),
              Row(
                children: [
                  _StatusPill(
                    icon: child.hasLinkedLogin
                        ? Icons.verified_user_outlined
                        : Icons.person_outline,
                    label:
                        child.hasLinkedLogin ? 'Linked login' : 'Profile only',
                    color: child.hasLinkedLogin
                        ? theme.colorScheme.primary
                        : theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  if (isActive)
                    _StatusPill(
                      icon: Icons.visibility,
                      label: 'Active',
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                onPressed: () {
                  context.go('/student-activity/${child.id}');
                },
                icon: const Icon(Icons.insights_outlined, size: 18),
                label: const Text('View Activity'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 36),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddChildTile extends StatelessWidget {
  const _AddChildTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        width: 220,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.15),
              theme.colorScheme.primaryContainer.withOpacity(0.6),
            ],
          ),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.45),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: theme.colorScheme.primary,
                size: 36,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Link or create child',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyChildrenCallout extends StatelessWidget {
  const _EmptyChildrenCallout({required this.onAddChild});

  final VoidCallback onAddChild;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Let’s add your child',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Start by creating a new profile or link an existing account shared by a teacher.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onAddChild,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Add Child'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParentHeader extends StatelessWidget {
  const _ParentHeader({
    required this.user,
    required this.selectedChild,
    required this.onCopyEmail,
    required this.onEditProfile,
  });

  final UserProfile user;
  final StudentProfile? selectedChild;
  final VoidCallback onCopyEmail;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.9),
            theme.colorScheme.surface,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.15),
            offset: const Offset(0, 12),
            blurRadius: 24,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(
                  initials: user.initials,
                  imageUrl: user.profileImageUrl,
                  radius: 38,
                  backgroundColor: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Family account owner',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer
                              .withOpacity(0.85),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      InkWell(
                        onTap: onCopyEmail,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: AppSpacing.xxs,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.mail_outline,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Flexible(
                                child: Text(
                                  user.email,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                    decoration: TextDecoration.underline,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Parent',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _HeaderActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit profile',
                  onTap: onEditProfile,
                ),
                _HeaderActionButton(
                  icon: Icons.copy_all_outlined,
                  label: 'Copy email',
                  onTap: onCopyEmail,
                ),
                _HeaderActionButton(
                  icon: Icons.family_restroom_outlined,
                  label: 'Manage family',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Family settings coming soon'),
                    ),
                  ),
                ),
                _HeaderActionButton(
                  icon: Icons.support_agent_outlined,
                  label: 'Contact support',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Support center will open in a future release'),
                    ),
                  ),
                ),
              ],
            ),
            if (selectedChild != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.4),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      _Avatar(
                        initials: selectedChild!.initials,
                        imageUrl: selectedChild!.profileImageUrl,
                        radius: 24,
                        backgroundColor: theme.colorScheme.secondaryContainer,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Currently viewing',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              selectedChild!.displayName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.visibility_outlined,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 18,
        color: theme.colorScheme.primary,
      ),
      label: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        backgroundColor: theme.colorScheme.surface.withOpacity(0.85),
      ),
    );
  }
}

class _ParentQuickLinks extends StatelessWidget {
  const _ParentQuickLinks({
    required this.onManageNotifications,
    required this.onOpenSettings,
    required this.onHelp,
  });

  final VoidCallback onManageNotifications;
  final VoidCallback onOpenSettings;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Parent tools',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                _QuickLink(
                  icon: Icons.notifications_active_outlined,
                  label: 'Alerts & notifications',
                  onTap: onManageNotifications,
                ),
                _QuickLink(
                  icon: Icons.settings_outlined,
                  label: 'Account settings',
                  onTap: onOpenSettings,
                ),
                _QuickLink(
                  icon: Icons.help_outline,
                  label: 'Help & support',
                  onTap: onHelp,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        width: 190,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          color: theme.colorScheme.surface,
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.open_in_new,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileEditSheet extends ConsumerStatefulWidget {
  const _ProfileEditSheet({required this.user});

  final UserProfile user;

  @override
  ConsumerState<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends ConsumerState<_ProfileEditSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.user.firstName.trim());
    _lastNameController =
        TextEditingController(text: widget.user.lastName.trim());
    _phoneController =
        TextEditingController(text: widget.user.phoneNumber ?? '');
    _addressController = TextEditingController(text: widget.user.address ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final notifier = ref.read(authProvider.notifier);
    try {
      await notifier.updateUserProfileDetails(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
      );

      if (!mounted) return;

      Navigator.of(context).pop();
      AppToast.success('Profile updated successfully.');
    } on ApiException {
      if (!mounted) return;
      setState(() => _isSaving = false);
      // Error toast already shown via ApiClient.
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppToast.error('Unable to update profile. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Edit profile',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Update how your name and contact details appear across the family dashboard.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _ProfileTextField(
                  controller: _firstNameController,
                  label: 'First name',
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'First name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _ProfileTextField(
                  controller: _lastNameController,
                  label: 'Last name',
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Last name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _ProfileTextField(
                  controller: _phoneController,
                  label: 'Mobile number',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return null;
                    }
                    final digits = trimmed.replaceAll(RegExp(r'[^0-9+]'), '');
                    if (digits.length < 7) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _ProfileTextField(
                  controller: _addressController,
                  label: 'Address',
                  textInputAction: TextInputAction.done,
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () {
                                Navigator.of(context).pop();
                              },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSaving ? null : _handleSave,
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save changes'),
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
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.controller,
    required this.label,
    this.validator,
    this.maxLines = 1,
    this.textInputAction,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}

class _BasicProfileView extends StatelessWidget {
  const _BasicProfileView({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.4),
            theme.colorScheme.surface,
          ],
        ),
      ),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _Avatar(
                        initials: user.initials,
                        imageUrl: user.profileImageUrl,
                        radius: 36,
                        backgroundColor: theme.colorScheme.secondaryContainer,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              user.email,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Looking to manage multiple learners? Switch to a parent account to access kid profiles, progress dashboards, and family tools.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Parent enrolment guidance will be available soon.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.info_outline),
                        label: const Text('Why create a parent profile?'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Contact support to upgrade your access.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.upgrade_outlined),
                        label: const Text('Request parent access'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, this.stackTrace});

  final String message;
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.initials,
    this.imageUrl,
    this.radius = 28,
    this.backgroundColor,
  });

  final String initials;
  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ProfileAvatar(
      initials: initials,
      imageUrl: imageUrl,
      radius: radius,
      backgroundColor:
          backgroundColor ?? Theme.of(context).colorScheme.primaryContainer,
    );
  }
}

enum _ChildAction { chooseAvatar, edit, remove }

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum ActionBannerVariant { info, warning }

class _ActionBanner extends StatelessWidget {
  const _ActionBanner({
    required this.icon,
    required this.title,
    required this.ctaLabel,
    required this.onTap,
    this.variant = ActionBannerVariant.info,
  });

  final IconData icon;
  final String title;
  final String ctaLabel;
  final VoidCallback onTap;
  final ActionBannerVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = variant == ActionBannerVariant.info
        ? theme.colorScheme.primary
        : theme.colorScheme.error;

    return Card(
      color: color.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: onTap,
              child: Text(ctaLabel),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showAddChildSheet(
  BuildContext context,
  WidgetRef ref,
  ParentChildrenController notifier,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return _AddChildSheet(notifier: notifier);
    },
  );
}

class _AddChildSheet extends ConsumerStatefulWidget {
  const _AddChildSheet({required this.notifier});

  final ParentChildrenController notifier;

  @override
  ConsumerState<_AddChildSheet> createState() => _AddChildSheetState();
}

class _AddChildSheetState extends ConsumerState<_AddChildSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _gradeController = TextEditingController();
  final _addressController = TextEditingController();
  final _citiesController = TextEditingController();
  final _parentContactController = TextEditingController();

  String _medium = 'ENGLISH';
  bool _isSubmitting = false;
  int _tabIndex = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _gradeController.dispose();
    _addressController.dispose();
    _citiesController.dispose();
    _parentContactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DefaultTabController(
        length: 2,
        initialIndex: _tabIndex,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            Container(
              height: 4,
              width: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Add Child',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TabBar(
              onTap: (idx) => setState(() => _tabIndex = idx),
              tabs: const [
                Tab(text: 'Create new profile'),
                Tab(text: 'Link existing'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildCreateForm(theme),
                  _buildLinkForm(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Child name'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _gradeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Grade'),
              validator: (value) {
                final parsed = int.tryParse(value ?? '');
                if (parsed == null) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Medium'),
              value: _medium,
              items: const [
                DropdownMenuItem(value: 'ENGLISH', child: Text('English')),
                DropdownMenuItem(value: 'SINHALA', child: Text('Sinhala')),
                DropdownMenuItem(value: 'TAMIL', child: Text('Tamil')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _medium = value);
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'School / address'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _citiesController,
              decoration: const InputDecoration(
                labelText: 'Cities',
                helperText: 'Separate multiple cities with commas',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _parentContactController,
              decoration: const InputDecoration(
                labelText: 'Parent contact (optional)',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;
                      setState(() => _isSubmitting = true);
                      final cities = _citiesController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();
                      await widget.notifier.createChild(
                        name: _nameController.text.trim(),
                        grade: int.parse(_gradeController.text),
                        medium: _medium,
                        address: _addressController.text.trim(),
                        cities: cities,
                        parentContact: _parentContactController.text.trim(),
                      );
                      if (mounted) {
                        setState(() => _isSubmitting = false);
                        Navigator.of(context).pop();
                      }
                    },
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create child'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkForm(ThemeData theme) {
    final controller = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Text(
            'Have a code or phone number from your child’s teacher? Enter it below and we’ll send a request.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Student code or mobile number',
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Link request feature will be available soon.',
                  ),
                ),
              );
            },
            child: const Text('Send request'),
          ),
        ],
      ),
    );
  }
}

void _showPendingRequestsSheet(
  BuildContext context,
  List<PendingChildRequest> requests,
  ParentChildrenController notifier,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return _PendingRequestsSheet(
        requests: requests,
        notifier: notifier,
      );
    },
  );
}

class _PendingRequestsSheet extends StatelessWidget {
  const _PendingRequestsSheet({
    required this.requests,
    required this.notifier,
  });

  final List<PendingChildRequest> requests;
  final ParentChildrenController notifier;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Pending enrolment requests',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...requests.map(
              (request) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.student.displayName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          request.classDetails,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Requested by ${request.teacherName} • ${request.instituteName}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  notifier.rejectPendingRequest(
                                    request.requestId,
                                  );
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Rejecting requests will be available soon.',
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  notifier.approvePendingRequest(
                                    request.requestId,
                                  );
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Approving requests will be available soon.',
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Approve'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showDuplicatesSheet(
  BuildContext context,
  List<DuplicateStudentProfile> duplicates,
  ParentChildrenController notifier,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return _DuplicateProfilesSheet(
        duplicates: duplicates,
        notifier: notifier,
      );
    },
  );
}

Future<void> _showEditProfileSheet(
  BuildContext context,
  UserProfile user,
) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _ProfileEditSheet(user: user),
  );
}

class _DuplicateProfilesSheet extends StatefulWidget {
  const _DuplicateProfilesSheet({
    required this.duplicates,
    required this.notifier,
  });

  final List<DuplicateStudentProfile> duplicates;
  final ParentChildrenController notifier;

  @override
  State<_DuplicateProfilesSheet> createState() =>
      _DuplicateProfilesSheetState();
}

class _DuplicateProfilesSheetState extends State<_DuplicateProfilesSheet> {
  final Set<String> _selected = {};
  String? _mergedName;
  int? _mergedGrade;
  String? _mergedMedium;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Resolve duplicate profiles',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...widget.duplicates.map(
              (duplicate) => CheckboxListTile(
                value: _selected.contains(duplicate.duplicateId),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selected.add(duplicate.duplicateId);
                      _mergedName ??= duplicate.student.name;
                      _mergedGrade ??= duplicate.student.grade;
                      _mergedMedium ??= duplicate.student.medium;
                    } else {
                      _selected.remove(duplicate.duplicateId);
                    }
                  });
                },
                title: Text(duplicate.student.displayName),
                subtitle: Text(
                  '${duplicate.enrollmentCount} enrolments • ${duplicate.createdBy}',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_selected.isNotEmpty)
              Column(
                children: [
                  TextFormField(
                    initialValue: _mergedName,
                    decoration:
                        const InputDecoration(labelText: 'Canonical name'),
                    onChanged: (value) => _mergedName = value,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    initialValue: _mergedGrade != null ? '$_mergedGrade' : null,
                    decoration:
                        const InputDecoration(labelText: 'Grade (optional)'),
                    onChanged: (value) =>
                        _mergedGrade = int.tryParse(value.trim()),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    initialValue: _mergedMedium,
                    decoration:
                        const InputDecoration(labelText: 'Medium (optional)'),
                    onChanged: (value) => _mergedMedium = value.trim(),
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () {
                      widget.notifier.mergeDuplicates(
                        _selected.toList(),
                        mergedName: _mergedName,
                        mergedGrade: _mergedGrade,
                        mergedMedium: _mergedMedium,
                      );
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Duplicate resolution will be available soon.',
                          ),
                        ),
                      );
                    },
              child: const Text('Merge now'),
            ),
          ],
        ),
      ),
    );
  }
}
