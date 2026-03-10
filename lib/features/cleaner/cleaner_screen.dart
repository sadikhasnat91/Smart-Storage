import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/file_utils.dart';
import '../../models/storage_models.dart';
import '../../providers/providers.dart';

class CleanerScreen extends ConsumerStatefulWidget {
  const CleanerScreen({super.key});

  @override
  ConsumerState<CleanerScreen> createState() => _CleanerScreenState();
}

class _CleanerScreenState extends ConsumerState<CleanerScreen>
    with SingleTickerProviderStateMixin {
  bool _isCleaning = false;
  int _cleanedBytes = 0;

  @override
  Widget build(BuildContext context) {
    final junkFiles = ref.watch(junkFilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Cleaner'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: junkFiles.when(
        data: (files) {
          final selectedFiles = files.where((f) => f.isSelected).toList();
          final totalJunkSize =
              selectedFiles.fold<int>(0, (sum, f) => sum + f.size);

          return Column(
            children: [
              // Clean button / status area
              FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: _isCleaning || _cleanedBytes > 0
                        ? AppColors.successGradient
                        : AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: (_isCleaning
                                ? AppColors.success
                                : AppColors.primary)
                            .withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (_cleanedBytes > 0) ...[
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Cleaning Complete!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${FileUtils.formatBytes(_cleanedBytes)} freed',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                          ),
                        ),
                      ] else if (_isCleaning) ...[
                        const SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Cleaning...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ] else ...[
                        Icon(
                          Icons.cleaning_services_rounded,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          files.isEmpty
                              ? 'No junk found!'
                              : FileUtils.formatBytes(totalJunkSize),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (files.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${selectedFiles.length} items selected to clean',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: selectedFiles.isNotEmpty
                                ? () => _startCleaning(selectedFiles)
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                'Clean Now',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),

              if (files.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Junk Files',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            final allSelected =
                                files.every((f) => f.isSelected);
                            for (final f in files) {
                              f.isSelected = !allSelected;
                            }
                          });
                        },
                        child: Text(
                          files.every((f) => f.isSelected)
                              ? 'Deselect All'
                              : 'Select All',
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
                        delay: Duration(milliseconds: (index % 15) * 40),
                        child: _JunkFileItem(
                          file: file,
                          onToggle: () {
                            setState(() {
                              file.isSelected = !file.isSelected;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ] else
                Expanded(
                  child: Center(
                    child: FadeIn(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 64,
                            color: AppColors.success.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your device is clean!',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
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
              Text('Scanning for junk files...'),
            ],
          ),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _startCleaning(List<JunkFile> selectedFiles) async {
    setState(() => _isCleaning = true);

    final service = ref.read(storageServiceProvider);
    final paths = selectedFiles.map((f) => f.path).toList();
    final totalSize = selectedFiles.fold<int>(0, (s, f) => s + f.size);

    await service.deleteFiles(paths);

    // Brief delay for visual feedback
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isCleaning = false;
      _cleanedBytes = totalSize;
    });

    ref.invalidate(junkFilesProvider);
    ref.invalidate(storageInfoProvider);
  }
}

class _JunkFileItem extends StatelessWidget {
  final JunkFile file;
  final VoidCallback onToggle;

  const _JunkFileItem({required this.file, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Checkbox(
              value: file.isSelected,
              onChanged: (_) => onToggle(),
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.warning,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    file.reason,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              FileUtils.formatBytes(file.size),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
