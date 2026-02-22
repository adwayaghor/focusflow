import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'theme.dart';
import 'overlay/overlay_widget.dart';
import 'overlay/overlay_service.dart';
import 'controllers/auth_controller.dart';
import 'controllers/session_controller.dart';
import 'controllers/navigation_controller.dart';
import 'pages/home_page.dart';
import 'pages/session_page.dart';
import 'pages/report_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  Get.put(AuthController());
  Get.put(SessionController());
  Get.put(MainNavigationController());
  
  runApp(const MyApp());
}

/// Overlay entry point - called when the overlay window is shown
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OverlayWidget());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const PermissionWrapper(),
      getPages: [
        GetPage(name: '/home', page: () => const HomePage()),
        GetPage(name: '/session', page: () => const SessionPage()),
        GetPage(name: '/report', page: () => const ReportPage()),
      ],
    );
  }
}

/// Wrapper that checks for overlay permission on app start
class PermissionWrapper extends StatefulWidget {
  const PermissionWrapper({super.key});

  @override
  State<PermissionWrapper> createState() => _PermissionWrapperState();
}

class _PermissionWrapperState extends State<PermissionWrapper> {
  bool _isChecking = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await OverlayService.isPermissionGranted();
    setState(() {
      _hasPermission = granted;
      _isChecking = false;
    });
    
    // If permission granted, show overlay if session is active
    if (granted) {
      _showOverlayIfSessionActive();
    }
  }
  
  Future<void> _showOverlayIfSessionActive() async {
    final sessionController = Get.find<SessionController>();
    // Wait for session controller to finish loading
    while (sessionController.isLoading.value) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    // Show overlay if session is active
    if (sessionController.isSessionActive.value) {
      await OverlayService.showOverlay();
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _isChecking = true);
    final granted = await OverlayService.requestPermission();
    setState(() {
      _hasPermission = granted;
      _isChecking = false;
    });
    
    // If permission granted, show overlay if session is active
    if (granted) {
      _showOverlayIfSessionActive();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Overlay Permission Required',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.text,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'FocusFlow needs overlay permission to display the focus indicator while you work. This helps you stay aware of your active session.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _requestPermission,
                    icon: const Icon(Icons.security_rounded),
                    label: const Text(
                      'Grant Permission',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radius),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _checkPermission,
                  child: const Text(
                    'I\'ve already granted permission',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Permission granted - show main navigation
    return const MainNavigation();
  }
}

class MainNavigation extends StatelessWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final navController = Get.find<MainNavigationController>();

    return Obx(() => Scaffold(
      body: IndexedStack(
        index: navController.currentIndex.value,
        children: const [
          HomePage(),
          SessionPage(),
          ReportPage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundCard,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: navController.currentIndex.value == 0,
                  onTap: () => navController.changeTab(0),
                ),
                _NavItem(
                  icon: Icons.timer_rounded,
                  label: 'Session',
                  selected: navController.currentIndex.value == 1,
                  onTap: () => navController.changeTab(1),
                ),
                _NavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Report',
                  selected: navController.currentIndex.value == 2,
                  onTap: () => navController.changeTab(2),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? AppTheme.primary : AppTheme.textMuted,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppTheme.primary : AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
