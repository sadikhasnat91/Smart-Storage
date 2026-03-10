import 'package:flutter/material.dart';
import '../core/utils/file_utils.dart';
import 'glass_card.dart';

class CategoryTile extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final int size;
  final int fileCount;
  final VoidCallback? onTap;

  const CategoryTile({
    super.key,
    required this.name,
    required this.icon,
    required this.color,
    required this.size,
    required this.fileCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '$fileCount files',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                FileUtils.formatBytes(size),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
