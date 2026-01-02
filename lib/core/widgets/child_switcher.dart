import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../theme/tokens.dart';
import '../strings/app_strings.dart';
import '../theme/haptics.dart';
import '../../features/profile/application/parent_children_controller.dart';
import '../domain/student_profile.dart';
import '../domain/user_profile.dart';
import '../services/app_toast.dart';
import 'profile_avatar.dart';

class ChildSwitcher extends ConsumerStatefulWidget {
  const ChildSwitcher({super.key});

  @override
  ConsumerState<ChildSwitcher> createState() => _ChildSwitcherState();
}

class _ChildSwitcherState extends ConsumerState<ChildSwitcher> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final childrenAsync = ref.watch(parentChildrenControllerProvider);

    // Only show for parents
    if (!authState.isParent) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final bottomPadding =
        MediaQuery.of(context).viewPadding.bottom + AppSpacing.lg;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.of(context).size.height * 0.9;

          return SizedBox(
            height: availableHeight,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primaryContainer.withOpacity(0.55),
                    theme.colorScheme.surface,
                  ],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  bottomPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outlineVariant
                              .withOpacity(0.45),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SwitcherIntro(
                      isParentMode: !authState.hasSelectedChild,
                      activeChildName: authState.selectedChild?.displayName,
                      totalChildren: childrenAsync.maybeWhen(
                            data: (state) => state.children.length,
                            orElse: () => null,
                          ) ??
                          (authState.hasSelectedChild ? 1 : 0),
                      pendingLinks: childrenAsync.maybeWhen(
                            data: (state) => state.pendingRequests.length,
                            orElse: () => 0,
                          ) ??
                          0,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Flexible(
                      child: childrenAsync.when(
                        loading: () => const _LoadingChildren(),
                        error: (error, stackTrace) =>
                            _ErrorChildren(error: error.toString()),
                        data: (state) => _ChildSwitcherDataView(
                          parent: authState.user,
                          selectedChild: authState.selectedChild,
                          children: state.children,
                          isProcessing: state.isProcessing,
                          showParentTile: authState.hasSelectedChild,
                          onSwitchParent: () => _switchToParent(context),
                          onSwitchChild: (child) =>
                              _switchToChild(context, child),
                          onManageProfiles: () =>
                              _navigateToProfile(context, highlightAdd: false),
                          onAddChild: () =>
                              _navigateToProfile(context, highlightAdd: true),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _switchToChild(BuildContext context, StudentProfile child) {
    final router = GoRouter.of(context);
    final parentLocation =
        router.routerDelegate.currentConfiguration.uri.toString();
    Navigator.of(context).maybePop();
    ref.read(authProvider.notifier).switchToChild(
      child,
      parentLocation: parentLocation,
    );
    AppHaptics.selectionClick();
    AppToast.info('${AppStrings.switchedTo} ${child.displayName}');
  }

  void _switchToParent(BuildContext context) {
    final router = GoRouter.of(context);
    final parentLocation = ref.read(authProvider).parentViewLocation;
    final currentLocation =
        router.routerDelegate.currentConfiguration.uri.toString();
    Navigator.of(context).maybePop();
    ref.read(authProvider.notifier).switchToParent();
    AppHaptics.selectionClick();
    AppToast.info(AppStrings.switchedBackToParent);
    if (parentLocation != null && currentLocation != parentLocation) {
      Future.microtask(() {
        if (!mounted) return;
        context.go(parentLocation);
      });
    }
  }

  void _navigateToProfile(
    BuildContext context, {
    required bool highlightAdd,
  }) {
    Navigator.of(context).pop();
    AppHaptics.selectionClick();
    Future.microtask(() {
      if (!mounted) return;
      final intentRoute =
          highlightAdd ? '/profile?intent=create-child' : '/profile';
      context.go(intentRoute);
      if (highlightAdd) {
        AppToast.info(
          'On the profile screen, tap "Add child" to create a new learner.',
        );
      }
    });
  }
}

class _SwitcherIntro extends StatelessWidget {
  const _SwitcherIntro({
    required this.isParentMode,
    required this.totalChildren,
    required this.pendingLinks,
    this.activeChildName,
  });

  final bool isParentMode;
  final int totalChildren;
  final int pendingLinks;
  final String? activeChildName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final headline = isParentMode
        ? 'Parent mode'
        : 'Learning with ${activeChildName ?? 'learner'}';
    final description = isParentMode
        ? 'Who’s ready to learn today? Pick a profile to jump into their world.'
        : 'You’re viewing ${activeChildName ?? 'this learner'}’s journey. Switch profiles anytime to explore their progress.';
    final learnerLabel = totalChildren == 1
        ? '1 linked learner'
        : '$totalChildren linked learners';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 24),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primaryContainer.withOpacity(0.85),
              theme.colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.16),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Icon(
                    Icons.switch_account,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.switchContext,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        headline,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _SwitcherStatChip(
                  icon: isParentMode
                      ? Icons.shield_outlined
                      : Icons.school_outlined,
                  label: isParentMode ? 'Parent protected' : 'Student view',
                  color: theme.colorScheme.primary,
                ),
                _SwitcherStatChip(
                  icon: Icons.people_alt_outlined,
                  label: learnerLabel,
                  color: theme.colorScheme.secondary,
                ),
                if (pendingLinks > 0)
                  _SwitcherStatChip(
                    icon: Icons.hourglass_bottom_rounded,
                    label: '$pendingLinks pending approval${pendingLinks == 1 ? '' : 's'}',
                    color: theme.colorScheme.tertiary,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildSwitcherDataView extends StatelessWidget {
  const _ChildSwitcherDataView({
    required this.parent,
    required this.selectedChild,
    required this.children,
    required this.showParentTile,
    required this.isProcessing,
    required this.onSwitchParent,
    required this.onSwitchChild,
    required this.onManageProfiles,
    required this.onAddChild,
  });

  final UserProfile? parent;
  final StudentProfile? selectedChild;
  final List<StudentProfile> children;
  final bool showParentTile;
  final bool isProcessing;
  final VoidCallback onSwitchParent;
  final ValueChanged<StudentProfile> onSwitchChild;
  final VoidCallback onManageProfiles;
  final VoidCallback onAddChild;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isParentMode = selectedChild == null;
    final heroChild =
        selectedChild ?? (children.isNotEmpty ? children.first : null);

    if (children.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (parent != null || heroChild != null)
            _ContextHeroBanner(
              parent: parent,
              child: heroChild,
              isParentMode: isParentMode,
              totalChildren: children.length,
            ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.15),
                ),
              ),
              child: const _EmptyChildren(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ActionButtons(
            onManageProfiles: onManageProfiles,
            onAddChild: onAddChild,
            isProcessing: isProcessing,
          ),
          const SizedBox(height: AppSpacing.sm),
          const _SwitcherFooterNotice(),
        ],
      );
    }

    final tiles = <Widget>[];
    if (showParentTile && parent != null) {
      tiles.add(
        _ParentContextTile(
          parent: parent!,
          lastViewedChild: heroChild,
          onTap: onSwitchParent,
        ),
      );
    }
    tiles.addAll(
      children.map(
        (child) => _ChildOptionCard(
          child: child,
          isSelected: selectedChild?.id == child.id,
          onTap: () => onSwitchChild(child),
        ),
      ),
    );

    final availableWidth = MediaQuery.of(context).size.width -
        (AppSpacing.lg * 2); // approximate modal horizontal padding
    final crossAxisCount = availableWidth > 520
        ? 3
        : availableWidth > 360
            ? 2
            : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ContextHeroBanner(
          parent: parent,
          child: heroChild,
          isParentMode: isParentMode,
          totalChildren: children.length,
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisExtent: 240,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
            ),
            itemCount: tiles.length,
            itemBuilder: (context, index) => tiles[index],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _ActionButtons(
          onManageProfiles: onManageProfiles,
          onAddChild: onAddChild,
          isProcessing: isProcessing,
        ),
        const SizedBox(height: AppSpacing.sm),
        const _SwitcherFooterNotice(),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.onManageProfiles,
    required this.onAddChild,
    required this.isProcessing,
  });

  final VoidCallback onManageProfiles;
  final VoidCallback onAddChild;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        OutlinedButton.icon(
          onPressed: isProcessing ? null : onManageProfiles,
          icon: const Icon(Icons.manage_accounts),
          label: const Text('Manage profiles'),
        ),
        FilledButton.icon(
          onPressed: isProcessing ? null : onAddChild,
          icon: const Icon(Icons.add_circle),
          label: const Text('Add child'),
        ),
      ],
    );
  }
}

class _SwitcherFooterNotice extends StatelessWidget {
  const _SwitcherFooterNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Text(
          'Switching profiles keeps recommendations, attendance, and progress tailored to each learner.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}

class _ParentContextTile extends StatelessWidget {
  final UserProfile parent;
  final StudentProfile? lastViewedChild;
  final VoidCallback onTap;

  const _ParentContextTile({
    required this.parent,
    this.lastViewedChild,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.18),
            theme.colorScheme.primaryContainer.withOpacity(0.5),
          ],
        ),
        border: Border.all(color: theme.colorScheme.primary, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.15),
            offset: const Offset(0, 6),
            blurRadius: 12,
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ProfileAvatar(
                    initials: parent.initials,
                    imageUrl: parent.profileImageUrl,
                    radius: 34,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    showBorder: true,
                    borderColor: theme.colorScheme.primary,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.onPrimary,
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.shield_moon,
                        size: 16,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Back to parent view',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                lastViewedChild != null
                    ? 'You were exploring ${lastViewedChild!.displayName}.'
                    : 'Return to your parent dashboard.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildOptionCard extends StatelessWidget {
  final StudentProfile child;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChildOptionCard({
    required this.child,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final outline = theme.colorScheme.outlineVariant.withOpacity(0.3);

    return AnimatedScale(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      scale: isSelected ? 1.02 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primary.withOpacity(0.55),
                    primary.withOpacity(0.25),
                  ],
                )
              : null,
          color: isSelected
              ? primary.withOpacity(0.08)
              : surface.withOpacity(0.96),
          border: Border.all(
            color: isSelected ? primary.withOpacity(0.65) : outline,
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(
                isSelected ? 0.16 : 0.06,
              ),
              blurRadius: isSelected ? 18 : 12,
              offset: Offset(0, isSelected ? 10 : 6),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            splashColor: primary.withOpacity(0.08),
            highlightColor: primary.withOpacity(0.04),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showStatusRow = constraints.maxHeight >= 260 &&
                    constraints.maxWidth >= 220;

                final horizontalPadding = showStatusRow ? AppSpacing.md : AppSpacing.sm;
                final verticalPadding =
                    showStatusRow ? AppSpacing.md : AppSpacing.xxs / 2;
                final compactSpacing =
                    showStatusRow ? AppSpacing.sm : AppSpacing.xxs / 2;

                if (showStatusRow) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ChildAvatar(
                          child: child,
                          radius: 34,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          child.displayName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            _SwitcherStatChip(
                              icon: Icons.workspace_premium_outlined,
                              label: child.gradeDisplay,
                              color: theme.colorScheme.secondary,
                            ),
                            _SwitcherStatChip(
                              icon: Icons.translate_outlined,
                              label: child.mediumDisplay,
                              color: theme.colorScheme.tertiary,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 220),
                          opacity: isSelected ? 1 : 0.9,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.touch_app_outlined,
                                size: 16,
                                color: primary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                isSelected
                                    ? 'You’re here'
                                    : 'Tap to explore',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: _buildCompactContent(
                    context: context,
                    constraints: constraints,
                    theme: theme,
                    primary: primary,
                    spacing: compactSpacing,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactContent({
    required BuildContext context,
    required BoxConstraints constraints,
    required ThemeData theme,
    required Color primary,
    required double spacing,
  }) {
    final availableHeight = constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : double.infinity;

    final double avatarRadius;
    if (availableHeight >= 220) {
      avatarRadius = 30;
    } else if (availableHeight >= 200) {
      avatarRadius = 28;
    } else if (availableHeight >= 180) {
      avatarRadius = 26;
    } else {
      avatarRadius = 24;
    }

    final bool showMetaLine =
        availableHeight >= 188 && child.gradeDisplay.trim().isNotEmpty;
    final bool showMediumFallback =
        !showMetaLine && child.mediumDisplay.trim().isNotEmpty;
    final bool showActionHint = availableHeight >= 172;

    final double gap;
    if (availableHeight >= 220) {
      gap = AppSpacing.sm;
    } else if (availableHeight >= 200) {
      gap = AppSpacing.xs;
    } else {
      gap = AppSpacing.xxs;
    }

    final metaText = showMetaLine
        ? '${child.gradeDisplay.trim()} • ${child.mediumDisplay.trim()}'.trim()
        : showMediumFallback
            ? child.mediumDisplay.trim()
            : child.gradeDisplay.trim();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ChildAvatar(
          child: child,
          radius: avatarRadius,
        ),
        SizedBox(height: gap),
        Text(
          child.displayName,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (metaText.isNotEmpty) ...[
          SizedBox(height: gap),
          Text(
            metaText,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (showActionHint) ...[
          SizedBox(height: gap),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: isSelected ? 1 : 0.9,
            child: Text(
              isSelected ? 'You’re here' : 'Tap to explore',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SwitcherStatChip extends StatelessWidget {
  const _SwitcherStatChip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = color ?? theme.colorScheme.onSurfaceVariant;
    final background = baseColor.withOpacity(color == null ? 0.08 : 0.16);
    final borderColor = baseColor.withOpacity(color == null ? 0.18 : 0.28);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: baseColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: baseColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum _ChipTone { primary, subtle }

class _ContextStatusChip extends StatelessWidget {
  const _ContextStatusChip({
    required this.label,
    required this.icon,
    this.tone = _ChipTone.primary,
  });

  final String label;
  final IconData icon;
  final _ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSubtle = tone == _ChipTone.subtle;
    final bgColor = isSubtle
        ? theme.colorScheme.surface.withOpacity(0.6)
        : theme.colorScheme.onSecondaryContainer.withOpacity(0.12);
    final foreground = isSubtle
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: foreground.withOpacity(isSubtle ? 0.2 : 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextHeroBanner extends StatelessWidget {
  const _ContextHeroBanner({
    required this.parent,
    required this.child,
    required this.isParentMode,
    this.totalChildren,
  });

  final UserProfile? parent;
  final StudentProfile? child;
  final bool isParentMode;
  final int? totalChildren;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final learner = child;
    final linkedCount = totalChildren ?? 0;
    final headline = isParentMode
        ? 'Choose who\'s learning'
        : 'Learning with ${learner?.displayName ?? 'your learner'}';
    final description = isParentMode
        ? 'Tap a profile below to jump into their adventure.'
        : 'Switch profiles to explore different learning journeys.';
    final avatarInitials =
        isParentMode ? (parent?.initials ?? '?') : (learner?.initials ?? '?');
    final avatarImage =
        isParentMode ? parent?.profileImageUrl : learner?.profileImageUrl;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isParentMode
              ? [
                  theme.colorScheme.secondaryContainer.withOpacity(0.7),
                  theme.colorScheme.secondaryContainer.withOpacity(0.35),
                ]
              : [
                  theme.colorScheme.tertiaryContainer.withOpacity(0.65),
                  theme.colorScheme.secondaryContainer.withOpacity(0.3),
                ],
        ),
      ),
      child: Row(
        children: [
          ProfileAvatar(
            initials: avatarInitials,
            imageUrl: avatarImage,
            radius: 40,
            backgroundColor: isParentMode
                ? theme.colorScheme.secondaryContainer
                : theme.colorScheme.tertiaryContainer,
            showBorder: true,
            borderColor: theme.colorScheme.primary.withOpacity(0.4),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _ContextStatusChip(
                      label: isParentMode ? 'Parent view' : 'Student view',
                      icon: isParentMode ? Icons.shield_outlined : Icons.school,
                    ),
                    if (!isParentMode && learner != null)
                      _ContextStatusChip(
                        label:
                            '${learner.gradeDisplay} • ${learner.mediumDisplay}',
                        icon: Icons.emoji_events_outlined,
                        tone: _ChipTone.subtle,
                      )
                    else if (isParentMode && linkedCount > 0)
                      _ContextStatusChip(
                        label: linkedCount == 1
                            ? '1 linked learner'
                            : '$linkedCount linked learners',
                        icon: Icons.group_outlined,
                        tone: _ChipTone.subtle,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  headline,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
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

class _ChildAvatar extends StatelessWidget {
  const _ChildAvatar({
    required this.child,
    this.radius = 24,
    this.backgroundColor,
  });

  final StudentProfile child;
  final double radius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ProfileAvatar(
      initials: child.initials,
      imageUrl: child.profileImageUrl,
      radius: radius,
      backgroundColor:
          backgroundColor ?? theme.colorScheme.tertiaryContainer,
    );
  }
}

class _LoadingChildren extends StatelessWidget {
  const _LoadingChildren();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorChildren extends StatelessWidget {
  final String error;

  const _ErrorChildren({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          'Error loading children: $error',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _EmptyChildren extends StatelessWidget {
  const _EmptyChildren();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Icon(
              Icons.child_care_outlined,
              size: 32,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
                        const SizedBox(height: AppSpacing.xs),
            Text(
              'No children added yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// Role-based navigation helper
class RoleBasedNavigation {
  static List<NavigationDestination> getDestinations({
    required BuildContext context,
    required String? profileImageUrl,
    required String profileInitials,
  }) {
    Widget buildMenuAvatar(bool isSelected) {
      final theme = Theme.of(context);
      final borderColor = isSelected
          ? theme.colorScheme.primary
          : theme.colorScheme.outlineVariant.withOpacity(0.6);

      Widget avatar = Container(
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1.2),
        ),
        child: ProfileAvatar(
          initials: profileInitials.isNotEmpty ? profileInitials : '?',
          imageUrl: profileImageUrl,
          radius: 15,
          backgroundColor: theme.colorScheme.primaryContainer,
        ),
      );

      return SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: avatar),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withOpacity(0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.menu,
                  size: 10,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return [
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: _GradientNavIcon(icon: Icons.home),
        label: AppStrings.home,
      ),
      const NavigationDestination(
        icon: Icon(Icons.search),
        selectedIcon: _GradientNavIcon(icon: Icons.search),
        label: AppStrings.discover,
      ),
      const NavigationDestination(
        icon: Icon(Icons.school_outlined),
        selectedIcon: _GradientNavIcon(icon: Icons.school),
        label: AppStrings.classes,
      ),
      const NavigationDestination(
        icon: Icon(Icons.storefront_outlined),
        selectedIcon: _GradientNavIcon(icon: Icons.storefront),
        label: AppStrings.marketplace,
      ),
      const NavigationDestination(
        icon: Icon(Icons.notifications_outlined),
        selectedIcon: _GradientNavIcon(icon: Icons.notifications),
        label: AppStrings.notifications,
      ),
      NavigationDestination(
        icon: buildMenuAvatar(false),
        selectedIcon: buildMenuAvatar(true),
        label: AppStrings.menu,
      ),
    ];
  }
}

class _GradientNavIcon extends StatelessWidget {
  final IconData icon;

  const _GradientNavIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          Color(AppColors.brandTeal),
          Color(AppColors.brandBlue),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Icon(
        icon,
        color: Colors.white,
      ),
    );
  }
}
