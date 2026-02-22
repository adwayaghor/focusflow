import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../theme.dart';
import '../controllers/auth_controller.dart';
import 'login_page.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final user = authController.user;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          elevation: 0,
          centerTitle: true,
          title: const Text('Reports', style: TextStyle(color: AppTheme.text, fontWeight: FontWeight.w700)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                  ),
                  child: const Icon(Icons.lock_outline_rounded, color: AppTheme.primary, size: 36),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Login Required',
                  style: TextStyle(color: AppTheme.text, fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Login to access your focus session reports and analytics.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textLight, fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Login to Continue'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: true,
        title: const Text('Reports', style: TextStyle(color: AppTheme.text, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.textLight, size: 20),
            onPressed: () => authController.logout(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('sessions')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: AppTheme.error)),
            );
          }

          final sessions = snapshot.data?.docs ?? [];

          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                    ),
                    child: const Icon(Icons.hourglass_empty_rounded, color: AppTheme.primary, size: 36),
                  ),
                  const SizedBox(height: 20),
                  const Text('No sessions yet', style: TextStyle(color: AppTheme.text, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Start a focus session to see your analytics here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textLight, fontSize: 14)),
                ],
              ),
            );
          }

          // Aggregate stats
          int totalFocusMs = 0;
          int totalDistractions = 0;
          int totalDistractionMs = 0;
          double totalScore = 0;
          int angelTotal = 0;
          int devilTotal = 0;
          Map<String, int> allSites = {};

          for (final doc in sessions) {
            final data = doc.data() as Map<String, dynamic>;
            totalFocusMs += (data['duration'] as num?)?.toInt() ?? 0;
            totalDistractions += (data['distractions'] as num?)?.toInt() ?? 0;
            totalDistractionMs += (data['distractionTime'] as num?)?.toInt() ?? 0;
            totalScore += (data['focusScore'] as num?)?.toDouble() ?? 0;

            final choices = data['choices'] as Map<String, dynamic>? ?? {};
            angelTotal += (choices['angel'] as num?)?.toInt() ?? 0;
            devilTotal += (choices['devil'] as num?)?.toInt() ?? 0;

            final sites = data['distractingSites'] as Map<String, dynamic>? ?? {};
            sites.forEach((site, count) {
              allSites[site] = (allSites[site] ?? 0) + ((count as num?)?.toInt() ?? 0);
            });
          }

          final avgScore = sessions.isNotEmpty ? totalScore / sessions.length : 0.0;
          final focusHours = totalFocusMs / 3600000;
          final distractionMins = totalDistractionMs / 60000;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // User info
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox.shrink();
                  final uData = snap.data!.data() as Map<String, dynamic>? ?? {};
                  return Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white30,
                          child: Text(
                            (uData['name'] as String? ?? 'U').isNotEmpty
                                ? (uData['name'] as String)[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                uData['name'] as String? ?? 'User',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '${uData['college'] ?? ''} • ${uData['course'] ?? ''} • ${uData['year'] ?? ''}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: Text(
                            '${sessions.length} sessions',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Key stats grid
              const _SectionTitle('Overview'),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  _StatCard(
                    label: 'Avg Focus Score',
                    value: '${avgScore.toStringAsFixed(0)}%',
                    icon: Icons.track_changes_rounded,
                    color: AppTheme.primary,
                    bg: AppTheme.primaryLight,
                    subtitle: 'across all sessions',
                  ),
                  _StatCard(
                    label: 'Total Focus Time',
                    value: '${focusHours.toStringAsFixed(1)}h',
                    icon: Icons.timer_rounded,
                    color: AppTheme.success,
                    bg: AppTheme.successBg,
                    subtitle: 'cumulative',
                  ),
                  _StatCard(
                    label: 'Total Distractions',
                    value: '$totalDistractions',
                    icon: Icons.notifications_off_outlined,
                    color: AppTheme.error,
                    bg: AppTheme.errorBg,
                    subtitle: 'times distracted',
                  ),
                  _StatCard(
                    label: 'Distraction Time',
                    value: '${distractionMins.toStringAsFixed(1)}m',
                    icon: Icons.hourglass_bottom_rounded,
                    color: AppTheme.warning,
                    bg: AppTheme.warningBg,
                    subtitle: 'total lost',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Angel vs Devil
              const _SectionTitle('Angel vs Devil Choices'),
              const SizedBox(height: 12),
              _AngelDevilCard(angel: angelTotal, devil: devilTotal),

              const SizedBox(height: 24),

              // Top distracting sites
              if (allSites.isNotEmpty) ...[
                const _SectionTitle('Top Distracting Sites'),
                const SizedBox(height: 12),
                _DistractingSitesCard(sites: allSites),
                const SizedBox(height: 24),
              ],

              // Recent sessions
              const _SectionTitle('Recent Sessions'),
              const SizedBox(height: 12),
              ...sessions.take(5).map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _SessionCard(data: data);
              }),

              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.text,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;
  final String subtitle;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AngelDevilCard extends StatelessWidget {
  final int angel;
  final int devil;

  const _AngelDevilCard({required this.angel, required this.devil});

  @override
  Widget build(BuildContext context) {
    final total = angel + devil;
    final angelRatio = total > 0 ? angel / total : 0.5;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('😇 Angel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.text)),
                    const SizedBox(height: 2),
                    Text(
                      '$angel choices',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.success),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('😈 Devil', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.text)),
                    const SizedBox(height: 2),
                    Text(
                      '$devil choices',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: (angelRatio * 100).round(),
                    child: Container(color: AppTheme.success),
                  ),
                  Expanded(
                    flex: 100 - (angelRatio * 100).round(),
                    child: Container(color: AppTheme.error),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            angelRatio >= 0.5
                ? '🎉 You resisted ${(angelRatio * 100).toStringAsFixed(0)}% of the time!'
                : '💪 Try to resist more distractions!',
            style: const TextStyle(color: AppTheme.textLight, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DistractingSitesCard extends StatelessWidget {
  final Map<String, int> sites;

  const _DistractingSitesCard({required this.sites});

  @override
  Widget build(BuildContext context) {
    final sorted = sites.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = sorted.first.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: sorted.take(5).map((entry) {
          final ratio = entry.value / maxVal;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          color: AppTheme.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.errorBg,
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Text(
                        '${entry.value}x',
                        style: const TextStyle(
                          color: AppTheme.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  child: LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: AppTheme.borderLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.error),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _SessionCard({required this.data});

  String _formatDuration(int ms) {
    final duration = Duration(milliseconds: ms);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    }
    return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    if (ts is Timestamp) {
      return DateFormat('MMM d, h:mm a').format(ts.toDate());
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final score = (data['focusScore'] as num?)?.toInt() ?? 0;
    final duration = (data['duration'] as num?)?.toInt() ?? 0;
    final distractions = (data['distractions'] as num?)?.toInt() ?? 0;
    final distractionTime = (data['distractionTime'] as num?)?.toInt() ?? 0;
    final createdAt = data['createdAt'];

    Color scoreColor = AppTheme.success;
    if (score < 60) scoreColor = AppTheme.error;
    else if (score < 80) scoreColor = AppTheme.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: score >= 80
                      ? AppTheme.successBg
                      : score >= 60
                          ? AppTheme.warningBg
                          : AppTheme.errorBg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: scoreColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Score: $score',
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                _formatTimestamp(createdAt),
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _SessionStat(
                icon: Icons.timer_outlined,
                value: _formatDuration(duration),
                label: 'Duration',
                color: AppTheme.primary,
              ),
              _SessionStat(
                icon: Icons.notifications_off_outlined,
                value: '$distractions',
                label: 'Distractions',
                color: AppTheme.error,
              ),
              _SessionStat(
                icon: Icons.hourglass_bottom_rounded,
                value: _formatDuration(distractionTime),
                label: 'Lost',
                color: AppTheme.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _SessionStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}