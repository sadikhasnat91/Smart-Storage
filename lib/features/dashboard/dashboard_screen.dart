import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/file_utils.dart';
import '../../models/storage_models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When user returns from Android Settings after granting permission
    if (state == AppLifecycleState.resumed) {
      _checkPermissionAndRefresh();
    }
  }

  Future<void> _checkPermissionAndRefresh() async {
    final permService = ref.read(permissionServiceProvider);
    final hasPermission = await permService.hasStoragePermission();
    if (hasPermission) {
      ref.invalidate(storageInfoProvider);
      ref.invalidate(storageCategoriesProvider);
    }
  }

  Future<void> _requestPermissions() async {
    final permService = ref.read(permissionServiceProvider);
    final hasPermission = await permService.hasStoragePermission();
    if (!hasPermission) {
      await permService.requestStoragePermission();
      // Re-check — handles regular dialog grants (not Settings redirect)
      final nowGranted = await permService.hasStoragePermission();
      if (nowGranted) {
        ref.invalidate(storageInfoProvider);
        ref.invalidate(storageCategoriesProvider);
      }
      // If still not granted, didChangeAppLifecycleState handles the Settings return
    }
  }

  @override
  Widget build(BuildContext context) {
    final storageInfo = ref.watch(storageInfoProvider);
    final categories = ref.watch(storageCategoriesProvider);
    final suggestions = ref.watch(suggestionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  colors: [Color(0xFF0D1117), Color(0xFF161B22)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          color: isDark ? null : AppColors.lightBg,
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(storageInfoProvider);
              ref.invalidate(storageCategoriesProvider);
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // App bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: FadeInDown(
                      duration: const Duration(milliseconds: 500),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Smart Storage',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Analyze & optimize your storage',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => context.push('/settings'),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkCard
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.settings_rounded,
                                color: isDark
                                    ? AppColors.textSecondary
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Storage overview card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 100),
                      child: _StorageOverviewCard(storageInfo: storageInfo),
                    ),
                  ),
                ),

                // Quick actions
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 200),
                      child: Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 300),
                      child: _QuickActionsGrid(),
                    ),
                  ),
                ),

                // Categories
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 400),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Storage Categories',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          TextButton(
                            onPressed: () => context.push('/categories'),
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                    child: categories.when(
                      data: (cats) => Column(
                        children: cats
                            .take(4)
                            .map((cat) => FadeInUp(
                                  duration: const Duration(milliseconds: 500),
                                  child: CategoryTile(
                                    name: cat.name,
                                    icon: cat.icon,
                                    color: cat.color,
                                    size: cat.size,
                                    fileCount: cat.fileCount,
                                    onTap: () =>
                                        context.push('/category/${cat.name}'),
                                  ),
                                ))
                            .toList(),
                      ),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Error scanning: $e'),
                      ),
                    ),
                  ),
                ),

                // Smart suggestions
                if (suggestions.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        child: Text(
                          'Smart Suggestions',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                      child: Column(
                        children: suggestions
                            .map((s) => FadeInUp(
                                  duration: const Duration(milliseconds: 500),
                                  child: _SuggestionCard(suggestion: s),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StorageOverviewCard extends StatelessWidget {
  final AsyncValue<StorageInfo> storageInfo;

  const _StorageOverviewCard({required this.storageInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4A42DB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: storageInfo.when(
        data: (info) {
          final (usedVal, usedUnit) =
              FileUtils.formatBytesComponents(info.usedSpace);
          final (totalVal, totalUnit) =
              FileUtils.formatBytesComponents(info.totalSpace);

          return Row(
            children: [
              AnimatedProgressRing(
                progress: info.usedPercentage / 100,
                size: 120,
                strokeWidth: 10,
                progressColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${info.usedPercentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Used',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StorageInfoRow(
                      label: 'Used',
                      value: '$usedVal $usedUnit',
                      dotColor: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    _StorageInfoRow(
                      label: 'Free',
                      value: FileUtils.formatBytes(info.freeSpace),
                      dotColor: Colors.white.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    _StorageInfoRow(
                      label: 'Total',
                      value: '$totalVal $totalUnit',
                      dotColor: Colors.white.withValues(alpha: 0.2),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const SizedBox(
          height: 120,
          child: Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        ),
        error: (e, _) => SizedBox(
          height: 120,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white70, size: 36),
                const SizedBox(height: 8),
                Text(
                  'Unable to read storage',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StorageInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color dotColor;

  const _StorageInfoRow({
    required this.label,
    required this.value,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.search_rounded,
        label: 'Large Files',
        color: AppColors.images,
        route: '/large-files',
      ),
      _QuickAction(
        icon: Icons.copy_rounded,
        label: 'Duplicates',
        color: AppColors.accent,
        route: '/duplicates',
      ),
      _QuickAction(
        icon: Icons.cleaning_services_rounded,
        label: 'Cleaner',
        color: AppColors.success,
        route: '/cleaner',
      ),
      _QuickAction(
        icon: Icons.apps_rounded,
        label: 'App Usage',
        color: AppColors.apps,
        route: '/app-usage',
      ),
    ];

    return Row(
      children: actions.map((action) {
        return Expanded(
          child: GestureDetector(
            onTap: () => context.push(action.route),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkCard
                    : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkBorder
                      : Colors.grey.shade200,
                  width: 0.5,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: action.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(action.icon, color: action.color, size: 22),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    action.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });
}

class _SuggestionCard extends StatelessWidget {
  final CleaningSuggestion suggestion;

  const _SuggestionCard({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => context.push(suggestion.actionRoute),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: suggestion.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(suggestion.icon, color: suggestion.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  suggestion.description,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
