import 'package:flutter/material.dart';
import '../../theme/tokens.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const AppCard({super.key, required this.child, this.padding, this.margin, this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      child: child,
    );
    return Card(
      margin: margin,
      child: onTap == null
          ? content
          : InkWell(
              borderRadius: BorderRadius.circular(AppRadii.md),
              onTap: onTap,
              child: content,
            ),
    );
  }
}


