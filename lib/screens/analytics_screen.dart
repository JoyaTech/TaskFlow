import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mindflow/providers/task_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskStatsAsync = ref.watch(taskStatsProvider);
    final focusSession = ref.watch(focusSessionProvider);
    final habits = ref.watch(habitProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('סטטיסטיקות ותובנות'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(taskStatsProvider),
          ),
        ],
      ),
      body: taskStatsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text('שגיאה בטעינת הנתונים: $error'),
            ],
          ),
        ),
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Stats Cards
              _buildQuickStatsSection(context, stats, focusSession, habits),
              
              const SizedBox(height: 24),
              
              // Task Completion Chart
              _buildTaskCompletionChart(context, stats),
              
              const SizedBox(height: 24),
              
              // Weekly Progress
              _buildWeeklyProgressChart(context),
              
              const SizedBox(height: 24),
              
              // Focus Time Analytics
              _buildFocusTimeSection(context, stats, focusSession),
              
              const SizedBox(height: 24),
              
              // Habit Tracking Overview
              _buildHabitOverview(context, habits),
              
              const SizedBox(height: 24),
              
              // Productivity Insights
              _buildProductivityInsights(context, stats),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatsSection(BuildContext context, TaskStatistics stats, 
      FocusSessionState focusSession, HabitState habits) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'סיכום מהיר',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'משימות הושלמו היום',
                '${stats.completedToday}',
                Icons.check_circle,
                Theme.of(context).colorScheme.primary,
                subtitle: 'מתוך ${stats.todayTasks} משימות',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'רצף יומי',
                '${stats.weeklyStreak}',
                Icons.local_fire_department,
                Colors.orange,
                subtitle: 'ימים ברצף',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'זמן פוקוס היום',
                '${stats.focusTimeToday.inHours}ש ${stats.focusTimeToday.inMinutes % 60}ד',
                Icons.timer,
                Theme.of(context).colorScheme.tertiary,
                subtitle: '${focusSession.completedSessions} סשנים',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'הרגלים פעילים',
                '${habits.habits.length}',
                Icons.track_changes,
                Theme.of(context).colorScheme.secondary,
                subtitle: _getCompletedHabitsToday(habits),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, 
      IconData icon, Color color, {String? subtitle}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCompletionChart(BuildContext context, TaskStatistics stats) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'התקדמות משימות',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      color: Theme.of(context).colorScheme.primary,
                      value: stats.completedTasks.toDouble(),
                      title: 'הושלמו\n${stats.completedTasks}',
                      radius: 60,
                      titleStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      value: (stats.totalTasks - stats.completedTasks).toDouble(),
                      title: 'נותרו\n${stats.totalTasks - stats.completedTasks}',
                      radius: 50,
                      titleStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                  centerSpaceRadius: 50,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem(context, 'הושלמו', Theme.of(context).colorScheme.primary),
                _buildLegendItem(context, 'נותרו', Theme.of(context).colorScheme.outline.withOpacity(0.3)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyProgressChart(BuildContext context) {
    // Mock data for weekly progress
    final weeklyData = [
      FlSpot(0, 3),
      FlSpot(1, 4),
      FlSpot(2, 2),
      FlSpot(3, 5),
      FlSpot(4, 3),
      FlSpot(5, 4),
      FlSpot(6, 6),
    ];
    
    final days = ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש'];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'התקדמות שבועית',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}',
                              style: Theme.of(context).textTheme.bodySmall);
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < days.length) {
                            return Text(days[value.toInt()],
                                style: Theme.of(context).textTheme.bodySmall);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: weeklyData,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      ),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: Theme.of(context).colorScheme.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusTimeSection(BuildContext context, TaskStatistics stats, 
      FocusSessionState focusSession) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer, color: Theme.of(context).colorScheme.tertiary),
                const SizedBox(width: 8),
                Text(
                  'זמן פוקוס ופרודוקטיביות',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildFocusMetric(
                    context,
                    'סשנים היום',
                    '${focusSession.completedSessions}',
                    Icons.play_circle,
                  ),
                ),
                Expanded(
                  child: _buildFocusMetric(
                    context,
                    'זמן כולל',
                    '${stats.focusTimeToday.inMinutes}ד',
                    Icons.access_time,
                  ),
                ),
                Expanded(
                  child: _buildFocusMetric(
                    context,
                    'יעילות',
                    '${(stats.todayCompletionRate * 100).round()}%',
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusMetric(BuildContext context, String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.tertiary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHabitOverview(BuildContext context, HabitState habits) {
    if (habits.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.track_changes, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'מעקב הרגלים',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...habits.habits.map((habit) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    habit.isCompletedToday() ? Icons.check_circle : Icons.circle_outlined,
                    color: habit.isCompletedToday() 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'רצף: ${habit.getCurrentStreak()} ימים',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStreakIndicator(context, habit.getCurrentStreak()),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakIndicator(BuildContext context, int streak) {
    Color color = Theme.of(context).colorScheme.outline;
    if (streak >= 7) color = Theme.of(context).colorScheme.primary;
    if (streak >= 21) color = Colors.orange;
    if (streak >= 30) color = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '🔥 $streak',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildProductivityInsights(BuildContext context, TaskStatistics stats) {
    final insights = _generateInsights(stats);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'תובנות פרודוקטיביות',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...insights.map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: insight.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(insight.icon, color: insight.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insight.title,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          insight.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _getCompletedHabitsToday(HabitState habits) {
    final completed = habits.habits.where((h) => h.isCompletedToday()).length;
    return '$completed הושלמו היום';
  }

  List<ProductivityInsight> _generateInsights(TaskStatistics stats) {
    final insights = <ProductivityInsight>[];
    
    // Completion rate insight
    if (stats.todayCompletionRate >= 0.8) {
      insights.add(ProductivityInsight(
        title: 'יום מעולה!',
        description: 'השלמת ${(stats.todayCompletionRate * 100).round()}% מהמשימות שלך היום. המשך כך!',
        icon: Icons.star,
        color: Colors.green,
      ));
    } else if (stats.todayCompletionRate < 0.5) {
      insights.add(ProductivityInsight(
        title: 'הזדמנות לשיפור',
        description: 'נסה לחלק משימות גדולות למשימות קטנות יותר לתחושת הצלחה גדולה יותר.',
        icon: Icons.trending_up,
        color: Colors.orange,
      ));
    }
    
    // Streak insight
    if (stats.weeklyStreak >= 7) {
      insights.add(ProductivityInsight(
        title: 'רצף מדהים!',
        description: '${stats.weeklyStreak} ימים ברצף של פרודוקטיביות. אתה בדרך הנכונה!',
        icon: Icons.local_fire_department,
        color: Colors.red,
      ));
    }
    
    // Focus time insight
    if (stats.focusTimeToday.inMinutes >= 120) {
      insights.add(ProductivityInsight(
        title: 'זמן פוקוס מצוין',
        description: '${stats.focusTimeToday.inMinutes} דקות של עבודה מרוכזת היום. המוח שלך אוהב את זה!',
        icon: Icons.psychology,
        color: Colors.purple,
      ));
    }
    
    return insights;
  }
}

class ProductivityInsight {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  
  ProductivityInsight({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
