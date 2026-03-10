import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/settings_service.dart';
import '../core/services/storage_service.dart';
import '../core/services/permission_service.dart';
import '../models/storage_models.dart';

// --- Service Providers ---

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

// --- Theme Provider ---

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final settings = ref.read(settingsServiceProvider);
    return settings.isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  void toggle() {
    final settings = ref.read(settingsServiceProvider);
    final isDark = state == ThemeMode.dark;
    settings.isDarkMode = !isDark;
    state = isDark ? ThemeMode.light : ThemeMode.dark;
  }

  bool get isDark => state == ThemeMode.dark;
}

// --- Storage Info Provider ---

final storageInfoProvider = FutureProvider<StorageInfo>((ref) async {
  final service = ref.read(storageServiceProvider);
  return service.getStorageInfo();
});

// --- Storage Categories Provider ---

final storageCategoriesProvider = FutureProvider<List<StorageCategory>>((ref) async {
  final service = ref.read(storageServiceProvider);
  return service.scanStorageCategories();
});

// --- Large Files Provider ---

final largeSizeThresholdProvider = NotifierProvider<LargeSizeThresholdNotifier, int>(
  LargeSizeThresholdNotifier.new,
);

class LargeSizeThresholdNotifier extends Notifier<int> {
  @override
  int build() => ref.read(settingsServiceProvider).largeSizeThresholdMB;

  void update(int value) => state = value;
}

final largeFilesProvider = FutureProvider<List<FileItem>>((ref) async {
  final service = ref.read(storageServiceProvider);
  final threshold = ref.watch(largeSizeThresholdProvider);
  return service.getLargeFiles(thresholdMB: threshold);
});

// --- Duplicate Files Provider ---

final duplicateFilesProvider = FutureProvider<List<DuplicateGroup>>((ref) async {
  final service = ref.read(storageServiceProvider);
  return service.findDuplicates();
});

// --- Junk Files Provider ---

final junkFilesProvider = FutureProvider<List<JunkFile>>((ref) async {
  final service = ref.read(storageServiceProvider);
  return service.findJunkFiles();
});

// --- Category Files Provider ---

final categoryFilesProvider =
    FutureProvider.family<List<FileItem>, String>((ref, category) async {
  final service = ref.read(storageServiceProvider);
  return service.getFilesByCategory(category);
});

// --- Suggestions Provider ---

final suggestionsProvider = Provider<List<CleaningSuggestion>>((ref) {
  final categories = ref.watch(storageCategoriesProvider);
  return categories.when(
    data: (cats) => ref.read(storageServiceProvider).generateSuggestions(cats),
    loading: () => [],
    error: (e, s) => [],
  );
});

// --- Permission Provider ---

final permissionProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(permissionServiceProvider);
  return service.hasStoragePermission();
});

// --- Scan State ---

final isScanningProvider = NotifierProvider<IsScanningNotifier, bool>(
  IsScanningNotifier.new,
);

class IsScanningNotifier extends Notifier<bool> {
  @override
  bool build() => false;
}

// --- Onboarding Provider ---

final onboardingCompleteProvider = NotifierProvider<OnboardingCompleteNotifier, bool>(
  OnboardingCompleteNotifier.new,
);

class OnboardingCompleteNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(settingsServiceProvider).isOnboardingComplete;

  void update(bool value) => state = value;
}
