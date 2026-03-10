import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class StorageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final Widget? trailing;

  const StorageCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconColor,
    this.gradient,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: gradient ??
              LinearGradient(
                colors: isDark
                    ? [AppColors.darkCard, AppColors.darkCard]
                    : [Colors.white, Colors.white],
              ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
            width: 0.5,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!
            else
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
          ],
        ),
      ),
    );
  }
}
