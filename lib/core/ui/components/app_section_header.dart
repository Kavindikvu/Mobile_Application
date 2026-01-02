import 'package:flutter/material.dart';
import '../../theme/tokens.dart';

class AppSectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const AppSectionHeader({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}


