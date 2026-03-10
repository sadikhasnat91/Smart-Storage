import 'package:flutter/material.dart';
import '../core/utils/file_utils.dart';

class FileListItem extends StatelessWidget {
  final String name;
  final String path;
  final int size;
  final DateTime modified;
  final String extension;
  final bool isSelected;
  final bool showCheckbox;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<bool?>? onSelectChanged;

  const FileListItem({
    super.key,
    required this.name,
    required this.path,
    required this.size,
    required this.modified,
    required this.extension,
    this.isSelected = false,
    this.showCheckbox = false,
    this.onTap,
    this.onLongPress,
    this.onSelectChanged,
  });

  IconData _getIconForExtension(String ext) {
    final e = ext.toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.heic'].contains(e)) {
      return Icons.image_rounded;
    }
    if (['.mp4', '.mkv', '.avi', '.mov', '.webm'].contains(e)) {
      return Icons.videocam_rounded;
    }
    if (['.mp3', '.wav', '.flac', '.aac', '.ogg'].contains(e)) {
      return Icons.audiotrack_rounded;
    }
    if (['.pdf'].contains(e)) return Icons.picture_as_pdf_rounded;
    if (['.doc', '.docx', '.txt', '.rtf'].contains(e)) return Icons.description_rounded;
    if (['.xls', '.xlsx', '.csv'].contains(e)) return Icons.table_chart_rounded;
    if (['.apk'].contains(e)) return Icons.android_rounded;
    if (['.zip', '.rar', '.7z', '.tar'].contains(e)) return Icons.folder_zip_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _getColorForExtension(String ext) {
    final e = ext.toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.heic'].contains(e)) {
      return const Color(0xFFFF6B6B);
    }
    if (['.mp4', '.mkv', '.avi', '.mov', '.webm'].contains(e)) {
      return const Color(0xFF4ECDC4);
    }
    if (['.mp3', '.wav', '.flac', '.aac', '.ogg'].contains(e)) {
      return const Color(0xFFFFBE0B);
    }
    if (['.pdf', '.doc', '.docx', '.txt'].contains(e)) return const Color(0xFF6C63FF);
    if (['.apk'].contains(e)) return const Color(0xFF00C9A7);
    return const Color(0xFF845EC2);
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorForExtension(extension);
    final icon = _getIconForExtension(extension);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            if (showCheckbox) ...[
              Checkbox(
                value: isSelected,
                onChanged: onSelectChanged,
                activeColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 4),
            ],
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    FileUtils.timeAgo(modified),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              FileUtils.formatBytes(size),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
