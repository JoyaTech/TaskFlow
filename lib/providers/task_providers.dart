import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindflow/task_model.dart';
import 'package:mindflow/services/database_service.dart';
import 'package:mindflow/services/cloud_database_service.dart';
import 'package:mindflow/services/auth_service.dart';
import 'package:mindflow/services/notification_service.dart';

// Secure cloud database service provider
final cloudDatabaseServiceProvider = Provider<CloudDatabaseService>((ref) {
  return CloudDatabaseService();
});

// Authentication service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Task repository provider with dependency injection
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(
    ref.watch(cloudDatabaseServiceProvider),
    ref.watch(authServiceProvider),
  );
});

// All tasks provider
final allTasksProvider = StreamProvider<List<Task>>((ref) async* {
  final repository = ref.watch(taskRepositoryProvider);
  yield* repository.watchAllTasks();
});

// Today's tasks provider
final todayTasksProvider = StreamProvider<List<Task>>((ref) async* {
  final repository = ref.watch(taskRepositoryProvider);
  yield* repository.watchTodayTasks();
});

// Completed tasks provider
final completedTasksProvider = StreamProvider<List<Task>>((ref) async* {
  final repository = ref.watch(taskRepositoryProvider);
  yield* repository.watchCompletedTasks();
});

// Notes provider
final notesProvider = StreamProvider<List<Task>>((ref) async* {
  final repository = ref.watch(taskRepositoryProvider);
  yield* repository.watchNotes();
});

// Task statistics provider
final taskStatsProvider = StreamProvider<TaskStatistics>((ref) async* {
  final repository = ref.watch(taskRepositoryProvider);
  yield* repository.watchTaskStatistics();
});

// Focus session provider
final focusSessionProvider = StateNotifierProvider<FocusSessionNotifier, FocusSessionState>((ref) {
  return FocusSessionNotifier();
});

// Habit tracking provider
final habitProvider = StateNotifierProvider<HabitNotifier, HabitState>((ref) {
  return HabitNotifier();
});

// User preferences provider
final userPreferencesProvider = StateNotifierProvider<UserPreferencesNotifier, UserPreferences>((ref) {
  return UserPreferencesNotifier();
});
// Task repository implementation with authentication and security
class TaskRepository {
  TaskRepository(this._cloudDb, this._auth);
  final CloudDatabaseService _cloudDb;
  final AuthService _auth;
  
  /// Ensure user is authenticated before any operation
  void _requireAuth() {
    if (!AuthService.isLoggedIn) {
      throw Exception('משתמש לא מחובר - נדרש לוגין לביצוע פעולות');
    }
  }
  Stream<List<Task>> watchAllTasks() {
    return CloudDatabaseService.watchAllTasks();
  }

  Stream<List<Task>> watchTodayTasks() {
    return CloudDatabaseService.watchTodayTasks();
  }

  Stream<List<Task>> watchCompletedTasks() {
    return CloudDatabaseService.watchAllTasks().map((tasks) => 
        tasks.where((task) => task.isCompleted).toList());
  }

  Stream<List<Task>> watchNotes() {
    return CloudDatabaseService.watchAllTasks().map((tasks) => 
        tasks.where((task) => task.type == TaskType.note).toList());
  }

  Stream<TaskStatistics> watchTaskStatistics() async* {
    // This can be further optimized by listening to a stream of stats from the db
    yield* watchAllTasks().map((tasks) {
      final todayTasks = tasks.where((t) => t.dueDate != null && DateUtils.isSameDay(t.dueDate, DateTime.now())).toList();
      final completedToday = todayTasks.where((t) => t.isCompleted).length;
      return TaskStatistics(
        totalTasks: tasks.length,
        completedTasks: tasks.where((t) => t.isCompleted).length,
        todayTasks: todayTasks.length,
        completedToday: completedToday,
        weeklyStreak: 0, // placeholder
        focusTimeToday: Duration.zero, // placeholder
      );
    });
  }


  Future<void> createTask(Task task) async {
    await CloudDatabaseService.insertTask(task);
    // Schedule notification if task has due date
    if (task.dueDate != null) {
      await NotificationService.scheduleTaskReminder(task);
    }
  }

  Future<void> updateTask(Task task) async {
    await CloudDatabaseService.updateTask(task);
  }

  Future<void> deleteTask(String taskId) async {
    await CloudDatabaseService.deleteTask(taskId);
    await NotificationService.cancelTaskNotification(taskId);
  }

  Future<void> completeTask(String taskId) async {
    final task = await CloudDatabaseService.getTaskById(taskId);
    if (task != null) {
      final updatedTask = task.copyWith(isCompleted: true);
      await CloudDatabaseService.updateTask(updatedTask);
      await NotificationService.showCompletionCelebration(updatedTask);
    }
  }

  Future<List<Task>> searchTasks(String query) async {
    return await CloudDatabaseService.searchTasks(query);
  }
}

// Task statistics model
class TaskStatistics {
  final int totalTasks;
  final int completedTasks;
  final int todayTasks;
  final int completedToday;
  final int weeklyStreak;
  final Duration focusTimeToday;

  const TaskStatistics({
    required this.totalTasks,
    required this.completedTasks,
    required this.todayTasks,
    required this.completedToday,
    required this.weeklyStreak,
    required this.focusTimeToday,
  });

  double get completionRate => totalTasks > 0 ? completedTasks / totalTasks : 0.0;
  double get todayCompletionRate => todayTasks > 0 ? completedToday / todayTasks : 0.0;
}

// Focus session state management
enum FocusSessionStatus { idle, running, paused, breakTime }

class FocusSessionState {
  final FocusSessionStatus status;
  final Duration remainingTime;
  final Duration totalTime;
  final int completedSessions;
  final bool isBreak;

  const FocusSessionState({
    required this.status,
    required this.remainingTime,
    required this.totalTime,
    required this.completedSessions,
    required this.isBreak,
  });

  FocusSessionState copyWith({
    FocusSessionStatus? status,
    Duration? remainingTime,
    Duration? totalTime,
    int? completedSessions,
    bool? isBreak,
  }) {
    return FocusSessionState(
      status: status ?? this.status,
      remainingTime: remainingTime ?? this.remainingTime,
      totalTime: totalTime ?? this.totalTime,
      completedSessions: completedSessions ?? this.completedSessions,
      isBreak: isBreak ?? this.isBreak,
    );
  }
}

class FocusSessionNotifier extends StateNotifier<FocusSessionState> {
  FocusSessionNotifier() : super(const FocusSessionState(
    status: FocusSessionStatus.idle,
    remainingTime: Duration(minutes: 25),
    totalTime: Duration(minutes: 25),
    completedSessions: 0,
    isBreak: false,
  ));

  void startSession({Duration? duration}) {
    final sessionDuration = duration ?? const Duration(minutes: 25);
    state = state.copyWith(
      status: FocusSessionStatus.running,
      remainingTime: sessionDuration,
      totalTime: sessionDuration,
    );
    _startTimer();
  }

  void pauseSession() {
    state = state.copyWith(status: FocusSessionStatus.paused);
  }

  void resumeSession() {
    state = state.copyWith(status: FocusSessionStatus.running);
    _startTimer();
  }

  void stopSession() {
    state = state.copyWith(
      status: FocusSessionStatus.idle,
      remainingTime: const Duration(minutes: 25),
    );
  }

  void startBreak() {
    final breakDuration = state.completedSessions % 4 == 3 
        ? const Duration(minutes: 15) // Long break every 4 sessions
        : const Duration(minutes: 5);  // Short break
    
    state = state.copyWith(
      status: FocusSessionStatus.breakTime,
      remainingTime: breakDuration,
      totalTime: breakDuration,
      isBreak: true,
    );
    _startTimer();
  }

  void _startTimer() async {
    while (state.status == FocusSessionStatus.running || state.status == FocusSessionStatus.breakTime) {
      await Future.delayed(const Duration(seconds: 1));
      
      if (state.remainingTime.inSeconds > 0) {
        state = state.copyWith(
          remainingTime: Duration(seconds: state.remainingTime.inSeconds - 1),
        );
      } else {
        _onSessionComplete();
        break;
      }
    }
  }

  void _onSessionComplete() {
    if (state.isBreak) {
      // Break completed, ready for next session
      state = state.copyWith(
        status: FocusSessionStatus.idle,
        remainingTime: const Duration(minutes: 25),
        isBreak: false,
      );
    } else {
      // Work session completed
      state = state.copyWith(
        status: FocusSessionStatus.idle,
        completedSessions: state.completedSessions + 1,
        isBreak: false,
      );
      // Auto-start break
      startBreak();
    }
  }
}

// Habit tracking
class Habit {
  final String id;
  final String name;
  final String description;
  final List<DateTime> completedDates;
  final int targetFrequency; // times per week
  final DateTime createdAt;

  const Habit({
    required this.id,
    required this.name,
    required this.description,
    required this.completedDates,
    required this.targetFrequency,
    required this.createdAt,
  });

  bool isCompletedToday() {
    final today = DateTime.now();
    return completedDates.any((date) => 
      date.year == today.year &&
      date.month == today.month &&
      date.day == today.day
    );
  }

  int getCurrentStreak() {
    if (completedDates.isEmpty) return 0;
    
    final sortedDates = List<DateTime>.from(completedDates)
      ..sort((a, b) => b.compareTo(a));
    
    int streak = 0;
    DateTime currentDate = DateTime.now();
    
    for (final date in sortedDates) {
      if (_isSameDay(date, currentDate) || 
          _isSameDay(date, currentDate.subtract(const Duration(days: 1)))) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class HabitState {
  final List<Habit> habits;
  final bool isLoading;

  const HabitState({
    required this.habits,
    required this.isLoading,
  });

  HabitState copyWith({
    List<Habit>? habits,
    bool? isLoading,
  }) {
    return HabitState(
      habits: habits ?? this.habits,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class HabitNotifier extends StateNotifier<HabitState> {
  HabitNotifier() : super(const HabitState(habits: [], isLoading: true)) {
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    // TODO: Load habits from database
    await Future.delayed(const Duration(milliseconds: 500));
    state = state.copyWith(
      habits: [
        Habit(
          id: '1',
          name: 'שתיית מים',
          description: '8 כוסות מים ביום',
          completedDates: [DateTime.now().subtract(const Duration(days: 1))],
          targetFrequency: 7,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        Habit(
          id: '2',
          name: 'פעילות גופנית',
          description: '30 דקות פעילות ביום',
          completedDates: [],
          targetFrequency: 5,
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
        ),
      ],
      isLoading: false,
    );
  }

  Future<void> markHabitComplete(String habitId) async {
    final habits = state.habits.map((habit) {
      if (habit.id == habitId && !habit.isCompletedToday()) {
        return Habit(
          id: habit.id,
          name: habit.name,
          description: habit.description,
          completedDates: [...habit.completedDates, DateTime.now()],
          targetFrequency: habit.targetFrequency,
          createdAt: habit.createdAt,
        );
      }
      return habit;
    }).toList();

    state = state.copyWith(habits: habits);
  }

  Future<void> addHabit(Habit habit) async {
    state = state.copyWith(habits: [...state.habits, habit]);
  }
}

// User preferences
class UserPreferences {
  final bool enableNotifications;
  final bool enableVoiceCommands;
  final ThemeMode themeMode;
  final Locale locale;
  final Duration defaultFocusTime;
  final Duration defaultBreakTime;
  final bool enableCelebrations;
  final bool enableStreakTracking;

  const UserPreferences({
    required this.enableNotifications,
    required this.enableVoiceCommands,
    required this.themeMode,
    required this.locale,
    required this.defaultFocusTime,
    required this.defaultBreakTime,
    required this.enableCelebrations,
    required this.enableStreakTracking,
  });

  UserPreferences copyWith({
    bool? enableNotifications,
    bool? enableVoiceCommands,
    ThemeMode? themeMode,
    Locale? locale,
    Duration? defaultFocusTime,
    Duration? defaultBreakTime,
    bool? enableCelebrations,
    bool? enableStreakTracking,
  }) {
    return UserPreferences(
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableVoiceCommands: enableVoiceCommands ?? this.enableVoiceCommands,
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      defaultFocusTime: defaultFocusTime ?? this.defaultFocusTime,
      defaultBreakTime: defaultBreakTime ?? this.defaultBreakTime,
      enableCelebrations: enableCelebrations ?? this.enableCelebrations,
      enableStreakTracking: enableStreakTracking ?? this.enableStreakTracking,
    );
  }
}

class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  UserPreferencesNotifier() : super(const UserPreferences(
    enableNotifications: true,
    enableVoiceCommands: true,
    themeMode: ThemeMode.system,
    locale: Locale('he', 'IL'),
    defaultFocusTime: Duration(minutes: 25),
    defaultBreakTime: Duration(minutes: 5),
    enableCelebrations: true,
    enableStreakTracking: true,
  )) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    // TODO: Load from SharedPreferences
  }

  Future<void> updatePreferences(UserPreferences preferences) async {
    state = preferences;
    // TODO: Save to SharedPreferences
  }

  Future<void> toggleNotifications() async {
    state = state.copyWith(enableNotifications: !state.enableNotifications);
  }

  Future<void> toggleVoiceCommands() async {
    state = state.copyWith(enableVoiceCommands: !state.enableVoiceCommands);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
  }
}
