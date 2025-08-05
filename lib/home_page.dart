import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindflow/task_model.dart';
import 'package:mindflow/providers/task_providers.dart';
import 'package:mindflow/voice_service.dart';
import 'package:mindflow/task_list_widget.dart';
import 'package:mindflow/brain_dump_page.dart';
import 'package:mindflow/settings_page.dart';
import 'package:mindflow/services/database_service.dart';
import 'package:mindflow/services/google_calendar_service.dart';
import 'package:mindflow/widgets/calendar_widget.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _isListening = false;
  late TabController _tabController;
  late AnimationController _voiceAnimationController;
  late Animation<double> _voiceAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 5, vsync: this);
    
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
    await GoogleCalendarService.initialize();
  }


  Future<void> _startVoiceCapture() async {
    if (!VoiceService.isAvailable) {
      _showMessage('🎤 קלט קולי לא זמין במכשיר זה');
      return;
    }

    setState(() => _isListening = true);
    _voiceAnimationController.repeat(reverse: true);
    _showMessage('🎤 מאזין... דבר עכשיו!', backgroundColor: Colors.blue);

    try {
      final recognizedText = await VoiceService.startListening();
      
      if (recognizedText != null && recognizedText.isNotEmpty) {
        _showMessage('🧠 מעבד את הטקסט: "$recognizedText"...', backgroundColor: Colors.orange);
        
        final parseResult = await VoiceService.parseHebrewCommand(recognizedText);
        
        if (parseResult != null) {
          final newTask = parseResult.toTask();
          await ref.read(taskRepositoryProvider).createTask(newTask);
          
          // Auto-sync to Google Calendar if connected and it's an event or important task
          bool calendarSynced = false;
          if (GoogleCalendarService.isAuthenticated && 
              (newTask.type == TaskType.event || newTask.priority == TaskPriority.important)) {
            try {
              calendarSynced = await GoogleCalendarService.createEventFromTask(newTask);
            } catch (e) {
              print('Calendar sync failed: $e');
            }
          }
          
          _showVoiceSuccess(newTask, recognizedText, calendarSynced: calendarSynced);
        } else {
          _showMessage('❌ לא הצלחתי להבין את הפקודה. נסה שוב.', backgroundColor: Colors.red);
        }
      } else {
        _showMessage('🔇 לא נקלט קול. נסה שוב ודבר בבירור.', backgroundColor: Colors.orange);
      }
    } catch (e) {
      print('Voice capture error: $e');
      _showMessage('⚠️ שגיאה בקלט קולי. בדוק הרשאות מיקרופון.', backgroundColor: Colors.red);
    } finally {
      setState(() => _isListening = false);
      _voiceAnimationController.stop();
      _voiceAnimationController.reset();
    }
  }

  void _showMessage(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 16)),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showVoiceSuccess(Task newTask, String originalText, {bool calendarSynced = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(newTask.type.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                const Text('✅ משימה נוצרה בהצלחה!', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text('📝 ${newTask.title}', style: const TextStyle(fontSize: 14)),
            if (newTask.dueDate != null) 
              Text('📅 ${_formatDateTime(newTask.dueDate!)}', 
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
            if (calendarSynced)
              const Text('📅 נוסף ליומן Google', 
                  style: TextStyle(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 4),
            Text('🎤 "$originalText"', 
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.white60)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'צפה',
          textColor: Colors.white,
          onPressed: () => _handleTaskTap(newTask),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    String dateStr;
    if (taskDate == today) {
      dateStr = 'היום';
    } else if (taskDate == tomorrow) {
      dateStr = 'מחר';
    } else {
      dateStr = '${taskDate.day}/${taskDate.month}';
    }
    
    return '$dateStr בשעה ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _handleTaskTap(Task task) {
    // Show task details dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskDetailSheet(task: task, onUpdate: () => ref.refresh(allTasksProvider)),
    );
  }

  void _handleTaskCompleted(Task task) {
    ref.read(taskRepositoryProvider).completeTask(task.id);
  }

  void _showManualTaskDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ManualTaskSheet(onTaskCreated: () => ref.refresh(allTasksProvider)),
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
                _buildCalendarView(),
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
              // App logo
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/Icon.jpg',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.psychology,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'FocusFlow',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getGreeting(),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
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
                Tab(text: 'יומן'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final allTasks = ref.watch(allTasksProvider);
    final todayTasks = ref.watch(todayTasksProvider);
    
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
                  value: todayTasks.when(
                    data: (data) {
                      final total = data.length;
                      final completed = data.where((t) => t.isCompleted).length;
                      return total > 0 ? completed / total : 0.0;
                    },
                    loading: () => 0.0,
                    error: (_, __) => 0.0,
                  ),
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
                todayTasks.when(
                  data: (data) => Text(
                    '${data.where((t) => t.isCompleted).length} מתוך ${data.length} משימות הושלמו',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                  ),
                  loading: () => const Text('טוען נתונים...'),
                  error: (err, stack) => Text('שגיאה: $err'),
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
    final todayTasks = ref.watch(todayTasksProvider);
    
    return todayTasks.when(
      data: (tasks) => TaskListWidget(
        tasks: tasks,
        onTaskTap: _handleTaskTap,
        onTaskCompleted: _handleTaskCompleted,
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('שגיאה: $err')),
    );
  }

  Widget _buildAllTasksView() {
    final allTasks = ref.watch(allTasksProvider);
    
    return allTasks.when(
      data: (tasks) {
        final activeTasks = tasks.where((task) => !task.isCompleted).toList();
        return TaskListWidget(
          tasks: activeTasks,
          onTaskTap: _handleTaskTap,
          onTaskCompleted: _handleTaskCompleted,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('שגיאה: $err')),
    );
  }

  Widget _buildCompletedView() {
    final completedTasks = ref.watch(completedTasksProvider);
    
    return completedTasks.when(
      data: (tasks) => TaskListWidget(
        tasks: tasks,
        onTaskTap: _handleTaskTap,
        onTaskCompleted: _handleTaskCompleted,
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('שגיאה: $err')),
    );
  }

  Widget _buildNotesView() {
    final notes = ref.watch(notesProvider);
    
    return notes.when(
      data: (tasks) => TaskListWidget(
        tasks: tasks,
        onTaskTap: _handleTaskTap,
        onTaskCompleted: _handleTaskCompleted,
        showDate: false,
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('שגיאה: $err')),
    );
  }

  Widget _buildCalendarView() {
    return GoogleCalendarService.isAuthenticated
        ? CalendarWidget(
            onTaskTap: _handleTaskTap,
            onTaskCompleted: _handleTaskCompleted,
            onRefresh: () => ref.refresh(allTasksProvider),
          )
        : Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'יומן Google לא מחובר',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'חבר את יומן Google שלך כדי לראות ולסנכרן את האירועים והמשימות החשובות',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () async {
                      // Navigate to settings page to connect Google Calendar
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsPage()),
                      );
                      // Refresh the view if calendar was connected
                      if (result == true && mounted) {
                        setState(() {});
                      }
                    },
                    icon: const Icon(Icons.link, color: Colors.white),
                    label: const Text('חבר יומן Google', style: TextStyle(color: Colors.white)),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
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

    await DatabaseService.insertTask(task);
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
                      await DatabaseService.markTaskCompleted(task.id);
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
                    await DatabaseService.deleteTask(task.id);
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