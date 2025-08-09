import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindflow/task_model.dart';
import 'package:mindflow/providers/task_providers.dart';
import 'package:mindflow/services/mock_database_service.dart';
import 'package:mindflow/widgets/custom_graphics.dart';
import 'package:intl/intl.dart';

class TaskListWidget extends StatefulWidget {
  final List<Task> tasks;
  final Function(Task) onTaskTap;
  final Function(Task) onTaskCompleted;
  final bool showDate;

  const TaskListWidget({
    super.key,
    required this.tasks,
    required this.onTaskTap,
    required this.onTaskCompleted,
    this.showDate = true,
  });

  @override
  State<TaskListWidget> createState() => _TaskListWidgetState();
}

class _TaskListWidgetState extends State<TaskListWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _celebrationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

@override
  Widget build(BuildContext context) {
    if (widget.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MindFlowGraphics.allDoneIllustration(size: 100),
            const SizedBox(height: 24),
            Text(
              'סיימת הכל! כל הכבוד 🎉',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'הגיע הזמן לנוח וליהנות\nאו להוסיף משימות חדשות',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.tasks.length,
      itemBuilder: (context, index) {
        final task = widget.tasks[index];
        return ADHDTaskCard(
          task: task,
          onTap: () => widget.onTaskTap(task),
          onCompleted: () => _handleTaskCompletion(task),
          showDate: widget.showDate,
          animationController: _celebrationController,
        );
      },
    );
  }

  void _handleTaskCompletion(Task task) async {
    if (task.isCompleted) return;

    // Animate completion
    _animationController.forward();

    // Update database
    await MockDatabaseService.markTaskCompleted(task.id);

    // Call parent callback
    widget.onTaskCompleted(task);

    // Show celebration
    if (mounted) {
      _showCompletionCelebration(context);
    }
  }

  void _showCompletionCelebration(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              'כל הכבוד! משימה הושלמה 🎉',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ADHD-Optimized Task Card with enhanced visual processing and micro-rewards
class ADHDTaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onCompleted;
  final bool showDate;
  final AnimationController animationController;

  const ADHDTaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onCompleted,
    this.showDate = true,
    required this.animationController,
  });

  @override
  State<ADHDTaskCard> createState() => _ADHDTaskCardState();
}

class _ADHDTaskCardState extends State<ADHDTaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _completionController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _completionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _completionController, curve: Curves.elasticOut),
    );
    
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _completionController, curve: Curves.bounceOut),
    );
    
    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.green.withOpacity(0.3),
    ).animate(CurvedAnimation(parent: _completionController, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _completionController.dispose();
    super.dispose();
  }

  void _handleCompletion() {
    if (!widget.task.isCompleted) {
      _completionController.forward().then((_) {
        _completionController.reverse();
        _showMicroReward();
      });
    }
    widget.onCompleted();
  }

  void _showMicroReward() {
    // Show confetti or celebration animation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'כל הכבוד! +10 נקודות',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'הושלמה: ${widget.task.title}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = widget.task.dueDate != null &&
        widget.task.dueDate!.isBefore(DateTime.now()) &&
        !widget.task.isCompleted;
    
    final priorityColor = _getPriorityColor(context, widget.task.priority);
    
    return AnimatedBuilder(
      animation: _completionController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                // ADHD-friendly visual priority indicator
                border: Border.all(
                  color: priorityColor.withOpacity(0.5),
                  width: widget.task.priority == TaskPriority.important ? 3 : 1,
                ),
                color: _colorAnimation.value ?? Colors.transparent,
              ),
              child: Card(
                margin: EdgeInsets.zero,
                elevation: widget.task.priority == TaskPriority.important ? 4 : 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: widget.task.isCompleted
                    ? Theme.of(context).colorScheme.surface.withOpacity(0.5)
                    : _getTaskBackgroundColor(context, widget.task.priority),
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _buildCompletionCheckbox(priorityColor),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTaskContent(context, isOverdue)),
                        _buildPriorityIndicator(context, priorityColor),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletionCheckbox(Color priorityColor) {
    return GestureDetector(
      onTap: _handleCompletion,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.task.isCompleted ? priorityColor : priorityColor.withOpacity(0.5),
            width: 3,
          ),
          color: widget.task.isCompleted ? priorityColor : Colors.transparent,
          boxShadow: widget.task.isCompleted
              ? [
                  BoxShadow(
                    color: priorityColor.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: widget.task.isCompleted
            ? Icon(
                Icons.check,
                size: 18,
                color: Theme.of(context).colorScheme.onPrimary,
              )
            : null,
      ),
    );
  }

  Widget _buildTaskContent(BuildContext context, bool isOverdue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with type emoji
        Row(
          children: [
            Text(
              widget.task.type.emoji,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.task.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  decoration: widget.task.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  color: widget.task.isCompleted
                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                      : null,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        // Progress bar for visual feedback
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: widget.task.isCompleted ? 1.0 : 0.3, // Show some progress for visual appeal
          backgroundColor: Colors.grey.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(
            _getPriorityColor(context, widget.task.priority),
          ),
          minHeight: 4,
        ),

        // Description
        if (widget.task.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            widget.task.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        // Due date with enhanced visual cues
        if (widget.showDate && widget.task.dueDate != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isOverdue
                  ? Theme.of(context).colorScheme.error.withOpacity(0.1)
                  : Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: isOverdue
                  ? Border.all(color: Theme.of(context).colorScheme.error, width: 1)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOverdue ? Icons.warning : Icons.schedule,
                  size: 14,
                  color: isOverdue
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(widget.task.dueDate!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isOverdue
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriorityIndicator(BuildContext context, Color priorityColor) {
    if (widget.task.priority == TaskPriority.simple) return const SizedBox.shrink();
    
    return Container(
      width: 4,
      height: 60,
      decoration: BoxDecoration(
        color: priorityColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) {
      return 'היום ${DateFormat('HH:mm', 'he').format(date)}';
    } else if (taskDate == today.add(const Duration(days: 1))) {
      return 'מחר ${DateFormat('HH:mm', 'he').format(date)}';
    } else if (taskDate == today.subtract(const Duration(days: 1))) {
      return 'אתמול ${DateFormat('HH:mm', 'he').format(date)}';
    } else {
      return DateFormat('dd/MM HH:mm', 'he').format(date);
    }
  }

  Color _getPriorityColor(BuildContext context, TaskPriority priority) {
    switch (priority) {
      case TaskPriority.important:
        return Theme.of(context).colorScheme.error;
      case TaskPriority.later:
        return Theme.of(context).colorScheme.tertiary;
      case TaskPriority.simple:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Color _getTaskBackgroundColor(BuildContext context, TaskPriority priority) {
    switch (priority) {
      case TaskPriority.important:
        return Theme.of(context).colorScheme.errorContainer.withOpacity(0.1);
      case TaskPriority.later:
        return Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.1);
      case TaskPriority.simple:
        return Theme.of(context).colorScheme.surface;
    }
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onCompleted;
  final bool showDate;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onCompleted,
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        !task.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: task.isCompleted
          ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.5)
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Completion checkbox
              GestureDetector(
                onTap: onCompleted,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: task.isCompleted
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.5),
                      width: 2,
                    ),
                    color: task.isCompleted
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  child: task.isCompleted
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: Theme.of(context).colorScheme.onPrimary,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),

              // Task content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and type emoji
                    Row(
                      children: [
                        Text(
                          task.type.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            task.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: task.isCompleted
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.5)
                                      : null,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Description
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Due date and priority
                    if (showDate && (task.dueDate != null || task.priority != TaskPriority.simple)) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Due date
                          if (task.dueDate != null) ...[
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: isOverdue
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(task.dueDate!),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: isOverdue
                                        ? Theme.of(context).colorScheme.error
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
                                  ),
                            ),
                          ],

                          // Priority badge
                          if (task.priority != TaskPriority.simple) ...[
                            if (task.dueDate != null) const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getPriorityColor(context, task.priority)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    task.priority.emoji,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    task.priority.hebrewName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: _getPriorityColor(
                                              context, task.priority),
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) {
      return 'היום ${DateFormat('HH:mm', 'he').format(date)}';
    } else if (taskDate == today.add(const Duration(days: 1))) {
      return 'מחר ${DateFormat('HH:mm', 'he').format(date)}';
    } else if (taskDate == today.subtract(const Duration(days: 1))) {
      return 'אתמול ${DateFormat('HH:mm', 'he').format(date)}';
    } else {
      return DateFormat('dd/MM HH:mm', 'he').format(date);
    }
  }

  Color _getPriorityColor(BuildContext context, TaskPriority priority) {
    switch (priority) {
      case TaskPriority.important:
        return Theme.of(context).colorScheme.error;
      case TaskPriority.later:
        return Theme.of(context).colorScheme.tertiary;
      case TaskPriority.simple:
        return Theme.of(context).colorScheme.primary;
    }
  }
}