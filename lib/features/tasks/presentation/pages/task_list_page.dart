import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/task_providers.dart';
import '../widgets/task_item_widget.dart';
import '../widgets/task_filter_bar.dart';
import '../widgets/add_task_fab.dart';
import '../../domain/entities/task.dart';

/// Modern task list page using Clean Architecture with Riverpod
class TaskListPage extends ConsumerWidget {
  const TaskListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredTasksAsync = ref.watch(filteredTasksProvider);
    final currentFilter = ref.watch(taskFilterProvider);
    final taskStats = ref.watch(taskStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getPageTitle(currentFilter)),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(taskListProvider.notifier).refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Card
          _buildStatsCard(context, taskStats),
          
          // Filter Bar
          const TaskFilterBar(),
          
          // Task List
          Expanded(
            child: filteredTasksAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => _buildErrorState(context, error.toString()),
              data: (tasks) => _buildTaskList(context, tasks),
            ),
          ),
        ],
      ),
      floatingActionButton: const AddTaskFab(),
    );
  }

  Widget _buildStatsCard(BuildContext context, TaskStats stats) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            icon: Icons.task_alt,
            label: 'סה"כ',
            value: stats.total.toString(),
          ),
          _buildStatItem(
            context,
            icon: Icons.check_circle,
            label: 'הושלמו',
            value: stats.completed.toString(),
            color: Colors.green,
          ),
          _buildStatItem(
            context,
            icon: Icons.pending,
            label: 'בהמתנה',
            value: stats.pending.toString(),
            color: Colors.orange,
          ),
          _buildStatItem(
            context,
            icon: Icons.warning,
            label: 'פיגור',
            value: stats.overdue.toString(),
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color ?? Theme.of(context).colorScheme.onPrimaryContainer,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: color ?? Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color?.withOpacity(0.7) ?? 
                Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskList(BuildContext context, List<Task> tasks) {
    if (tasks.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskItemWidget(
          key: ValueKey(task.id),
          task: task,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'אין משימות להצגה',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'לחץ על + כדי ליצור משימה חדשה',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'שגיאה בטעינת המשימות',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Retry logic would go here
            },
            icon: const Icon(Icons.refresh),
            label: const Text('נסה שנית'),
          ),
        ],
      ),
    );
  }

  String _getPageTitle(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.all:
        return 'כל המשימות';
      case TaskFilter.pending:
        return 'משימות בהמתנה';
      case TaskFilter.completed:
        return 'משימות שהושלמו';
      case TaskFilter.today:
        return 'משימות היום';
      case TaskFilter.overdue:
        return 'משימות בפיגור';
      case TaskFilter.important:
        return 'משימות חשובות';
    }
  }

  void _showSearchDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('חיפוש משימות'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'הזן טקסט לחיפוש...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              // Search logic would go here
              Navigator.of(context).pop();
            },
            child: const Text('חיפוש'),
          ),
        ],
      ),
    );
  }
}
