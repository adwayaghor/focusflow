import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayPage extends StatefulWidget {
  const OverlayPage({super.key});

  @override
  State<OverlayPage> createState() => _OverlayPageState();
}

class _OverlayPageState extends State<OverlayPage> {
  double top = 0;
  double left = 0;
  bool isDragging = false;
  bool isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Ensure we only set initial position once
    if (!isInitialized) {
      final screenSize = MediaQuery.of(context).size;

      top = screenSize.height - 160;
      left = screenSize.width - 100;

      isInitialized = true;
    }
  }

  void checkExitZone(Size screenSize) async {
    double centerX = screenSize.width / 2;
    double bottomY = screenSize.height - 120;

    bool isNearCenter =
        (left + 35 > centerX - 80 && left + 35 < centerX + 80) &&
        (top > bottomY - 80);

    if (isNearCenter) {
      await FlutterOverlayWindow.closeOverlay();

      // Reset position for next session
      setState(() {
        top = screenSize.height - 160;
        left = screenSize.width - 100;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Material(
      color: Colors.transparent, // Important: no blocking layer
      child: Stack(
        children: [

          /// 🔴 EXIT ZONE (Visible only while dragging)
          if (isDragging)
            Positioned(
              bottom: 40,
              left: screenSize.width / 2 - 70,
              child: Container(
                width: 140,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  "DRAG HERE TO EXIT",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          /// 🟢 DRAGGABLE FLOATING LOGO WITH SHADOW
          Positioned(
            top: top,
            left: left,
            child: GestureDetector(
              onPanStart: (_) {
                setState(() {
                  isDragging = true;
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  left += details.delta.dx;
                  top += details.delta.dy;

                  // Keep inside screen bounds
                  left = left.clamp(0, screenSize.width - 70);
                  top = top.clamp(0, screenSize.height - 70);
                });
              },
              onPanEnd: (_) {
                setState(() {
                  isDragging = false;
                });

                checkExitZone(screenSize);
              },
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    "assets/images/logo.png",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}