import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mindflow/brain_dump_model.dart';
import 'package:mindflow/brain_dump_service.dart';
import 'package:mindflow/database_service.dart';
import 'package:mindflow/task_model.dart';
import 'package:uuid/uuid.dart';

class BrainDumpPage extends StatefulWidget {
  const BrainDumpPage({super.key});

  @override
  State<BrainDumpPage> createState() => _BrainDumpPageState();
}

class _BrainDumpPageState extends State<BrainDumpPage>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final _uuid = const Uuid();
  BrainDumpType _selectedType = BrainDumpType.thought;
  bool _isLoading = false;
  late TabController _tabController;
  List<BrainDump> _allBrainDumps = [];
  List<BrainDump> _todayBrainDumps = [];
  List<BrainDump> _unprocessedBrainDumps = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBrainDumps();
  }

  @override
  void dispose() {
    _textController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBrainDumps() async {
    try {
      final allDumps = await BrainDumpService.getAllBrainDumps();
      final todayDumps = await BrainDumpService.getTodayBrainDumps();
      final unprocessedDumps = await BrainDumpService.getUnprocessedBrainDumps();
      
      if (mounted) {
        setState(() {
          _allBrainDumps = allDumps;
          _todayBrainDumps = todayDumps;
          _unprocessedBrainDumps = unprocessedDumps;
        });
      }
    } catch (e) {
      _showMessage('שגיאה בטעינת המחשבות: $e');
    }
  }

  Future<void> _quickSave() async {
    if (_textController.text.trim().isEmpty) {
      return;
    }

    final brainDump = BrainDump(
      id: _uuid.v4(),
      content: _textController.text.trim(),
      createdAt: DateTime.now(),
      type: _selectedType,
    );

    try {
      await BrainDumpService.insertBrainDump(brainDump);
      _textController.clear();
      _loadBrainDumps();
      
      // Show subtle feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text(_selectedType.emoji),
              const SizedBox(width: 8),
              const Text('נשמר!'),
            ],
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      _showMessage('שגיאה בשמירה: $e');
    }
  }

  Future<void> _convertToTask(BrainDump brainDump) async {
    try {
      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: brainDump.content,
        description: 'נוצר ממחשבה מהירה',
        type: _inferTaskType(brainDump.type),
        priority: _inferTaskPriority(brainDump.type),
        createdAt: DateTime.now(),
        voiceNote: 'מחשבה מהירה: ${brainDump.content}',
      );

      await DatabaseService.insertTask(task);
      await BrainDumpService.markAsProcessed(brainDump.id, task.id);
      
      _loadBrainDumps();
      _showMessage('הומר למשימה בהצלחה!');
    } catch (e) {
      _showMessage('שגיאה בהמרה למשימה: $e');
    }
  }

  TaskType _inferTaskType(BrainDumpType brainDumpType) {
    switch (brainDumpType) {
      case BrainDumpType.reminder:
        return TaskType.reminder;
      case BrainDumpType.idea:
      case BrainDumpType.inspiration:
        return TaskType.note;
      default:
        return TaskType.task;
    }
  }

  TaskPriority _inferTaskPriority(BrainDumpType brainDumpType) {
    switch (brainDumpType) {
      case BrainDumpType.worry:
      case BrainDumpType.reminder:
        return TaskPriority.important;
      case BrainDumpType.idea:
      case BrainDumpType.inspiration:
        return TaskPriority.later;
      default:
        return TaskPriority.simple;
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

  void _showBrainDumpDetails(BrainDump brainDump) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BrainDumpDetailSheet(
        brainDump: brainDump,
        onConvertToTask: () => _convertToTask(brainDump),
        onDelete: () async {
          await BrainDumpService.deleteBrainDump(brainDump.id);
          _loadBrainDumps();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // App bar with greeting
          _buildAppBar(),
          
          // Quick capture section
          _buildQuickCaptureSection(),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTodayView(),
                _buildUnprocessedView(),
                _buildAllView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.tertiaryContainer,
            Theme.of(context).colorScheme.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'מחשבות מהירות 🧠',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'שחרר את המחשבות שלך מהראש',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onTertiaryContainer
                                .withValues(alpha: 0.8),
                          ),
                    ),
                  ],
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
                color: Theme.of(context).colorScheme.tertiary,
                borderRadius: BorderRadius.circular(25),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              unselectedLabelStyle: Theme.of(context).textTheme.labelMedium,
              tabs: [
                Tab(text: 'היום (${_todayBrainDumps.length})'),
                Tab(text: 'לטיפול (${_unprocessedBrainDumps.length})'),
                Tab(text: 'הכל (${_allBrainDumps.length})'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCaptureSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '💭',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'מה עובר לך בראש?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Quick input field
          TextField(
            controller: _textController,
            maxLines: null,
            minLines: 2,
            decoration: InputDecoration(
              hintText: 'כתוב כל מה שעובר לך בראש...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.all(16),
            ),
            onSubmitted: (_) => _quickSave(),
          ),
          
          const SizedBox(height: 12),
          
          // Type selection chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: BrainDumpType.values.map((type) {
                final isSelected = type == _selectedType;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ActionChip(
                    onPressed: () => setState(() => _selectedType = type),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(type.emoji),
                        const SizedBox(width: 4),
                        Text(type.hebrewName),
                      ],
                    ),
                    backgroundColor: isSelected
                        ? Theme.of(context).colorScheme.tertiaryContainer
                        : null,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onTertiaryContainer
                          : null,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Quick save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _quickSave,
              icon: const Icon(Icons.flash_on),
              label: const Text('שמור מהר!'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayView() {
    if (_todayBrainDumps.isEmpty) {
      return _buildEmptyState('אין מחשבות מהיום', '🌅');
    }
    
    return _buildBrainDumpList(_todayBrainDumps);
  }

  Widget _buildUnprocessedView() {
    if (_unprocessedBrainDumps.isEmpty) {
      return _buildEmptyState('כל המחשבות טופלו!', '✅');
    }
    
    return _buildBrainDumpList(_unprocessedBrainDumps, showConvertButton: true);
  }

  Widget _buildAllView() {
    if (_allBrainDumps.isEmpty) {
      return _buildEmptyState('אין מחשבות שנשמרו', '💭');
    }
    
    return _buildBrainDumpList(_allBrainDumps);
  }

  Widget _buildEmptyState(String message, String emoji) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrainDumpList(List<BrainDump> brainDumps, {bool showConvertButton = false}) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: brainDumps.length,
      itemBuilder: (context, index) {
        final brainDump = brainDumps[index];
        return BrainDumpCard(
          brainDump: brainDump,
          onTap: () => _showBrainDumpDetails(brainDump),
          showConvertButton: showConvertButton,
          onConvertToTask: () => _convertToTask(brainDump),
        );
      },
    );
  }
}

class BrainDumpCard extends StatelessWidget {
  final BrainDump brainDump;
  final VoidCallback onTap;
  final bool showConvertButton;
  final VoidCallback? onConvertToTask;

  const BrainDumpCard({
    super.key,
    required this.brainDump,
    required this.onTap,
    this.showConvertButton = false,
    this.onConvertToTask,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: brainDump.isProcessed
          ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.5)
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Text(
                    brainDump.type.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      brainDump.type.hebrewName,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  if (brainDump.isProcessed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'טופל',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Content
              Text(
                brainDump.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      decoration: brainDump.isProcessed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Footer
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(brainDump.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                  const Spacer(),
                  if (showConvertButton && !brainDump.isProcessed && onConvertToTask != null)
                    TextButton.icon(
                      onPressed: onConvertToTask,
                      icon: const Icon(Icons.task_alt, size: 16),
                      label: const Text('למשימה'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.tertiary,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'עכשיו';
    } else if (difference.inMinutes < 60) {
      return 'לפני ${difference.inMinutes} דקות';
    } else if (difference.inHours < 24) {
      return 'לפני ${difference.inHours} שעות';
    } else {
      return DateFormat('dd/MM HH:mm', 'he').format(dateTime);
    }
  }
}

class BrainDumpDetailSheet extends StatelessWidget {
  final BrainDump brainDump;
  final VoidCallback onConvertToTask;
  final VoidCallback onDelete;

  const BrainDumpDetailSheet({
    super.key,
    required this.brainDump,
    required this.onConvertToTask,
    required this.onDelete,
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
          
          // Header
          Row(
            children: [
              Text(
                brainDump.type.emoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      brainDump.type.hebrewName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      brainDump.type.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              brainDump.content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Time info
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                'נוצר ${DateFormat('dd/MM/yyyy בשעה HH:mm', 'he').format(brainDump.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            children: [
              if (!brainDump.isProcessed)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      onConvertToTask();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.task_alt, color: Colors.white),
                    label: const Text('המר למשימה', style: TextStyle(color: Colors.white)),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ),
              if (!brainDump.isProcessed) const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    onDelete();
                    Navigator.pop(context);
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
