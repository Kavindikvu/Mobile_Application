import 'package:flutter/material.dart';
import '../../theme/motion.dart';

class AppButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool isPrimary;

  const AppButton({super.key, required this.onPressed, required this.child, this.style, this.isPrimary = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = isPrimary
        ? theme.filledButtonTheme.style
        : theme.outlinedButtonTheme.style;
    return AnimatedSize(
      duration: AppMotion.durationShort,
      curve: AppMotion.curveStandard,
      child: isPrimary
          ? FilledButton(onPressed: onPressed, style: baseStyle?.merge(style), child: child)
          : OutlinedButton(onPressed: onPressed, style: baseStyle?.merge(style), child: child),
    );
  }
}


