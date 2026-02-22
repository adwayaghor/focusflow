import 'dart:developer' as developer;
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'overlay_config.dart';

// Re-export BlockingMode for convenience
export 'overlay_config.dart' show BlockingMode;

/// Service class for managing overlay window functionality
class OverlayService {
  OverlayService._();

  // ------------------------------------------------
  // PERMISSION MANAGEMENT
  // ------------------------------------------------

  /// Check if overlay permission is granted
  /// Returns true if permission is already granted
  static Future<bool> isPermissionGranted() async {
    return await FlutterOverlayWindow.isPermissionGranted();
  }

  /// Request overlay permission from the user
  /// Opens system settings and returns true once permission is granted
  static Future<bool> requestPermission() async {
    final result = await FlutterOverlayWindow.requestPermission();
    return result ?? false;
  }

  /// Check permission and request if not granted
  /// Returns true if permission is granted (either already or after request)
  static Future<bool> ensurePermission() async {
    final granted = await isPermissionGranted();
    if (granted) return true;
    return await requestPermission();
  }

  // ------------------------------------------------
  // OVERLAY CONTROL
  // ------------------------------------------------

  /// Show overlay based on current blocking mode
  /// Always starts as floating overlay, widget handles blocking display
  static Future<void> showOverlay() async {
    try {
      final hasPermission = await isPermissionGranted();
      developer.log('OverlayService: hasPermission = $hasPermission');
      if (!hasPermission) return;

      // Check if overlay is already active
      final isActive = await FlutterOverlayWindow.isActive();
      developer.log('OverlayService: isActive = $isActive');
      if (isActive) return;

      final mode = await OverlayConfig.getBlockingMode();
      developer.log('OverlayService: Blocking mode = $mode');

      if (mode == BlockingMode.disablePhone) {
        // Full screen blocking overlay
        await _showBlockingOverlay();
      } else {
        // Small floating button overlay for selective blocking
        await _showFloatingOverlay();
      }
    } catch (e) {
      developer.log('OverlayService: Error showing overlay: $e');
    }
  }

  /// Show the small floating button overlay (logo)
  static Future<void> _showFloatingOverlay() async {
    developer.log('OverlayService: Showing floating overlay...');
    await FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      overlayTitle: "FocusFlow",
      overlayContent: "Focus session active",
      flag: OverlayFlag.defaultFlag,
      visibility: NotificationVisibility.visibilityPublic,
      positionGravity: PositionGravity.right,
      height: 110,
      width: 110,
      startPosition: const OverlayPosition(-20, -200),
    );
    developer.log('OverlayService: Floating overlay shown successfully');
  }

  /// Show full-screen blocking overlay (70% transparent)
  static Future<void> _showBlockingOverlay() async {
    developer.log('OverlayService: Showing blocking overlay...');
    await FlutterOverlayWindow.showOverlay(
      enableDrag: false,
      overlayTitle: "FocusFlow",
      overlayContent: "Focus session active",
      flag: OverlayFlag.clickThrough,
      visibility: NotificationVisibility.visibilityPublic,
      positionGravity: PositionGravity.none,
      height: WindowSize.matchParent,
      width: WindowSize.matchParent,
    );
    developer.log('OverlayService: Blocking overlay shown successfully');
  }

  /// Close the overlay window
  /// Call this when ending a session
  static Future<void> closeOverlay() async {
    try {
      // Send close signal to overlay first
      await shareData('close');
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (_) {}
    
    final isActive = await FlutterOverlayWindow.isActive();
    if (isActive) {
      await FlutterOverlayWindow.closeOverlay();
    }
  }

  /// Check if overlay is currently active
  static Future<bool> isOverlayActive() async {
    return await FlutterOverlayWindow.isActive();
  }

  /// Share data between main app and overlay
  /// Used to communicate blocking mode changes
  static Future<void> shareData(String data) async {
    await FlutterOverlayWindow.shareData(data);
  }

  /// Send block command to overlay
  static Future<void> sendBlockCommand() async {
    await shareData('block');
  }

  /// Send unblock command to overlay
  static Future<void> sendUnblockCommand() async {
    await shareData('unblock');
  }

  /// Resize the overlay
  static Future<void> resizeOverlay(int width, int height, bool enableDrag) async {
    await FlutterOverlayWindow.resizeOverlay(width, height, enableDrag);
  }

  /// Move the overlay to a new position
  static Future<bool?> moveOverlay(double x, double y) async {
    return await FlutterOverlayWindow.moveOverlay(OverlayPosition(x, y));
  }
}
