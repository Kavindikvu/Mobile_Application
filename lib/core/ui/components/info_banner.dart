import 'package:flutter/material.dart';
import '../../theme/tokens.dart';

enum InfoBannerType { info, success, warning, error }

class InfoBanner extends StatelessWidget {
  final InfoBannerType type;
  final String title;
  final String? message;
  final Widget? action;

  const InfoBanner({super.key, required this.type, required this.title, this.message, this.action});

  Color _bg(ColorScheme cs) {
    switch (type) {
      case InfoBannerType.success:
        return const Color(AppColors.successContainer);
      case InfoBannerType.warning:
        return const Color(AppColors.warningContainer);
      case InfoBannerType.error:
        return const Color(AppColors.errorContainer);
      case InfoBannerType.info:
      default:
        return cs.surfaceVariant;
    }
  }

  Color _fg(ColorScheme cs) {
    switch (type) {
      case InfoBannerType.success:
        return const Color(AppColors.onSuccessContainer);
      case InfoBannerType.warning:
        return const Color(AppColors.onWarningContainer);
      case InfoBannerType.error:
        return const Color(AppColors.onErrorContainer);
      case InfoBannerType.info:
      default:
        return cs.onSurfaceVariant;
    }
  }

  IconData _icon() {
    switch (type) {
      case InfoBannerType.success:
        return Icons.check_circle;
      case InfoBannerType.warning:
        return Icons.warning_amber_rounded;
      case InfoBannerType.error:
        return Icons.error_outline;
      case InfoBannerType.info:
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _bg(cs),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon(), color: _fg(cs)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _fg(cs), fontWeight: FontWeight.w600)),
                if (message != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(message!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _fg(cs))),
                ],
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: AppSpacing.sm),
            action!,
          ],
        ],
      ),
    );
  }
}


