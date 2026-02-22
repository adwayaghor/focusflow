import 'package:shared_preferences/shared_preferences.dart';

/// Blocking mode options for focus sessions
enum BlockingMode {
  disablePhone,      // Option 1: Full screen blocking
  disableSelectApps, // Option 2: Block only specific apps
}

/// Manages overlay configuration using SharedPreferences
class OverlayConfig {
  OverlayConfig._();

  static const String _blockingModeKey = 'blocking_mode';

  /// Get the current blocking mode
  /// Returns disablePhone by default if not set
  static Future<BlockingMode> getBlockingMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_blockingModeKey) ?? 0;
    return BlockingMode.values[modeIndex];
  }

  /// Set the blocking mode
  static Future<void> setBlockingMode(BlockingMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_blockingModeKey, mode.index);
  }

  /// List of package name keywords that should be blocked in selective mode
  static const List<String> blockedAppKeywords = [
    'youtube',
    'instagram',
    'facebook',
    'meta',
    'tiktok',
    'twitter',
    'snapchat',
    'whatsapp',
    'telegram',
    'reddit',
    'pinterest',
    'netflix',
    'discord',
  ];

  /// Check if a package name matches any blocked app keyword
  static bool isBlockedApp(String packageName) {
    final lowerPackageName = packageName.toLowerCase();
    return blockedAppKeywords.any((keyword) => lowerPackageName.contains(keyword));
  }
}
