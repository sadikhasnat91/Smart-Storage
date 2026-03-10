import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'core/services/settings_service.dart';
import 'providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize settings
  final settingsService = SettingsService();
  await settingsService.init();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
  ));

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(
    ProviderScope(
      overrides: [
        settingsServiceProvider.overrideWithValue(settingsService),
      ],
      child: const SmartStorageApp(),
    ),
  );
}

class SmartStorageApp extends ConsumerWidget {
  const SmartStorageApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Smart Storage Analyzer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: routerProvider,
    );
  }
}


