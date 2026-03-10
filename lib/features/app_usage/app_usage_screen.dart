import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/file_utils.dart';
import '../../models/storage_models.dart';
import '../../providers/providers.dart';

final installedAppsProvider = FutureProvider<List<AppInfo>>((ref) async {
  final service = ref.read(storageServiceProvider);
  return service.getInstalledApps();
});

class AppUsageScreen extends ConsumerStatefulWidget {
  const AppUsageScreen({super.key});

  @override
  ConsumerState<AppUsageScreen> createState() => _AppUsageScreenState();
}

class _AppUsageScreenState extends ConsumerState<AppUsageScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(installedAppsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final apps = ref.watch(installedAppsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Usage'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: apps.when(
        data: (appList) {
          if (appList.isEmpty) {
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
                      'All apps are actively used!',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          final totalSize =
              appList.fold<int>(0, (sum, a) => sum + a.size);

          return Column(
            children: [
              // Summary card
              FadeInDown(
                duration: const Duration(milliseconds: 400),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6392), Color(0xFFFF8FAB)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.apps_rounded, color: Colors.white, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${appList.length} installed apps',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total: ${FileUtils.formatBytes(totalSize)}',
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

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sorted by size • Tap uninstall to remove',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: appList.length,
                  itemBuilder: (context, index) {
                    final app = appList[index];
                    return FadeInUp(
                      duration: const Duration(milliseconds: 400),
                      delay: Duration(milliseconds: index * 80),
                      child: _AppInfoCard(
                        app: app,
                        onUninstall: () async {
                          final service = ref.read(storageServiceProvider);
                          await service.uninstallApp(app.packageName);
                          // Refresh list after returning from uninstall dialog
                          ref.invalidate(installedAppsProvider);
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
              Text('Analyzing apps...'),
            ],
          ),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _AppInfoCard extends StatelessWidget {
  final AppInfo app;
  final VoidCallback? onUninstall;

  const _AppInfoCard({required this.app, this.onUninstall});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.apps.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.android_rounded,
              color: AppColors.apps,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last used: ${app.lastUsed != null ? FileUtils.timeAgo(app.lastUsed!) : "Unknown"}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                FileUtils.formatBytes(app.size),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.apps,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onUninstall,
                  borderRadius: BorderRadius.circular(8),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Uninstall',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
