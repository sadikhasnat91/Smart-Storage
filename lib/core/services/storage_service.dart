import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/storage_models.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/file_utils.dart';
import '../../core/theme/app_colors.dart';

class StorageService {
  static const _channel = MethodChannel('com.smartstorage/storage');

  /// Get device storage information via platform channel
  Future<StorageInfo> getStorageInfo() async {
    try {
      final result = await _channel.invokeMethod('getStorageInfo');
      return StorageInfo(
        totalSpace: result['totalSpace'] as int,
        usedSpace: result['usedSpace'] as int,
        freeSpace: result['freeSpace'] as int,
      );
    } on PlatformException {
      // Fallback: estimate from available paths
      return _getStorageInfoFallback();
    }
  }

  Future<StorageInfo> _getStorageInfoFallback() async {
    try {
      final dir = await getExternalStorageDirectory();
      if (dir == null) return StorageInfo.empty();

      // Use a reasonable estimate as fallback
      const totalEstimate = 64 * 1024 * 1024 * 1024; // 64GB default
      final freeBytes = await _getFreeDiskSpace(dir.path);
      final usedBytes = totalEstimate - freeBytes;

      return StorageInfo(
        totalSpace: totalEstimate,
        usedSpace: usedBytes > 0 ? usedBytes : 0,
        freeSpace: freeBytes,
      );
    } catch (_) {
      return StorageInfo.empty();
    }
  }

  Future<int> _getFreeDiskSpace(String path) async {
    try {
      final result = await _channel.invokeMethod('getFreeDiskSpace', {'path': path});
      return result as int;
    } catch (_) {
      return 0;
    }
  }

  /// Scan storage and categorize files
  Future<List<StorageCategory>> scanStorageCategories() async {
    try {
      final directories = await _getStorageDirectories();
      final categoryMap = <String, (int size, int count)>{
        'Images': (0, 0),
        'Videos': (0, 0),
        'Audio': (0, 0),
        'Documents': (0, 0),
        'Apps': (0, 0),
        'Other': (0, 0),
      };

      for (final dirPath in directories) {
        await _scanDirectoryForCategories(Directory(dirPath), categoryMap);
      }

      const iconMap = {
        'Images': Icons.image,
        'Videos': Icons.videocam,
        'Audio': Icons.audiotrack,
        'Documents': Icons.description,
        'Apps': Icons.apps,
        'Other': Icons.folder,
      };

      const colorMap = {
        'Images': AppColors.images,
        'Videos': AppColors.videos,
        'Audio': AppColors.audio,
        'Documents': AppColors.documents,
        'Apps': AppColors.apps,
        'Other': AppColors.other,
      };

      return categoryMap.entries.map((e) {
        return StorageCategory(
          name: e.key,
          icon: iconMap[e.key] ?? Icons.folder,
          color: colorMap[e.key] ?? AppColors.other,
          size: e.value.$1,
          fileCount: e.value.$2,
        );
      }).toList();
    } catch (e) {
      return _getDefaultCategories();
    }
  }

  Future<void> _scanDirectoryForCategories(
    Directory dir,
    Map<String, (int size, int count)> categoryMap,
  ) async {
    try {
      final stream = dir.list(recursive: true, followLinks: false)
          .handleError((_) {}); // skip inaccessible subdirectories
      await for (final entity in stream) {
        if (entity is File) {
          try {
            final stat = await entity.stat();
            final name = entity.path.split('/').last;
            final ext = name.contains('.')
                ? '.${name.split('.').last}'.toLowerCase()
                : '';
            final category = FileUtils.getCategoryFromExtension(ext);
            final current = categoryMap[category] ?? (0, 0);
            categoryMap[category] = (current.$1 + stat.size, current.$2 + 1);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  Future<List<String>> _getStorageDirectories() async {
    final dirs = <String>[];

    // Try the standard external storage root first
    const primaryPath = '/storage/emulated/0';
    try {
      if (await Directory(primaryPath).exists()) {
        dirs.add(primaryPath);
      }
    } catch (_) {}

    // Try path_provider approach as secondary
    if (dirs.isEmpty) {
      try {
        final ext = await getExternalStorageDirectory();
        if (ext != null) {
          String path = ext.path;
          final androidIndex = path.indexOf('/Android');
          if (androidIndex > 0) {
            path = path.substring(0, androidIndex);
          }
          if (!dirs.contains(path)) dirs.add(path);
        }
      } catch (_) {}
    }

    // Try /sdcard symlink
    if (dirs.isEmpty) {
      try {
        if (await Directory('/sdcard').exists()) {
          dirs.add('/sdcard');
        }
      } catch (_) {}
    }

    // Fallback: known media directories (accessible with media permissions)
    if (dirs.isEmpty) {
      const mediaDirs = [
        '/storage/emulated/0/DCIM',
        '/storage/emulated/0/Pictures',
        '/storage/emulated/0/Movies',
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Documents',
      ];
      for (final d in mediaDirs) {
        try {
          if (await Directory(d).exists()) dirs.add(d);
        } catch (_) {}
      }
    }

    // Absolute fallback — always try something
    if (dirs.isEmpty) {
      dirs.add(primaryPath);
    }

    return dirs;
  }

  /// Get large files above threshold
  Future<List<FileItem>> getLargeFiles({int thresholdMB = 50}) async {
    final directories = await _getStorageDirectories();
    final thresholdBytes = FileUtils.mbToBytes(thresholdMB);

    final files = <FileItem>[];
    for (final dirPath in directories) {
      await _scanForLargeFiles(Directory(dirPath), thresholdBytes, files);
    }

    files.sort((a, b) => b.size.compareTo(a.size));
    return files;
  }

  Future<void> _scanForLargeFiles(
    Directory dir,
    int threshold,
    List<FileItem> results,
  ) async {
    try {
      final stream = dir.list(recursive: true, followLinks: false)
          .handleError((_) {});
      await for (final entity in stream) {
        if (entity is File) {
          try {
            final stat = await entity.stat();
            if (stat.size >= threshold) {
              final name = entity.path.split('/').last;
              final ext = name.contains('.') ? '.${name.split('.').last}' : '';
              results.add(FileItem(
                name: name,
                path: entity.path,
                size: stat.size,
                modified: stat.modified,
                extension: ext,
                category: FileUtils.getCategoryFromExtension(ext),
              ));
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// Find duplicate files by comparing file sizes and partial hashes
  Future<List<DuplicateGroup>> findDuplicates() async {
    final directories = await _getStorageDirectories();
    final sizeMap = <int, List<FileItem>>{};

    for (final dirPath in directories) {
      await _groupFilesBySize(Directory(dirPath), sizeMap);
    }

    // Only keep groups with duplicates (same size)
    final duplicateGroups = <DuplicateGroup>[];
    for (final entry in sizeMap.entries) {
      if (entry.value.length > 1) {
        final wastedSpace = entry.key * (entry.value.length - 1);
        duplicateGroups.add(DuplicateGroup(
          hash: entry.key.toString(),
          files: entry.value,
          totalWastedSpace: wastedSpace,
        ));
      }
    }

    duplicateGroups.sort((a, b) => b.totalWastedSpace.compareTo(a.totalWastedSpace));
    return duplicateGroups;
  }

  Future<void> _groupFilesBySize(
    Directory dir,
    Map<int, List<FileItem>> sizeMap,
  ) async {
    try {
      final stream = dir.list(recursive: true, followLinks: false)
          .handleError((_) {});
      await for (final entity in stream) {
        if (entity is File) {
          try {
            final stat = await entity.stat();
            // Only consider files larger than 100KB for duplicate detection
            if (stat.size > 100 * 1024) {
              final name = entity.path.split('/').last;
              final ext = name.contains('.') ? '.${name.split('.').last}' : '';
              // Only look at image files for duplicate photo finder
              if (AppConstants.imageExtensions.contains(ext.toLowerCase())) {
                final item = FileItem(
                  name: name,
                  path: entity.path,
                  size: stat.size,
                  modified: stat.modified,
                  extension: ext,
                  category: 'Images',
                );
                sizeMap.putIfAbsent(stat.size, () => []).add(item);
              }
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// Find junk files (cache, temp, logs)
  Future<List<JunkFile>> findJunkFiles() async {
    final directories = await _getStorageDirectories();
    final junkFiles = <JunkFile>[];

    for (final dirPath in directories) {
      await _scanForJunkFiles(Directory(dirPath), junkFiles);
    }

    junkFiles.sort((a, b) => b.size.compareTo(a.size));
    return junkFiles;
  }

  Future<void> _scanForJunkFiles(Directory dir, List<JunkFile> results) async {
    try {
      final stream = dir.list(recursive: true, followLinks: false)
          .handleError((_) {});
      await for (final entity in stream) {
        if (entity is File) {
          try {
            final name = entity.path.split('/').last.toLowerCase();
            final stat = await entity.stat();

            // Check for junk file patterns
            for (final pattern in AppConstants.junkPatterns) {
              if (name.endsWith(pattern)) {
                results.add(JunkFile(
                  path: entity.path,
                  name: name,
                  size: stat.size,
                  reason: 'Temporary file ($pattern)',
                ));
                break;
              }
            }
          } catch (_) {}
        } else if (entity is Directory) {
          final dirName = entity.path.split('/').last.toLowerCase();
          if (AppConstants.junkDirectories.contains(dirName)) {
            final size = await _getDirectorySize(entity);
            if (size > 0) {
              results.add(JunkFile(
                path: entity.path,
                name: dirName,
                size: size,
                reason: 'Cache directory',
              ));
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<int> _getDirectorySize(Directory dir) async {
    int size = 0;
    try {
      final stream = dir.list(recursive: true, followLinks: false)
          .handleError((_) {});
      await for (final entity in stream) {
        if (entity is File) {
          try {
            size += (await entity.stat()).size;
          } catch (_) {}
        }
      }
    } catch (_) {}
    return size;
  }

  /// Get files by category
  Future<List<FileItem>> getFilesByCategory(String category) async {
    final directories = await _getStorageDirectories();
    final files = <FileItem>[];

    Set<String> extensions;
    switch (category) {
      case 'Images':
        extensions = AppConstants.imageExtensions.toSet();
        break;
      case 'Videos':
        extensions = AppConstants.videoExtensions.toSet();
        break;
      case 'Audio':
        extensions = AppConstants.audioExtensions.toSet();
        break;
      case 'Documents':
        extensions = AppConstants.documentExtensions.toSet();
        break;
      case 'Apps':
        extensions = AppConstants.apkExtensions.toSet();
        break;
      default:
        extensions = {};
    }

    for (final dirPath in directories) {
      await _scanForFilesByExtension(Directory(dirPath), extensions, files);
    }

    files.sort((a, b) => b.size.compareTo(a.size));
    return files;
  }

  Future<void> _scanForFilesByExtension(
    Directory dir,
    Set<String> extensions,
    List<FileItem> results,
  ) async {
    try {
      final stream = dir.list(recursive: true, followLinks: false)
          .handleError((_) {});
      await for (final entity in stream) {
        if (entity is File) {
          try {
            final name = entity.path.split('/').last;
            final ext = name.contains('.') ? '.${name.split('.').last}'.toLowerCase() : '';
            if (extensions.contains(ext)) {
              final stat = await entity.stat();
              results.add(FileItem(
                name: name,
                path: entity.path,
                size: stat.size,
                modified: stat.modified,
                extension: ext,
                category: FileUtils.getCategoryFromExtension(ext),
              ));
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// Delete files and directories using native platform channel
  Future<int> deleteFiles(List<String> paths) async {
    int deletedCount = 0;
    for (final path in paths) {
      try {
        // Use native deletion which handles both files and directories
        final deleted = await _channel.invokeMethod('deletePath', {'path': path});
        if (deleted == true) {
          deletedCount++;
        }
      } catch (_) {
        // Fallback to dart:io
        try {
          final type = await FileSystemEntity.type(path);
          if (type == FileSystemEntityType.directory) {
            await Directory(path).delete(recursive: true);
            deletedCount++;
          } else if (type == FileSystemEntityType.file) {
            await File(path).delete();
            deletedCount++;
          }
        } catch (_) {}
      }
    }
    return deletedCount;
  }

  /// Open a file using the system viewer
  Future<bool> openFile(String path) async {
    try {
      final result = await _channel.invokeMethod('openFile', {'path': path});
      return result == true;
    } catch (_) {
      return false;
    }
  }

  Future<List<AppInfo>> getInstalledApps() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getInstalledApps');
      return result.map((app) {
        final map = Map<String, dynamic>.from(app as Map);
        final lastUsedMs = (map['lastUsed'] as int?) ?? 0;
        return AppInfo(
          name: map['name'] as String? ?? 'Unknown',
          packageName: map['packageName'] as String? ?? '',
          size: (map['size'] as int?) ?? 0,
          lastUsed: lastUsedMs > 0
              ? DateTime.fromMillisecondsSinceEpoch(lastUsedMs)
              : null,
          isSystemApp: (map['isSystemApp'] as bool?) ?? false,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> uninstallApp(String packageName) async {
    try {
      final result = await _channel.invokeMethod('uninstallApp', {'packageName': packageName});
      return result == true;
    } catch (_) {
      return false;
    }
  }

  /// Generate smart suggestions based on scan results
  List<CleaningSuggestion> generateSuggestions(List<StorageCategory> categories) {
    final suggestions = <CleaningSuggestion>[];

    for (final cat in categories) {
      if (cat.name == 'Videos' && cat.size > 1024 * 1024 * 1024) {
        suggestions.add(CleaningSuggestion(
          title: 'Large Video Collection',
          description:
              'You have ${FileUtils.formatBytes(cat.size)} of videos. Review and remove old ones to free space.',
          potentialSavings: (cat.size * 0.3).round(),
          icon: Icons.video_library,
          color: AppColors.videos,
          actionRoute: '/category/Videos',
        ));
      }
      if (cat.name == 'Images' && cat.fileCount > 500) {
        suggestions.add(CleaningSuggestion(
          title: 'Many Photos Detected',
          description:
              '${cat.fileCount} images found. Check for duplicates to save ${FileUtils.formatBytes((cat.size * 0.2).round())}.',
          potentialSavings: (cat.size * 0.2).round(),
          icon: Icons.photo_library,
          color: AppColors.images,
          actionRoute: '/duplicates',
        ));
      }
    }

    suggestions.add(const CleaningSuggestion(
      title: 'Clean Junk Files',
      description: 'Remove cache, temp files, and logs to free up space instantly.',
      potentialSavings: 0,
      icon: Icons.cleaning_services,
      color: AppColors.accent,
      actionRoute: '/cleaner',
    ));

    return suggestions;
  }
}

List<StorageCategory> _getDefaultCategories() {
  return [
    const StorageCategory(name: 'Images', icon: Icons.image, color: AppColors.images, size: 0, fileCount: 0),
    const StorageCategory(name: 'Videos', icon: Icons.videocam, color: AppColors.videos, size: 0, fileCount: 0),
    const StorageCategory(name: 'Audio', icon: Icons.audiotrack, color: AppColors.audio, size: 0, fileCount: 0),
    const StorageCategory(name: 'Documents', icon: Icons.description, color: AppColors.documents, size: 0, fileCount: 0),
    const StorageCategory(name: 'Apps', icon: Icons.apps, color: AppColors.apps, size: 0, fileCount: 0),
    const StorageCategory(name: 'Other', icon: Icons.folder, color: AppColors.other, size: 0, fileCount: 0),
  ];
}
