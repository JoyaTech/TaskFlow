import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mindflow/task_model.dart';
import 'package:mindflow/services/google_calendar_service.dart';
import 'package:mindflow/services/mock_database_service.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:intl/intl.dart';

class CalendarWidget extends StatefulWidget {
  final Function(Task) onTaskTap;
  final VoidCallback onTasksChanged;

  const CalendarWidget({
    super.key,
    required this.onTaskTap,
    required this.onTasksChanged,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late final ValueNotifier<List<CalendarEvent>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, List<CalendarEvent>> _events = {};
  bool _isLoading = false;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _loadEvents();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    
    try {
      final events = <String, List<CalendarEvent>>{};
      
      // Load local tasks
      final tasks = await MockDatabaseService.getAllTasks();
      for (final task in tasks) {
        if (task.dueDate != null) {
          final dateKey = _getDateKey(task.dueDate!);
          events[dateKey] ??= [];
          events[dateKey]!.add(CalendarEvent.fromTask(task));
        }
      }
      
      // Load Google Calendar events if connected
      if (GoogleCalendarService.isAuthenticated) {
        try {
          final calendarEvents = await GoogleCalendarService.getUpcomingEvents(days: 30);
          for (final event in calendarEvents) {
            if (event.start?.dateTime != null) {
              final dateKey = _getDateKey(event.start!.dateTime!);
              events[dateKey] ??= [];
              events[dateKey]!.add(CalendarEvent.fromGoogleEvent(event));
            } else if (event.start?.date != null) {
              final dateKey = _getDateKey(event.start!.date!);
              events[dateKey] ??= [];
              events[dateKey]!.add(CalendarEvent.fromGoogleEvent(event));
            }
          }
        } catch (e) {
          print('Error loading Google Calendar events: $e');
        }
      }
      
      setState(() {
        _events = events;
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _connectToGoogleCalendar() async {
    setState(() => _isConnecting = true);
    
    try {
      final success = await GoogleCalendarService.signIn();
      
      if (success) {
        _showMessage('✅ התחברת בהצלחה ליומן Google!');
        await _loadEvents(); // Reload with Google Calendar events
      } else {
        _showMessage('❌ החיבור ליומן Google נכשל');
      }
    } catch (e) {
      _showMessage('⚠️ שגיאה בחיבור ליומן Google: ${e.toString()}');
    } finally {
      setState(() => _isConnecting = false);
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

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _events[_getDateKey(day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    if (!GoogleCalendarService.isAuthenticated) {
      return _buildConnectionPrompt();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'היומן שלי',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                IconButton(
                  onPressed: _loadEvents,
                  icon: Icon(
                    Icons.refresh,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  tooltip: 'רענן יומן',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Calendar
            TableCalendar<CalendarEvent>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              eventLoader: _getEventsForDay,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              locale: 'he',
              
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
                holidayTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
              
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                formatButtonTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _selectedEvents.value = _getEventsForDay(selectedDay);
                }
              },
              
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Events for selected day
            ValueListenableBuilder<List<CalendarEvent>>(
              valueListenable: _selectedEvents,
              builder: (context, events, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'אירועים ב-${DateFormat('dd/MM/yyyy', 'he').format(_selectedDay!)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (events.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'אין אירועים ביום זה',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ...events.map((event) => _buildEventCard(event)).toList(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionPrompt() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today,
              size: 48,
color: Theme.of(context).colorScheme.primary.withOpacity(0.7)
            ),
            const SizedBox(height: 16),
            Text(
              'חבר את היומן שלך',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'התחבר ליומן Google כדי לראות את כל האירועים והמשימות שלך במקום אחד',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isConnecting ? null : _connectToGoogleCalendar,
                icon: _isConnecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.account_circle, color: Colors.white),
                label: Text(
                  _isConnecting ? 'מתחבר...' : 'התחבר ליומן Google',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(CalendarEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: event.color,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          event.title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: event.time != null 
            ? Text(
                event.time!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
color: Theme.of(context).colorScheme.outline.withOpacity(0.3)
                ),
              )
            : null,
        trailing: event.isTask 
            ? IconButton(
                icon: const Icon(Icons.open_in_new, size: 16),
                onPressed: () {
                  if (event.task != null) {
                    widget.onTaskTap(event.task!);
                  }
                },
              )
            : null,
        onTap: event.isTask 
            ? () {
                if (event.task != null) {
                  widget.onTaskTap(event.task!);
                }
              }
            : null,
      ),
    );
  }
}

class CalendarEvent {
  final String title;
  final String? time;
  final Color color;
  final bool isTask;
  final Task? task;
  final String? googleEventId;

  CalendarEvent({
    required this.title,
    this.time,
    required this.color,
    this.isTask = false,
    this.task,
    this.googleEventId,
  });

  factory CalendarEvent.fromTask(Task task) {
    return CalendarEvent(
      title: '${task.type.emoji} ${task.title}',
      time: task.dueDate != null 
          ? DateFormat('HH:mm', 'he').format(task.dueDate!)
          : null,
      color: _getTaskColor(task),
      isTask: true,
      task: task,
    );
  }

  factory CalendarEvent.fromGoogleEvent(calendar.Event event) {
    DateTime? eventTime;
    if (event.start?.dateTime != null) {
      eventTime = event.start!.dateTime!;
    } else if (event.start?.date != null) {
      eventTime = event.start!.date!;
    }

    return CalendarEvent(
      title: event.summary ?? 'אירוע ללא כותרת',
      time: eventTime != null && event.start?.dateTime != null
          ? DateFormat('HH:mm', 'he').format(eventTime)
          : null,
      color: Colors.blue,
      isTask: false,
      googleEventId: event.id,
    );
  }

  static Color _getTaskColor(Task task) {
    switch (task.priority) {
      case TaskPriority.important:
        return Colors.red;
      case TaskPriority.simple:
        return Colors.green;
      case TaskPriority.later:
        return Colors.orange;
    }
  }
}
