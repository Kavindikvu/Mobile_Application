import 'package:flutter/material.dart';

import '../domain/avatar_catalog.dart';

/// Shared avatar widget that understands remote images, assets, and catalog IDs.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.initials,
    this.imageUrl,
    this.radius = 24,
    this.backgroundColor,
    this.showBorder = false,
    this.borderColor,
    this.iconSizeFactor = 0.65,
  });

  final String initials;
  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;
  final bool showBorder;
  final Color? borderColor;
  final double iconSizeFactor;

  bool get _hasNetworkImage =>
      imageUrl != null &&
      imageUrl!.startsWith('http') &&
      !imageUrl!.contains('example.com');

  bool get _hasAssetImage => imageUrl != null && imageUrl!.startsWith('asset://');

  @override
  Widget build(BuildContext context) {
    final resolvedAvatar = AvatarCatalog.resolveStudentAvatar(imageUrl);
    final theme = Theme.of(context);

    Widget avatarChild;
    Decoration? decoration;

    if (resolvedAvatar != null) {
      decoration = BoxDecoration(
        shape: BoxShape.circle,
        gradient: resolvedAvatar.gradient,
        border: showBorder
            ? Border.all(
                color: borderColor ?? theme.colorScheme.surface,
                width: 2,
              )
            : null,
      );
      avatarChild = Icon(
        resolvedAvatar.icon,
        color: resolvedAvatar.iconColor,
        size: radius * (iconSizeFactor + 0.35),
      );
    } else if (_hasNetworkImage) {
      avatarChild = ClipOval(
        child: Image.network(
          imageUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _InitialsAvatar(
            initials: initials,
            radius: radius,
            backgroundColor: backgroundColor,
          ),
        ),
      );
      decoration = BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? theme.colorScheme.primaryContainer,
        border: showBorder
            ? Border.all(
                color: borderColor ?? theme.colorScheme.primary,
                width: 2,
              )
            : null,
      );
    } else if (_hasAssetImage) {
      avatarChild = ClipOval(
        child: Image.asset(
          imageUrl!.replaceFirst('asset://', ''),
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
        ),
      );
      decoration = BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? theme.colorScheme.primaryContainer,
      );
    } else {
      avatarChild = _InitialsAvatar(
        initials: initials,
        radius: radius,
        backgroundColor: backgroundColor,
      );
      decoration = BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.primaryContainer,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: borderColor ?? theme.colorScheme.primary,
                width: 2,
              )
            : null,
      );
    }

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: decoration,
      child: Center(child: avatarChild),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({
    required this.initials,
    required this.radius,
    this.backgroundColor,
  });

  final String initials;
  final double radius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

