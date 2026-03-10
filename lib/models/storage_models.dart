import 'package:flutter/material.dart';

class StorageInfo {
  final int totalSpace;
  final int usedSpace;
  final int freeSpace;

  const StorageInfo({
    required this.totalSpace,
    required this.usedSpace,
    required this.freeSpace,
  });

  double get usedPercentage =>
      totalSpace > 0 ? (usedSpace / totalSpace) * 100 : 0;

  double get freePercentage =>
      totalSpace > 0 ? (freeSpace / totalSpace) * 100 : 0;

  factory StorageInfo.empty() => const StorageInfo(
        totalSpace: 0,
        usedSpace: 0,
        freeSpace: 0,
      );
}

class StorageCategory {
  final String name;
  final IconData icon;
  final Color color;
  final int size;
  final int fileCount;

  const StorageCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.size,
    required this.fileCount,
  });
}

class FileItem {
  final String name;
  final String path;
  final int size;
  final DateTime modified;
  final String extension;
  final String category;
  bool isSelected;

  FileItem({
    required this.name,
    required this.path,
    required this.size,
    required this.modified,
    required this.extension,
    required this.category,
    this.isSelected = false,
  });
}

class DuplicateGroup {
  final String hash;
  final List<FileItem> files;
  final int totalWastedSpace;

  const DuplicateGroup({
    required this.hash,
    required this.files,
    required this.totalWastedSpace,
  });
}

class AppInfo {
  final String name;
  final String packageName;
  final int size;
  final DateTime? lastUsed;
  final bool isSystemApp;

  const AppInfo({
    required this.name,
    required this.packageName,
    required this.size,
    this.lastUsed,
    this.isSystemApp = false,
  });
}

class JunkFile {
  final String path;
  final String name;
  final int size;
  final String reason;
  bool isSelected;

  JunkFile({
    required this.path,
    required this.name,
    required this.size,
    required this.reason,
    this.isSelected = true,
  });
}

class CleaningSuggestion {
  final String title;
  final String description;
  final int potentialSavings;
  final IconData icon;
  final Color color;
  final String actionRoute;

  const CleaningSuggestion({
    required this.title,
    required this.description,
    required this.potentialSavings,
    required this.icon,
    required this.color,
    required this.actionRoute,
  });
}

class ScanResult {
  final StorageInfo storageInfo;
  final List<StorageCategory> categories;
  final List<CleaningSuggestion> suggestions;
  final DateTime scannedAt;

  const ScanResult({
    required this.storageInfo,
    required this.categories,
    required this.suggestions,
    required this.scannedAt,
  });
}
