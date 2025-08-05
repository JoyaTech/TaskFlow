import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindflow/task_model.dart';
import 'package:mindflow/providers/task_providers.dart';
import 'package:mindflow/voice_service.dart';
import 'package:mindflow/task_list_widget.dart';
import 'package:mindflow/brain_dump_page.dart';
import 'package:mindflow/settings_page.dart';
import 'package:mindflow/services/mock_database_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  List<Task> _tasks = [];
  List<Task> _todayTasks = [];
  bool _isLoading = true;
  bool _isListening = false;
  int _completedTasksToday = 0;
  
  late TabController _tabController;
  late AnimationController _voiceAnimationController;
  late Animation<double> _voiceAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 4, vsync: this);
    
    _voiceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _voiceAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _voiceAnimationController, curve: Curves.easeInOut),
    );
    
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _voiceAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await VoiceService.initialize();
    await _loadTasks();
    
    // Initialize sample data if empty
    if (_tasks.isEmpty) {
      await MockDatabaseService.initSampleData();
      await _loadTasks();
    }
  }

  Future<void> _loadTasks() async {
    final tasks = await MockDatabaseService.getAllTasks();
    final todayTasks = await MockDatabaseService.getTodayTasks();
    final completedToday = await MockDatabaseService.getTodayCompletedTasksCount();
    
    if (mounted) {
      setState(() {
        _tasks = tasks;
        _todayTasks = todayTasks;
        _completedTasksToday = completedToday;
        _isLoading = false;
      });
    }
  }

  Future<void> _startVoiceCapture() async {
    if (!VoiceService.isAvailable) {
      _showMessage('קלט קולי לא זמין במכשיר זה');
      return;
    }

    setState(() => _isListening = true);
    _voiceAnimationController.repeat(reverse: true);

    try {
      final recognizedText = await VoiceService.startListening();
      
      if (recognizedText != null && recognizedText.isNotEmpty) {
        final parseResult = await VoiceService.parseHebrewCommand(recognizedText);
        
        if (parseResult != null) {
          final newTask = parseResult.toTask();
          await MockDatabaseService.insertTask(newTask);
          await _loadTasks();
          
          _showMessage('משימה נוספה בהצלחה: ${newTask.title}');
        } else {
          _showMessage('לא הצלחתי להבין את הפקודה');
        }
      } else {
        _showMessage('לא נקלט קול');
      }
    } catch (e) {
      _showMessage('שגיאה בקלט קולי');
    } finally {
      setState(() => _isListening = false);
      _voiceAnimationController.stop();
      _voiceAnimationController.reset();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _handleTaskTap(Task task) {
    // Show task details dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskDetailSheet(task: task, onUpdate: _loadTasks),
    );
  }

  void _handleTaskCompleted(Task task) {
    _loadTasks();
  }

  void _showManualTaskDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ManualTaskSheet(onTaskCreated: _loadTasks),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // App bar with greeting
          _buildAppBar(),
          
          // Progress indicators
          _buildProgressSection(),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTodayView(),
                _buildAllTasksView(),
                _buildCompletedView(),
                _buildNotesView(),
              ],
            ),
          ),
        ],
      ),
      
      // Floating action buttons
      floatingActionButton: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Manual task creation button
              FloatingActionButton(
                onPressed: _showManualTaskDialog,
                backgroundColor: Theme.of(context).colorScheme.secondary,
                heroTag: 'manual_task',
                child: const Icon(Icons.add, color: Colors.white),
              ),
              
              // Brain dump page button
              FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BrainDumpPage()),
                  );
                },
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                heroTag: 'brain_dump',
                child: const Icon(Icons.edit, color: Colors.white),
              ),
              
              // Voice capture button
              AnimatedBuilder(
                animation: _voiceAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isListening ? _voiceAnimation.value : 1.0,
                    child: FloatingActionButton.large(
                      onPressed: _isListening ? null : _startVoiceCapture,
                      backgroundColor: _isListening 
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)
                          : Theme.of(context).colorScheme.primary,
                      heroTag: 'voice_task',
                      child: _isListening
                          ? const Icon(Icons.mic, size: 32, color: Colors.white)
                          : const Icon(Icons.mic_none, size: 32, color: Colors.white),
                    ),
                  );
                },
              ),
            ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'מה נרצה להשיג היום?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer
                              .withValues(alpha: 0.8),
                        ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsPage()),
                  );
                },
                icon: Icon(
                  Icons.settings,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Tab bar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(25),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              unselectedLabelStyle: Theme.of(context).textTheme.labelMedium,
              tabs: const [
                Tab(text: 'היום'),
                Tab(text: 'הכל'),
                Tab(text: 'הושלמו'),
                Tab(text: 'פתקים'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final totalTasks = _todayTasks.length;
    final completedTasks = _completedTasksToday;
    final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Progress circle
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
          
          const SizedBox(width: 16),
          
          // Progress text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ההתקדמות שלך היום',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completedTasks מתוך $totalTasks משימות הושלמו',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
          
          // Celebration emoji
          if (progress >= 1.0)
            const Text('🎉', style: TextStyle(fontSize: 32)),
        ],
      ),
    );
  }

  Widget _buildTodayView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return TaskListWidget(
      tasks: _todayTasks,
      onTaskTap: _handleTaskTap,
      onTaskCompleted: _handleTaskCompleted,
    );
  }

  Widget _buildAllTasksView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final activeTasks = _tasks.where((task) => !task.isCompleted).toList();
    
    return TaskListWidget(
      tasks: activeTasks,
      onTaskTap: _handleTaskTap,
      onTaskCompleted: _handleTaskCompleted,
    );
  }

  Widget _buildCompletedView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final completedTasks = _tasks.where((task) => task.isCompleted).toList();
    
    return TaskListWidget(
      tasks: completedTasks,
      onTaskTap: _handleTaskTap,
      onTaskCompleted: _handleTaskCompleted,
    );
  }

  Widget _buildNotesView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final notes = _tasks.where((task) => task.type == TaskType.note).toList();
    
    return TaskListWidget(
      tasks: notes,
      onTaskTap: _handleTaskTap,
      onTaskCompleted: _handleTaskCompleted,
      showDate: false,
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'בוקר טוב! 🌅';
    } else if (hour < 17) {
      return 'צהריים טובים! ☀️';
    } else if (hour < 21) {
      return 'ערב טוב! 🌆';
    } else {
      return 'לילה טוב! 🌙';
    }
  }
}

class ManualTaskSheet extends StatefulWidget {
  final VoidCallback onTaskCreated;

  const ManualTaskSheet({super.key, required this.onTaskCreated});

  @override
  State<ManualTaskSheet> createState() => _ManualTaskSheetState();
}

class _ManualTaskSheetState extends State<ManualTaskSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TaskType _selectedType = TaskType.task;
  TaskPriority _selectedPriority = TaskPriority.simple;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (time != null && mounted) {
      setState(() => _selectedTime = time);
    }
  }

  DateTime? get _combinedDateTime {
    if (_selectedDate == null) return null;
    if (_selectedTime == null) return _selectedDate;
    
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
  }

  Future<void> _saveTask() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('נא להזין כותרת למשימה')),
      );
      return;
    }

    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      type: _selectedType,
      priority: _selectedPriority,
      dueDate: _combinedDateTime,
      createdAt: DateTime.now(),
    );

    await MockDatabaseService.insertTask(task);
    widget.onTaskCreated();
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_selectedType.hebrewName} נוסף/ה בהצלחה')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header
          Text(
            'הוספת משימה חדשה',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Task type selection
          Text(
            'סוג:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TaskType.values.map((type) {
                final isSelected = type == _selectedType;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilterChip(
                    selected: isSelected,
                    onSelected: (selected) => setState(() => _selectedType = type),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(type.emoji),
                        const SizedBox(width: 4),
                        Text(type.hebrewName),
                      ],
                    ),
                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Title field
          TextField(
            controller: _titleController,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              labelText: 'כותרת *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainer,
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // Description field
          TextField(
            controller: _descriptionController,
            textDirection: TextDirection.rtl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'תיאור (אופציונלי)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainer,
            ),
          ),
          const SizedBox(height: 16),

          // Priority selection
          Text(
            'עדיפות:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TaskPriority.values.map((priority) {
                final isSelected = priority == _selectedPriority;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilterChip(
                    selected: isSelected,
                    onSelected: (selected) => setState(() => _selectedPriority = priority),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(priority.emoji),
                        const SizedBox(width: 4),
                        Text(priority.hebrewName),
                      ],
                    ),
                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Date and time selection
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'בחר תאריך',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectTime,
                  icon: const Icon(Icons.access_time),
                  label: Text(
                    _selectedTime != null
                        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                        : 'בחר שעה',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ביטול'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saveTask,
                  child: const Text('שמור', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TaskDetailSheet extends StatelessWidget {
  final Task task;
  final VoidCallback onUpdate;

  const TaskDetailSheet({
    super.key,
    required this.task,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Task header
          Row(
            children: [
              Text(
                task.type.emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  task.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Task details
          if (task.description.isNotEmpty) ...[
            Text(
              'תיאור:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              task.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],
          
          if (task.voiceNote != null) ...[
            Text(
              'הקלטה מקורית:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                task.voiceNote!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Action buttons
          Row(
            children: [
              if (!task.isCompleted)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      await MockDatabaseService.markTaskCompleted(task.id);
                      onUpdate();
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('סמן כהושלם', style: TextStyle(color: Colors.white)),
                  ),
                ),
              if (!task.isCompleted) const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await MockDatabaseService.deleteTask(task.id);
                    onUpdate();
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                  label: Text('מחק', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}