import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class SettingsService {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get isDarkMode => _prefs.getBool(AppConstants.darkModeKey) ?? true;
  set isDarkMode(bool value) => _prefs.setBool(AppConstants.darkModeKey, value);

  bool get isOnboardingComplete =>
      _prefs.getBool(AppConstants.onboardingCompleteKey) ?? false;
  set isOnboardingComplete(bool value) =>
      _prefs.setBool(AppConstants.onboardingCompleteKey, value);

  int get largeSizeThresholdMB =>
      _prefs.getInt(AppConstants.largeSizeThresholdKey) ??
      AppConstants.defaultLargeSizeThresholdMB;
  set largeSizeThresholdMB(int value) =>
      _prefs.setInt(AppConstants.largeSizeThresholdKey, value);

  String? get lastScanDate => _prefs.getString(AppConstants.lastScanKey);
  set lastScanDate(String? value) {
    if (value != null) _prefs.setString(AppConstants.lastScanKey, value);
  }
}
