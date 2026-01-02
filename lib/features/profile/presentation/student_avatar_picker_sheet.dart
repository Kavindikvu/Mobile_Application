import 'package:characters/characters.dart';
import 'package:flutter/material.dart';

import '../../../../core/domain/avatar_catalog.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/profile_avatar.dart';

class StudentAvatarPickerResult {
  const StudentAvatarPickerResult._({
    this.avatarId,
    this.resetToInitials = false,
  });

  final String? avatarId;
  final bool resetToInitials;

  static StudentAvatarPickerResult select(String avatarId) =>
      StudentAvatarPickerResult._(avatarId: avatarId);

  static const StudentAvatarPickerResult reset =
      StudentAvatarPickerResult._(avatarId: null, resetToInitials: true);
}

Future<StudentAvatarPickerResult?> showStudentAvatarPicker({
  required BuildContext context,
  required String childName,
  String? initialAvatarId,
}) {
  return showModalBottomSheet<StudentAvatarPickerResult>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return _StudentAvatarPickerSheet(
        childName: childName,
        initialAvatarId: initialAvatarId,
      );
    },
  );
}

class _StudentAvatarPickerSheet extends StatefulWidget {
  const _StudentAvatarPickerSheet({
    required this.childName,
    this.initialAvatarId,
  });

  final String childName;
  final String? initialAvatarId;

  @override
  State<_StudentAvatarPickerSheet> createState() =>
      _StudentAvatarPickerSheetState();
}

class _StudentAvatarPickerSheetState
    extends State<_StudentAvatarPickerSheet> {
  late String? _selectedAvatarId = widget.initialAvatarId;

  void _selectAvatar(String avatarId) {
    Navigator.of(context).pop(StudentAvatarPickerResult.select(avatarId));
  }

  void _resetAvatar() {
    Navigator.of(context).pop(StudentAvatarPickerResult.reset);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Choose an avatar',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Pick a character for ${widget.childName}. You can change this anytime.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 320,
                child: GridView.builder(
                  shrinkWrap: true,
                  itemCount: AvatarCatalog.studentAvatars.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.78,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final option = AvatarCatalog.studentAvatars[index];
                    final isSelected = option.id == _selectedAvatarId;
                    return _AvatarOptionTile(
                      option: option,
                      isSelected: isSelected,
                      onTap: () => _selectAvatar(option.id),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetAvatar,
                      child: const Text('Use initials'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('Maybe later'),
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
}

class _AvatarOptionTile extends StatelessWidget {
  const _AvatarOptionTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final AvatarOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.md),
          color: theme.colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withOpacity(0.4),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(
                isSelected ? 0.16 : 0.08,
              ),
              blurRadius: isSelected ? 18 : 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ProfileAvatar(
              initials: option.label.characters.first,
              imageUrl: '$kAvatarScheme${option.id}',
              radius: 30,
              backgroundColor: theme.colorScheme.primaryContainer,
              showBorder: isSelected,
              borderColor: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              option.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

