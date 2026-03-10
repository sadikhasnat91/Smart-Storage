import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request storage permissions for Android
  Future<bool> requestStoragePermission() async {
    // Already have full access
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    // Try manage external storage first (Android 11+) — opens Settings page
    var status = await Permission.manageExternalStorage.request();
    if (status.isGranted) return true;

    // On Android 13+, request granular media permissions
    final mediaResults = await [
      Permission.photos,
      Permission.videos,
      Permission.audio,
    ].request();
    final anyMediaGranted = mediaResults.values.any((s) => s.isGranted);
    if (anyMediaGranted) return true;

    // Fallback to regular storage permission (Android ≤12)
    status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Check if storage permission is granted
  Future<bool> hasStoragePermission() async {
    if (await Permission.manageExternalStorage.isGranted) return true;
    if (await Permission.storage.isGranted) return true;
    // Android 13+ media permissions
    if (await Permission.photos.isGranted ||
        await Permission.videos.isGranted ||
        await Permission.audio.isGranted) {
      return true;
    }
    return false;
  }

  /// Open app settings
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
