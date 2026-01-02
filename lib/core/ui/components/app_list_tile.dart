import 'package:flutter/material.dart';

class AppListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const AppListTile({super.key, this.leading, this.title, this.subtitle, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      // Avoid dense to preserve accessibility touch targets
      visualDensity: VisualDensity.standard,
      minVerticalPadding: 12,
    );
  }
}


