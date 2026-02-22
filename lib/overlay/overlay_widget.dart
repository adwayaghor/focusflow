import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'overlay_config.dart';

/// Overlay widget that can display either:
/// 1. A small draggable floating logo button
/// 2. A full-screen blocking overlay with message
/// 
/// The mode is determined by the blocking mode setting
class OverlayWidget extends StatefulWidget {
  const OverlayWidget({super.key});

  @override
  State<OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget> {
  bool _isBlocking = false;
  BlockingMode _blockingMode = BlockingMode.disablePhone;
  StreamSubscription? _dataSubscription;

  @override
  void initState() {
    super.initState();
    _initializeOverlay();
    _listenForData();
  }

  Future<void> _initializeOverlay() async {
    final mode = await OverlayConfig.getBlockingMode();
    setState(() => _blockingMode = mode);
    
    if (mode == BlockingMode.disablePhone) {
      // In disablePhone mode, always show blocking overlay
      setState(() => _isBlocking = true);
    }
  }

  void _listenForData() {
    _dataSubscription = FlutterOverlayWindow.overlayListener.listen((data) {
      if (data == 'block') {
        setState(() => _isBlocking = true);
      } else if (data == 'unblock') {
        setState(() => _isBlocking = false);
      } else if (data == 'close') {
        FlutterOverlayWindow.closeOverlay();
      }
    });
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use Directionality to provide text direction without MaterialApp
    return Directionality(
      textDirection: TextDirection.ltr,
      child: _isBlocking ? _buildBlockingOverlay() : _buildFloatingButton(),
    );
  }

  /// Full-screen blocking overlay with 70% transparency
  Widget _buildBlockingOverlay() {
    return Container(
      color: const Color(0xB3000000), // 70% black
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                "assets/images/logo.png",
                fit: BoxFit.cover,
                width: 100,
                height: 100,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Focus Session Active',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              _blockingMode == BlockingMode.disablePhone
                  ? 'Stay focused! Your phone is locked during this session.'
                  : 'This app is blocked during your focus session.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xB3FFFFFF), // Colors.white70
                fontSize: 16,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(height: 48),
          GestureDetector(
            onTap: () {
              // Button exists but doesn't do anything yet
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_rounded, color: Color(0xDD000000), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Return to FocusFlow',
                    style: TextStyle(
                      color: Color(0xDD000000), // Colors.black87
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Small draggable floating button with logo
  Widget _buildFloatingButton() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 3,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          "assets/images/logo.png",
          fit: BoxFit.cover,
          width: 100,
          height: 100,
        ),
      ),
    );
  }
}
