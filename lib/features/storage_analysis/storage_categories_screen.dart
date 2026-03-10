import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

class StorageCategoriesScreen extends ConsumerWidget {
  const StorageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(storageCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Categories'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: categories.when(
        data: (cats) => ListView.builder(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          itemCount: cats.length,
          itemBuilder: (context, index) {
            final cat = cats[index];
            return FadeInUp(
              duration: const Duration(milliseconds: 400),
              delay: Duration(milliseconds: index * 80),
              child: CategoryTile(
                name: cat.name,
                icon: cat.icon,
                color: cat.color,
                size: cat.size,
                fileCount: cat.fileCount,
                onTap: () => context.push('/category/${cat.name}'),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
