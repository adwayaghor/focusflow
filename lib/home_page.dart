import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'theme.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final String userId = "Ms2vKxs1ThU0wWZOCosw2yYlex93"; // replace dynamically later

  late Future<List<QueryDocumentSnapshot>> sessionsFuture;

  @override
  void initState() {
    super.initState();
    sessionsFuture = fetchSessions();
  }

  Future<List<QueryDocumentSnapshot>> fetchSessions() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('sessions')
        .orderBy('createdAt')
        .get();

    return snapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("FocusFlow Dashboard"),
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: sessionsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sessions = snapshot.data!;

          final focusScores = sessions
              .map((e) => (e['focusScore'] ?? 0).toDouble())
              .toList();

          final distractions = sessions
              .map((e) => (e['distractions'] ?? 0).toDouble())
              .toList();

          final totalDuration = sessions.fold<int>(
              0, (sum, e) => sum + ((e['duration'] ?? 0) as int));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                // ===== Total Duration Card =====
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          "Total Study Time",
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${(totalDuration / 3600).toStringAsFixed(2)} hrs",
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ===== Focus Score Line Chart =====
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Focus Score Trend",
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  height: 250,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      borderData: FlBorderData(
                        border: Border.all(
                          color: AppTheme.border,
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          color: AppTheme.primary,
                          barWidth: 3,
                          spots: List.generate(
                            focusScores.length,
                            (index) => FlSpot(
                              index.toDouble(),
                              focusScores[index],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ===== Distraction Bar Chart =====
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Distractions per Session",
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      borderData: FlBorderData(
                        border: Border.all(color: AppTheme.border),
                      ),
                      barGroups: List.generate(
                        distractions.length,
                        (index) => BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: distractions[index],
                              color: AppTheme.secondary,
                              width: 18,
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusXs),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}