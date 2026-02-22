import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme.dart';
import '../controllers/session_controller.dart';
import '../overlay/overlay_config.dart';

class SessionPage extends StatefulWidget {
  const SessionPage({super.key});

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  BlockingMode _blockingMode = BlockingMode.disablePhone;

  @override
  void initState() {
    super.initState();
    _loadBlockingMode();
  }

  Future<void> _loadBlockingMode() async {
    try {
      final mode = await OverlayConfig.getBlockingMode();
      if (mounted) {
        setState(() {
          _blockingMode = mode;
        });
      }
    } catch (e) {
      // If loading fails, keep the default
    }
  }

  Future<void> _setBlockingMode(BlockingMode mode) async {
    await OverlayConfig.setBlockingMode(mode);
    setState(() => _blockingMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SessionController>();

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Focus Session',
            style: TextStyle(
              color: AppTheme.text,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // Status Badge
              Obx(() => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: controller.isSessionActive.value
                      ? AppTheme.successBg
                      : AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(
                    color: controller.isSessionActive.value
                        ? AppTheme.success.withOpacity(0.4)
                        : AppTheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: controller.isSessionActive.value
                            ? AppTheme.success
                            : AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      controller.isSessionActive.value
                          ? 'Session Active'
                          : 'No Active Session',
                      style: TextStyle(
                        color: controller.isSessionActive.value
                            ? AppTheme.successDark
                            : AppTheme.textLight,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )),

              const SizedBox(height: 40),

              // Timer Section (with loading)
              Obx(() => controller.isLoading.value
                  ? const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _TimerRing(
                      elapsed: controller.elapsed.value,
                      isActive: controller.isSessionActive.value,
                      label: controller.formatDuration(
                        controller.elapsed.value,
                      ),
                    ),
              ),

              const SizedBox(height: 32),

              // Blocking Mode Selector (only show when no active session)
              Obx(() => !controller.isSessionActive.value
                  ? Column(
                      children: [
                        _BlockingModeSelector(
                          currentMode: _blockingMode,
                          onModeChanged: _setBlockingMode,
                        ),
                        const SizedBox(height: 32),
                      ],
                    )
                  : const SizedBox.shrink(),
              ),

              // Main Action Button
              Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.isSessionActive.value
                      ? controller.endCurrentSession
                      : controller.startNewSession,
                  icon: Icon(
                    controller.isSessionActive.value
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  label: Text(
                    controller.isSessionActive.value
                        ? 'End Session'
                        : 'Start Session',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: controller.isSessionActive.value
                        ? AppTheme.error
                        : AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                    ),
                  ),
                ),
              )),

              const SizedBox(height: 32),

              // Tips Card
              Obx(() => _TipsCard(isActive: controller.isSessionActive.value)),
            ],
          ),
        ),
      ),
    );
  }
}

// Blocking Mode Selector Widget
class _BlockingModeSelector extends StatelessWidget {
  final BlockingMode currentMode;
  final Function(BlockingMode) onModeChanged;

  const _BlockingModeSelector({
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_rounded, color: AppTheme.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Blocking Mode',
                style: TextStyle(
                  color: AppTheme.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ModeOption(
            title: 'Disable Phone',
            description: 'Block all apps while session is active',
            icon: Icons.phone_disabled_rounded,
            isSelected: currentMode == BlockingMode.disablePhone,
            onTap: () => onModeChanged(BlockingMode.disablePhone),
          ),
          const SizedBox(height: 12),
          _ModeOption(
            title: 'Disable Select Apps',
            description: 'Only block distracting apps (social media, etc.)',
            icon: Icons.app_blocking_rounded,
            isSelected: currentMode == BlockingMode.disableSelectApps,
            onTap: () => onModeChanged(BlockingMode.disableSelectApps),
          ),
        ],
      ),
    );
  }
}

// Mode Option Widget
class _ModeOption extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : AppTheme.backgroundCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppTheme.textMuted,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? AppTheme.primary : AppTheme.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// Timer Ring Widget
class _TimerRing extends StatelessWidget {
  final Duration elapsed;
  final bool isActive;
  final String label;

  const _TimerRing({
    required this.elapsed,
    required this.isActive,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.backgroundCard,
        boxShadow: [
          BoxShadow(
            color: isActive
                ? AppTheme.primary.withOpacity(0.2)
                : Colors.black.withOpacity(0.06),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
        border: Border.all(
          color: isActive ? AppTheme.primary : AppTheme.border,
          width: isActive ? 3 : 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? Icons.timer_rounded : Icons.timer_outlined,
            color: isActive ? AppTheme.primary : AppTheme.textMuted,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: isActive ? AppTheme.text : AppTheme.textMuted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isActive ? 'elapsed' : 'ready',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Tips Card
class _TipsCard extends StatelessWidget {
  final bool isActive;

  const _TipsCard({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final tips = isActive
        ? [
            '📵 Put your phone face-down when not using FocusFlow.',
            '🔕 Silence non-essential notifications.',
            '💧 Stay hydrated — your brain needs it.',
          ]
        : [
            '🎯 Set a clear goal before starting your session.',
            '⏱ Even 25 focused minutes can make a big difference.',
            '🚫 Close distracting apps before you begin.',
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isActive ? '💡 While you focus...' : '💡 Before you start...',
            style: const TextStyle(
              color: AppTheme.text,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                tip,
                style: const TextStyle(
                  color: AppTheme.textLight,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
