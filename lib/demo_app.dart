import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindflow/providers/task_providers.dart';
import 'package:mindflow/screens/analytics_screen.dart';
import 'package:mindflow/screens/focus_timer_screen.dart';
import 'package:mindflow/screens/graphics_demo_screen.dart';

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'TaskFlow - Demo',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          fontFamily: 'Rubik',
        ),
        home: const DemoHomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class DemoHomeScreen extends ConsumerStatefulWidget {
  const DemoHomeScreen({super.key});

  @override
  ConsumerState<DemoHomeScreen> createState() => _DemoHomeScreenState();
}

class _DemoHomeScreenState extends ConsumerState<DemoHomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const DemoTasksView(),
    const AnalyticsScreen(),
    const FocusTimerScreen(),
    const GraphicsDemoScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskFlow - דמו', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showDemoInfo(context),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task),
            label: 'משימות',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'סטטיסטיקות',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'פוקוס',
          ),
          NavigationDestination(
            icon: Icon(Icons.palette_outlined),
            selectedIcon: Icon(Icons.palette),
            label: 'גרפיקות',
          ),
        ],
      ),
    );
  }

  void _showDemoInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎯 TaskFlow Demo'),
        content: const Text(
          'זה הוא דמו של אפליקציית TaskFlow - מערכת ניהול משימות מתקדמת עם:\n\n'
          '📊 לוח סטטיסטיקות מתקדם\n'
          '⏱️ טיימר פוקוס (פומודורו)\n'
          '🧠 תכנון מיוחד למשתמשים עם ADHD\n'
          '🎮 גיימיפיקציה ומוטיבציה\n'
          '📱 עיצוב עברי-ראשון',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('סגור'),
          ),
        ],
      ),
    );
  }
}

class DemoTasksView extends StatelessWidget {
  const DemoTasksView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.waving_hand, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'ברוכים הבאים ל-TaskFlow!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'אפליקציית ניהול משימות מתקדמת המיועדת במיוחד עבור דוברי עברית עם ADHD',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Demo features
          Text(
            'תכונות מרכזיות',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Expanded(
            child: ListView(
              children: [
                _buildFeatureCard(
                  context,
                  icon: Icons.analytics,
                  title: 'סטטיסטיקות מתקדמות',
                  description: 'לוח בקרה עם גרפים ותובנות על הפרודוקטיביות שלך',
                  color: Colors.blue,
                ),
                
                _buildFeatureCard(
                  context,
                  icon: Icons.timer,
                  title: 'טיימר פוקוס (פומודורו)',
                  description: 'עבוד בסשנים קצרים עם הפסקות לשיפור הריכוז',
                  color: Colors.green,
                ),
                
                _buildFeatureCard(
                  context,
                  icon: Icons.track_changes,
                  title: 'מעקב הרגלים',
                  description: 'בנה הרגלים טובים ועקוב אחר ההתקדמות שלך',
                  color: Colors.orange,
                ),
                
                _buildFeatureCard(
                  context,
                  icon: Icons.psychology,
                  title: 'תכונות ADHD',
                  description: 'כלים מיוחדים לשיפור הזיכרון וההתמקדות',
                  color: Colors.purple,
                ),
                
                _buildFeatureCard(
                  context,
                  icon: Icons.mic,
                  title: 'קלט קולי בעברית',
                  description: 'הוסף משימות באמצעות פקודות קוליות בעברית',
                  color: Colors.red,
                ),
                
                _buildFeatureCard(
                  context,
                  icon: Icons.lightbulb,
                  title: 'תובנות חכמות',
                  description: 'המלצות אישיות לשיפור הפרודוקטיביות',
                  color: Colors.amber,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
          textDirection: TextDirection.rtl,
        ),
        subtitle: Text(
          description,
          textDirection: TextDirection.rtl,
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
