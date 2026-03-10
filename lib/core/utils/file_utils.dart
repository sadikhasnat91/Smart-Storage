import 'dart:math';

class FileUtils {
  /// Format bytes to human-readable string
  static String formatBytes(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1024)).floor();
    final size = bytes / pow(1024, i);
    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  /// Format bytes to value and unit separately
  static (double value, String unit) formatBytesComponents(int bytes) {
    if (bytes <= 0) return (0, 'B');
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1024)).floor();
    final size = bytes / pow(1024, i);
    return (double.parse(size.toStringAsFixed(1)), suffixes[i]);
  }

  /// Convert MB to bytes
  static int mbToBytes(int mb) => mb * 1024 * 1024;

  /// Get file category from extension
  static String getCategoryFromExtension(String extension) {
    final ext = extension.toLowerCase();
    const imageExts = {'.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.heic', '.heif', '.svg'};
    const videoExts = {'.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm', '.3gp', '.m4v'};
    const audioExts = {'.mp3', '.wav', '.flac', '.aac', '.ogg', '.wma', '.m4a', '.opus'};
    const docExts = {'.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt', '.csv', '.rtf'};
    const apkExts = {'.apk', '.xapk', '.aab'};

    if (imageExts.contains(ext)) return 'Images';
    if (videoExts.contains(ext)) return 'Videos';
    if (audioExts.contains(ext)) return 'Audio';
    if (docExts.contains(ext)) return 'Documents';
    if (apkExts.contains(ext)) return 'Apps';
    return 'Other';
  }

  /// Get a friendly time ago string
  static String timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
