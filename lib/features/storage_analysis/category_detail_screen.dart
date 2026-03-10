import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/utils/file_utils.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

class CategoryDetailScreen extends ConsumerWidget {
  final String category;

  const CategoryDetailScreen({super.key, required this.category});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(categoryFilesProvider(category));

    return Scaffold(
      appBar: AppBar(
        title: Text(category),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: files.when(
        data: (fileList) {
          if (fileList.isEmpty) {
            return Center(
              child: FadeIn(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No $category files found',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          final totalSize =
              fileList.fold<int>(0, (sum, f) => sum + f.size);

          return Column(
            children: [
              // Summary bar
              Container(
                margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${fileList.length} files',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      'Total: ${FileUtils.formatBytes(totalSize)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              // File list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  physics: const BouncingScrollPhysics(),
                  itemCount: fileList.length,
                  itemBuilder: (context, index) {
                    final file = fileList[index];
                    return FadeInUp(
                      duration: const Duration(milliseconds: 300),
                      delay: Duration(milliseconds: (index % 20) * 30),
                      child: FileListItem(
                        name: file.name,
                        path: file.path,
                        size: file.size,
                        modified: file.modified,
                        extension: file.extension,
                        onTap: () => _openFile(context, ref, file.path),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
