import 'dart:async';
import 'dart:developer' as developer;
import 'package:usage_stats/usage_stats.dart';
import 'overlay_config.dart';

/// Service for monitoring foreground apps and detecting blocked apps
class AppMonitor {
  AppMonitor._();

  static Timer? _monitorTimer;
  static String? _lastForegroundApp;
  static Function(bool isBlocked)? _onBlockedAppDetected;

  /// Check if usage stats permission is granted
  static Future<bool> isUsagePermissionGranted() async {
    return await UsageStats.checkUsagePermission() ?? false;
  }

  /// Request usage stats permission
  static Future<void> requestUsagePermission() async {
    await UsageStats.grantUsagePermission();
  }

  /// Get the current foreground app package name
  static Future<String?> getForegroundApp() async {
    try {
      final endTime = DateTime.now();
      final startTime = endTime.subtract(const Duration(seconds: 5));
      
      final usageStats = await UsageStats.queryUsageStats(startTime, endTime);
      
      if (usageStats.isEmpty) return null;
      
      // Sort by last time used (most recent first)
      usageStats.sort((a, b) {
        final aTime = int.tryParse(a.lastTimeUsed ?? '0') ?? 0;
        final bTime = int.tryParse(b.lastTimeUsed ?? '0') ?? 0;
        return bTime.compareTo(aTime);
      });
      
      return usageStats.first.packageName;
    } catch (e) {
      developer.log('AppMonitor: Error getting foreground app: $e');
      return null;
    }
  }

  /// Start monitoring foreground apps
  /// Calls [onBlockedAppDetected] with true when a blocked app is detected
  /// Always returns false (not blocked) when user is in FocusFlow
  static void startMonitoring({
    required Function(bool isBlocked) onBlockedAppDetected,
    Duration interval = const Duration(milliseconds: 500),
  }) {
    _onBlockedAppDetected = onBlockedAppDetected;
    
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(interval, (_) async {
      final foregroundApp = await getForegroundApp();
      
      if (foregroundApp == null) return;
      if (foregroundApp == _lastForegroundApp) return;
      
      _lastForegroundApp = foregroundApp;
      developer.log('AppMonitor: Foreground app changed to: $foregroundApp');
      
      // Never block if user is in FocusFlow
      if (isFocusFlow(foregroundApp)) {
        _onBlockedAppDetected?.call(false);
        return;
      }
      
      // Check if this is a blocked app
      final isBlocked = OverlayConfig.isBlockedApp(foregroundApp);
      _onBlockedAppDetected?.call(isBlocked);
    });
  }

  /// Stop monitoring foreground apps
  static void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
    _lastForegroundApp = null;
    _onBlockedAppDetected = null;
  }

  /// Check if the app is FocusFlow itself
  static bool isFocusFlow(String packageName) {
    return packageName.toLowerCase().contains('focusflow');
  }
}
