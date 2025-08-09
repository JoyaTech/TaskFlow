import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task.dart';
import '../providers/task_providers.dart';

/// Modern task item widget with completion animation and actions
class TaskItemWidget extends ConsumerWidget {
  final Task task;

  const TaskItemWidget({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: task.isCompleted
              ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5)
              : Theme.of(context).colorScheme.surface,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: _buildLeadingIcon(context, ref),
          title: _buildTitle(context),
          subtitle: _buildSubtitle(context),
          trailing: _buildTrailing(context),
          onTap: () => _showTaskDetails(context, ref),
          onLongPress: () => _showTaskActions(context, ref),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(taskListProvider.notifier).toggleTaskCompletion(task.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: task.isCompleted
                ? Colors.green
                : _getPriorityColor(task.priority),
            width: 2,
          ),
          color: task.isCompleted
              ? Colors.green
              : Colors.transparent,
        ),
        child: task.isCompleted
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 18,
              )
            : null,
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            task.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              decoration: task.isCompleted
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              color: task.isCompleted
                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                  : Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          task.priority.emoji,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(width: 4),
        Text(
          task.type.emoji,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final subtitle = <String>[];

    if (task.description.isNotEmpty) {
      subtitle.add(task.description);
    }

    if (task.dueDate != null) {
      final dueText = _formatDueDate(task.dueDate!);
      subtitle.add(dueText);
    }

    if (task.tags.isNotEmpty) {
      subtitle.add('${task.tags.join(', ')}#');
    }

    if (subtitle.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        subtitle.join(' • '),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: task.isCompleted
              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTrailing(BuildContext context) {
    if (task.isOverdue && !task.isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red, width: 1),
        ),
        child: Text(
          'פיגור',
          style: TextStyle(
            color: Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (task.isDueToday && !task.isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange, width: 1),
        ),
        child: Text(
          'היום',
          style: TextStyle(
            color: Colors.orange,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.important:
        return Colors.red;
      case TaskPriority.simple:
        return Colors.blue;
      case TaskPriority.later:
        return Colors.grey;
    }
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    if (taskDay == today) {
      return 'היום ${dueDate.hour.toString().padLeft(2, '0')}:${dueDate.minute.toString().padLeft(2, '0')}';
    } else if (taskDay == today.add(const Duration(days: 1))) {
      return 'מחר';
    } else if (taskDay == today.subtract(const Duration(days: 1))) {
      return 'אתמול';
    } else {
      return '${dueDate.day}/${dueDate.month}';
    }
  }

  void _showTaskDetails(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskDetailsSheet(task: task),
    );
  }

  void _showTaskActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => TaskActionsSheet(task: task),
    );
  }
}

/// Task details bottom sheet
class TaskDetailsSheet extends StatelessWidget {
  final Task task;

  const TaskDetailsSheet({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'תיאור:',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(task.description),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.flag, size: 16),
              const SizedBox(width: 8),
              Text('${task.priority.hebrewName} ${task.priority.emoji}'),
              const SizedBox(width: 24),
              Icon(task.type == TaskType.task ? Icons.task : Icons.event, size: 16),
              const SizedBox(width: 8),
              Text('${task.type.hebrewName} ${task.type.emoji}'),
            ],
          ),
          if (task.dueDate != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16),
                const SizedBox(width: 8),
                Text('תאריך יעד: ${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}'),
              ],
            ),
          ],
          if (task.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: task.tags.map((tag) => Chip(
                label: Text(tag),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Task actions bottom sheet
class TaskActionsSheet extends ConsumerWidget {
  final Task task;

  const TaskActionsSheet({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('ערוך משימה'),
            onTap: () {
              Navigator.of(context).pop();
              // Navigate to edit task screen
            },
          ),
          ListTile(
            leading: Icon(task.isCompleted ? Icons.undo : Icons.check_circle),
            title: Text(task.isCompleted ? 'סמן כלא הושלם' : 'סמן כהושלם'),
            onTap: () {
              ref.read(taskListProvider.notifier).toggleTaskCompletion(task.id);
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('מחק משימה', style: TextStyle(color: Colors.red)),
            onTap: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחק משימה'),
        content: Text('האם אתה בטוח שברצונך למחוק את "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(taskListProvider.notifier).deleteTask(task.id);
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close bottom sheet
            },
            child: const Text('מחק'),
          ),
        ],
      ),
    );
  }
}
