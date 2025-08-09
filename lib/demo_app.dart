import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindflow/core/theme/app_theme.dart';
import 'package:mindflow/core/theme/theme_provider.dart';
import 'package:mindflow/providers/task_providers.dart';
import 'package:mindflow/screens/analytics_screen.dart';
import 'package:mindflow/screens/focus_timer_screen.dart';
import 'package:mindflow/screens/graphics_demo_screen.dart';

class DemoApp extends ConsumerWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    
    return MaterialApp(
      title: 'TaskFlow - Demo',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const DemoHomeScreen(),
      debugShowCheckedModeBanner: false,
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
        actions: [
          // Theme toggle button
          Consumer(
            builder: (context, ref, child) {
              final themeNotifier = ref.read(themeProvider.notifier);
              return IconButton(
                icon: Icon(themeNotifier.currentThemeIcon),
                tooltip: 'החלף ערכת נושא (${themeNotifier.currentThemeDisplayName})',
                onPressed: () => themeNotifier.toggleTheme(),
              );
            },
          ),
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

class DemoTasksView extends ConsumerWidget {
  const DemoTasksView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          
          // Theme Demo Section
          _buildThemeDemoSection(context, ref),
          
          const SizedBox(height: 24),
          
          Text(
            'מאפיינים נוספים',
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
                  color: Theme.of(context).colorScheme.primary,
                ),
                
                _buildFeatureCard(
                  context,
                  icon: Icons.timer,
                  title: 'טיימר פוקוס (פומודורו)',
                  description: 'עבוד בסשנים קצרים עם הפסקות לשיפור הריכוז',
                  color: Theme.of(context).colorScheme.secondary,
                ),
                
                _buildFeatureCard(
                  context,
                  icon: Icons.track_changes,
                  title: 'מעקב הרגלים',
                  description: 'בנה הרגלים טובים ועקוב אחר ההתקדמות שלך',
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                
                _buildFeatureCard(
                  context,
                  icon: Icons.psychology,
                  title: 'תכונות ADHD',
                  description: 'כלים מיוחדים לשיפור הזיכרון וההתמקדות',
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ),
                
                _buildFeatureCard(
                  context,
                  icon: Icons.mic,
                  title: 'קלט קולי בעברית',
                  description: 'הוסף משימות באמצעות פקודות קוליות בעברית',
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                ),
                
                _buildFeatureCard(
                  context,
                  icon: Icons.lightbulb,
                  title: 'תובנות חכמות',
                  description: 'המלצות אישיות לשיפור הפרודוקטיביות',
                  color: Theme.of(context).colorScheme.tertiary.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeDemoSection(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.read(themeProvider.notifier);
    final currentTheme = ref.watch(themeProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.palette, size: 24),
                const SizedBox(width: 12),
                Text(
                  'נסו את מערכת הערכות!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'מערכת ערכות דינמית עם תמיכה מלאה בצבעים בהירים וכהים',
              style: Theme.of(context).textTheme.bodyMedium,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 16),
            Text(
              'מצב נוכחי: ${themeNotifier.currentThemeDisplayName}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildThemeButton(
                  context,
                  icon: Icons.light_mode,
                  label: 'מצב בהיר',
                  isSelected: currentTheme == ThemeMode.light,
                  onPressed: () => themeNotifier.setLightTheme(),
                ),
                _buildThemeButton(
                  context,
                  icon: Icons.dark_mode,
                  label: 'מצב כהה',
                  isSelected: currentTheme == ThemeMode.dark,
                  onPressed: () => themeNotifier.setDarkTheme(),
                ),
                _buildThemeButton(
                  context,
                  icon: Icons.auto_mode,
                  label: 'לפי המכשיר',
                  isSelected: currentTheme == ThemeMode.system,
                  onPressed: () => themeNotifier.setSystemTheme(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildThemeButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: isSelected 
          ? Theme.of(context).colorScheme.primary 
          : Theme.of(context).colorScheme.surfaceVariant,
        foregroundColor: isSelected 
          ? Theme.of(context).colorScheme.onPrimary 
          : Theme.of(context).colorScheme.onSurfaceVariant,
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
