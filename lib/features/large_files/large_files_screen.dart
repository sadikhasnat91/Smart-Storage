import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/file_utils.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

class LargeFilesScreen extends ConsumerStatefulWidget {
  const LargeFilesScreen({super.key});

  @override
  ConsumerState<LargeFilesScreen> createState() => _LargeFilesScreenState();
}

class _LargeFilesScreenState extends ConsumerState<LargeFilesScreen> {
  final Set<int> _selectedIndices = {};
  bool _selectionMode = false;

  void _openFile(BuildContext context, WidgetRef ref, String path) async {
    final service = ref.read(storageServiceProvider);
    final success = await service.openFile(path);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No app found to open this file')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final largeFiles = ref.watch(largeFilesProvider);
    final threshold = ref.watch(largeSizeThresholdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Large Files'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_selectionMode && _selectedIndices.isNotEmpty)
            IconButton(
              onPressed: () => _deleteSelected(ref),
              icon: const Icon(Icons.delete_rounded, color: AppColors.error),
            ),
        ],
      ),
      body: Column(
        children: [
          // Size threshold selector
          FadeInDown(
            duration: const Duration(milliseconds: 400),
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkBorder
                      : Colors.grey.shade200,
                  width: 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Minimum file size',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${threshold}MB',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.primary.withValues(alpha: 0.15),
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primary.withValues(alpha: 0.1),
                    ),
                    child: Slider(
                      value: threshold.toDouble(),
                      min: 10,
                      max: 500,
                      divisions: 49,
                      onChanged: (val) {
                        ref.read(largeSizeThresholdProvider.notifier).update(
                            val.round());
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // File list
          Expanded(
            child: largeFiles.when(
              data: (files) {
                if (files.isEmpty) {
                  return Center(
                    child: FadeIn(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 64,
                            color: AppColors.success.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No large files found!',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Files above ${threshold}MB will appear here',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final totalSize =
                    files.fold<int>(0, (sum, f) => sum + f.size);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${files.length} files found',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            'Total: ${FileUtils.formatBytes(totalSize)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        physics: const BouncingScrollPhysics(),
                        itemCount: files.length,
                        itemBuilder: (context, index) {
                          final file = files[index];
                          return FadeInUp(
                            duration: const Duration(milliseconds: 300),
                            delay:
                                Duration(milliseconds: (index % 20) * 30),
                            child: FileListItem(
                              name: file.name,
                              path: file.path,
                              size: file.size,
                              modified: file.modified,
                              extension: file.extension,
                              isSelected: _selectedIndices.contains(index),
                              showCheckbox: _selectionMode,
                              onTap: () {
                                if (_selectionMode) {
                                  setState(() {
                                    if (_selectedIndices.contains(index)) {
                                      _selectedIndices.remove(index);
                                      if (_selectedIndices.isEmpty) {
                                        _selectionMode = false;
                                      }
                                    } else {
                                      _selectedIndices.add(index);
                                    }
                                  });
                                } else {
                                  _openFile(context, ref, file.path);
                                }
                              },
                              onLongPress: () {
                                if (!_selectionMode) {
                                  setState(() {
                                    _selectionMode = true;
                                    _selectedIndices.add(index);
                                  });
                                }
                              },
                              onSelectChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedIndices.add(index);
                                  } else {
                                    _selectedIndices.remove(index);
                                    if (_selectedIndices.isEmpty) {
                                      _selectionMode = false;
                                    }
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Scanning for large files...'),
                  ],
                ),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelected(WidgetRef ref) async {
    final files = ref.read(largeFilesProvider).value;
    if (files == null) return;

    final paths = _selectedIndices.map((i) => files[i].path).toList();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Files'),
        content: Text(
          'Are you sure you want to delete ${paths.length} file(s)? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final service = ref.read(storageServiceProvider);
      final deleted = await service.deleteFiles(paths);
      _selectedIndices.clear();
      _selectionMode = false;
      ref.invalidate(largeFilesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted $deleted file(s)')),
        );
      }
    }
  }
}
