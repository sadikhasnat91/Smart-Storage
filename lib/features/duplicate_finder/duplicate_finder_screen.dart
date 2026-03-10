import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/file_utils.dart';
import '../../models/storage_models.dart';
import '../../providers/providers.dart';

class DuplicateFinderScreen extends ConsumerStatefulWidget {
  const DuplicateFinderScreen({super.key});

  @override
  ConsumerState<DuplicateFinderScreen> createState() =>
      _DuplicateFinderScreenState();
}

class _DuplicateFinderScreenState extends ConsumerState<DuplicateFinderScreen> {
  final Map<int, Set<int>> _selectedFiles = {}; // groupIndex -> set of fileIndices

  @override
  Widget build(BuildContext context) {
    final duplicates = ref.watch(duplicateFilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Duplicate Photos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_selectedFiles.isNotEmpty)
            TextButton.icon(
              onPressed: _deleteSelected,
              icon: const Icon(Icons.delete_rounded, color: AppColors.error, size: 20),
              label: Text(
                '$_totalSelectedCount',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
        ],
      ),
      body: duplicates.when(
        data: (groups) {
          if (groups.isEmpty) {
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
                      'No duplicates found!',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your photos are all unique',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          }

          final totalWasted =
              groups.fold<int>(0, (sum, g) => sum + g.totalWastedSpace);

          return Column(
            children: [
              // Summary
              FadeInDown(
                duration: const Duration(milliseconds: 400),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.warningGradient,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.copy_rounded, color: Colors.white, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${groups.length} duplicate groups',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${FileUtils.formatBytes(totalWasted)} can be freed',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Groups list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: groups.length,
                  itemBuilder: (context, groupIndex) {
                    final group = groups[groupIndex];
                    return FadeInUp(
                      duration: const Duration(milliseconds: 400),
                      delay: Duration(milliseconds: (groupIndex % 10) * 60),
                      child: _DuplicateGroupCard(
                        group: group,
                        groupIndex: groupIndex,
                        selectedIndices: _selectedFiles[groupIndex] ?? {},
                        onFileSelected: (fileIndex, selected) {
                          setState(() {
                            final set = _selectedFiles.putIfAbsent(
                              groupIndex,
                              () => {},
                            );
                            if (selected) {
                              set.add(fileIndex);
                            } else {
                              set.remove(fileIndex);
                              if (set.isEmpty) {
                                _selectedFiles.remove(groupIndex);
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
              Text('Scanning for duplicates...'),
            ],
          ),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  int get _totalSelectedCount =>
      _selectedFiles.values.fold(0, (sum, set) => sum + set.length);

  Future<void> _deleteSelected() async {
    final groups = ref.read(duplicateFilesProvider).value;
    if (groups == null) return;

    final paths = <String>[];
    for (final entry in _selectedFiles.entries) {
      final group = groups[entry.key];
      for (final fileIdx in entry.value) {
        paths.add(group.files[fileIdx].path);
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Duplicates'),
        content: Text('Delete ${paths.length} duplicate file(s)?'),
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
      setState(() => _selectedFiles.clear());
      ref.invalidate(duplicateFilesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted $deleted duplicate(s)')),
        );
      }
    }
  }
}

class _DuplicateGroupCard extends StatelessWidget {
  final DuplicateGroup group;
  final int groupIndex;
  final Set<int> selectedIndices;
  final Function(int fileIndex, bool selected) onFileSelected;

  const _DuplicateGroupCard({
    required this.group,
    required this.groupIndex,
    required this.selectedIndices,
    required this.onFileSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${group.files.length} duplicates',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  'Wasted: ${FileUtils.formatBytes(group.totalWastedSpace)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          // Image previews in horizontal scroll
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: group.files.length,
              itemBuilder: (context, index) {
                final file = group.files[index];
                final isSelected = selectedIndices.contains(index);

                return GestureDetector(
                  onTap: () => onFileSelected(index, !isSelected),
                  child: Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.error.withValues(alpha: 0.1)
                          : (isDark
                              ? AppColors.darkBg
                              : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(14),
                      border: isSelected
                          ? Border.all(color: AppColors.error, width: 2)
                          : null,
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.image_rounded,
                            color: AppColors.images.withValues(alpha: 0.5),
                            size: 32,
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 4,
                          left: 4,
                          right: 4,
                          child: Text(
                            FileUtils.formatBytes(file.size),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 9),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
