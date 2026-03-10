import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.watch(themeProvider.notifier);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final permissionStatus = ref.watch(permissionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          // Appearance section
          FadeInUp(
            duration: const Duration(milliseconds: 400),
            child: _SectionHeader(title: 'Appearance'),
          ),
          const SizedBox(height: 8),
          FadeInUp(
            duration: const Duration(milliseconds: 400),
            delay: const Duration(milliseconds: 100),
            child: _SettingsTile(
              icon: Icons.dark_mode_rounded,
              iconColor: AppColors.primary,
              title: 'Dark Mode',
              subtitle: isDark ? 'On' : 'Off',
              trailing: Switch.adaptive(
                value: isDark,
                onChanged: (_) => themeNotifier.toggle(),
                activeTrackColor: AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Permissions section
          FadeInUp(
            duration: const Duration(milliseconds: 400),
            delay: const Duration(milliseconds: 200),
            child: _SectionHeader(title: 'Permissions'),
          ),
          const SizedBox(height: 8),
          FadeInUp(
            duration: const Duration(milliseconds: 400),
            delay: const Duration(milliseconds: 300),
            child: _SettingsTile(
              icon: Icons.folder_rounded,
              iconColor: AppColors.success,
              title: 'Storage Access',
              subtitle: permissionStatus.when(
                data: (granted) => granted ? 'Granted' : 'Not granted',
                loading: () => 'Checking...',
                error: (e1, s1) => 'Unknown',
              ),
              trailing: permissionStatus.when(
                data: (granted) => granted
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.success)
                    : TextButton(
                        onPressed: () async {
                          final service = ref.read(permissionServiceProvider);
                          await service.requestStoragePermission();
                          ref.invalidate(permissionProvider);
                        },
                        child: const Text('Grant'),
                      ),
                loading: () => const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (e2, s2) => const SizedBox(),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // About section
          FadeInUp(
            duration: const Duration(milliseconds: 400),
            delay: const Duration(milliseconds: 400),
            child: _SectionHeader(title: 'About'),
          ),
          const SizedBox(height: 8),
          FadeInUp(
            duration: const Duration(milliseconds: 400),
            delay: const Duration(milliseconds: 500),
            child: _SettingsTile(
              icon: Icons.info_outline_rounded,
              iconColor: AppColors.info,
              title: AppConstants.appName,
              subtitle: 'Version ${AppConstants.appVersion}',
            ),
          ),
          FadeInUp(
            duration: const Duration(milliseconds: 400),
            delay: const Duration(milliseconds: 600),
            child: _SettingsTile(
              icon: Icons.shield_outlined,
              iconColor: AppColors.accent,
              title: 'Privacy Policy',
              subtitle: 'Your data stays on your device',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'All analysis is performed locally. No data leaves your device.',
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),

          // Reset onboarding
          FadeInUp(
            duration: const Duration(milliseconds: 400),
            delay: const Duration(milliseconds: 700),
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  ref.read(settingsServiceProvider).isOnboardingComplete = false;
                  ref.read(onboardingCompleteProvider.notifier).update(false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Onboarding reset. Restart the app to see it again.'),
                    ),
                  );
                },
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('Reset Onboarding'),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
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
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
