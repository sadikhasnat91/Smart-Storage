class AppConstants {
  static const String appName = 'Smart Storage Analyzer';
  static const String appVersion = '1.0.0';

  // Hive box names
  static const String settingsBox = 'settings';
  static const String cacheBox = 'cache';
  static const String onboardingBox = 'onboarding';

  // Settings keys
  static const String darkModeKey = 'dark_mode';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String lastScanKey = 'last_scan';
  static const String largeSizeThresholdKey = 'large_size_threshold';

  // Default values
  static const int defaultLargeSizeThresholdMB = 50;
  static const int scanBatchSize = 100;

  // File categories
  static const List<String> imageExtensions = [
    '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.heic', '.heif', '.svg',
  ];

  static const List<String> videoExtensions = [
    '.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm', '.3gp', '.m4v',
  ];

  static const List<String> audioExtensions = [
    '.mp3', '.wav', '.flac', '.aac', '.ogg', '.wma', '.m4a', '.opus',
  ];

  static const List<String> documentExtensions = [
    '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
    '.txt', '.csv', '.rtf', '.odt', '.ods', '.odp',
  ];

  static const List<String> apkExtensions = ['.apk', '.xapk', '.aab'];

  // Junk file patterns
  static const List<String> junkPatterns = [
    '.tmp', '.temp', '.log', '.cache', '.thumb', '.bak',
  ];

  static const List<String> junkDirectories = [
    'cache', '.cache', 'tmp', 'temp', '.tmp', '.trash',
    'thumbnails', '.thumbnails',
  ];
}
