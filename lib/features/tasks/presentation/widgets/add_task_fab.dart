import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/task_providers.dart';
import '../../domain/entities/task.dart';

/// Floating Action Button for adding new tasks
class AddTaskFab extends ConsumerWidget {
  const AddTaskFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () => _showAddTaskDialog(context, ref),
      icon: const Icon(Icons.add),
      label: const Text('משימה חדשה'),
    );
  }

  void _showAddTaskDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(ref: ref),
    );
  }
}

/// Dialog for adding a new task
class AddTaskDialog extends StatefulWidget {
  final WidgetRef ref;

  const AddTaskDialog({super.key, required this.ref});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TaskPriority _selectedPriority = TaskPriority.simple;
  TaskType _selectedType = TaskType.task;
  DateTime? _selectedDueDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('משימה חדשה'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'כותרת המשימה *',
                hintText: 'הזן את כותרת המשימה',
                prefixIcon: Icon(Icons.title),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'תיאור (אופציונלי)',
                hintText: 'הזן תיאור של המשימה',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.flag),
                const SizedBox(width: 8),
                const Text('עדיפות:'),
                const Spacer(),
                DropdownButton<TaskPriority>(
                  value: _selectedPriority,
                  items: TaskPriority.values.map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(priority.emoji),
                          const SizedBox(width: 8),
                          Text(priority.hebrewName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPriority = value;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.category),
                const SizedBox(width: 8),
                const Text('סוג:'),
                const Spacer(),
                DropdownButton<TaskType>(
                  value: _selectedType,
                  items: TaskType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(type.emoji),
                          const SizedBox(width: 8),
                          Text(type.hebrewName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.schedule),
                const SizedBox(width: 8),
                const Text('תאריך יעד:'),
                const Spacer(),
                TextButton(
                  onPressed: () => _selectDueDate(context),
                  child: Text(
                    _selectedDueDate != null
                        ? '${_selectedDueDate!.day}/${_selectedDueDate!.month}'
                        : 'בחר תאריך',
                  ),
                ),
                if (_selectedDueDate != null)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedDueDate = null;
                      });
                    },
                    icon: const Icon(Icons.clear, size: 20),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ביטול'),
        ),
        ElevatedButton(
          onPressed: _titleController.text.trim().isEmpty ? null : _addTask,
          child: const Text('הוסף'),
        ),
      ],
    );
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      setState(() {
        _selectedDueDate = DateTime(
          date.year,
          date.month,
          date.day,
          time?.hour ?? 9,
          time?.minute ?? 0,
        );
      });
    }
  }

  void _addTask() {
    if (_titleController.text.trim().isEmpty) return;

    widget.ref.read(taskListProvider.notifier).addTask(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _selectedPriority,
          type: _selectedType,
          dueDate: _selectedDueDate,
        );

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
