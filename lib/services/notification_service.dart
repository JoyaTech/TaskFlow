import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mindflow/task_model.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static bool _initialized = false;

  /// Initialize notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jerusalem'));

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Initialize Firebase messaging
    await _initializeFirebaseMessaging();

    _initialized = true;
  }

  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request permissions
    await _requestNotificationPermissions();
  }

  /// Initialize Firebase messaging
  static Future<void> _initializeFirebaseMessaging() async {
    // Request permission for iOS
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      print('Firebase Messaging permission: ${settings.authorizationStatus}');
    }

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Get initial message if app was opened from notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Request notification permissions
  static Future<bool> _requestNotificationPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return true; // iOS permissions are handled by Firebase
  }

  /// Schedule task reminder notification
  static Future<void> scheduleTaskReminder(Task task) async {
    if (task.dueDate == null) return;

    final scheduledDate = tz.TZDateTime.from(task.dueDate!, tz.local);
    final now = tz.TZDateTime.now(tz.local);

    // Don't schedule if due date is in the past
    if (scheduledDate.isBefore(now)) return;

    // Schedule 15 minutes before
    final notificationTime = scheduledDate.subtract(const Duration(minutes: 15));
    if (notificationTime.isAfter(now)) {
      await _localNotifications.zonedSchedule(
        task.id.hashCode,
        '⏰ תזכורת: ${task.title}',
        task.description.isNotEmpty ? task.description : 'משימה חשובה מחכה לך!',
        notificationTime,
        _getNotificationDetails(task),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'task_${task.id}',
      );
    }

    // Schedule at due time if it's today
    if (_isToday(scheduledDate) && scheduledDate.isAfter(now)) {
      await _localNotifications.zonedSchedule(
        task.id.hashCode + 1,
        '🚨 ${task.title}',
        'הגיע הזמן! ${task.description.isNotEmpty ? task.description : ""}',
        scheduledDate,
        _getNotificationDetails(task, urgent: true),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'task_${task.id}',
      );
    }
  }

  /// Cancel task notification
  static Future<void> cancelTaskNotification(String taskId) async {
    await _localNotifications.cancel(taskId.hashCode);
    await _localNotifications.cancel(taskId.hashCode + 1);
  }

  /// Schedule daily summary notification
  static Future<void> scheduleDailySummary() async {
    // Cancel existing daily summary
    await _localNotifications.cancel(999999);

    // Schedule for 8 AM tomorrow
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 8);
    
    // If 8 AM today has passed, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _localNotifications.zonedSchedule(
      999999,
      '🌅 בוקר טוב! יום חדש מתחיל',
      'מוכן להתחיל יום פרודוקטיביי? בוא נראה מה יש לנו היום',
      scheduledDate,
      _getDailySummaryNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'daily_summary',
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );
  }

  /// Show completion celebration notification
  static Future<void> showCompletionCelebration(Task task) async {
    final motivationalMessages = [
      'כל הכבוד! אתה על הדרך הנכונה! 💪',
      'משימה הושלמה! המשך את הרצף הזה! 🔥',
      'גאה בך! עוד צעד קדימה! ✨',
      'יפה! אתה בלתי עצור! 🚀',
      'מושלם! המשך ככה! 🌟',
    ];

    final message = motivationalMessages[DateTime.now().millisecond % motivationalMessages.length];

    await _localNotifications.show(
      DateTime.now().millisecond,
      '🎉 ${task.title} הושלם!',
      message,
      _getCelebrationNotificationDetails(),
      payload: 'celebration_${task.id}',
    );
  }

  /// Show streak milestone notification
  static Future<void> showStreakMilestone(int streak) async {
    String title = '';
    String body = '';

    if (streak == 3) {
      title = '🔥 3 ימים ברצף!';
      body = 'אתה בונה תאוצה נהדרת! המשך ככה!';
    } else if (streak == 7) {
      title = '⭐ שבוע שלם!';
      body = 'מדהים! 7 ימים של פרודוקטיביות!';
    } else if (streak == 30) {
      title = '👑 חודש מושלם!';
      body = 'אתה אלוף! 30 ימים של עקביות!';
    } else if (streak % 10 == 0) {
      title = '🏆 $streak ימים ברצף!';
      body = 'פשוט בלתי ייאמן! אתה מקצוען!';
    }

    if (title.isNotEmpty) {
      await _localNotifications.show(
        DateTime.now().millisecond + 1,
        title,
        body,
        _getCelebrationNotificationDetails(),
        payload: 'streak_$streak',
      );
    }
  }

  /// Get notification details for tasks
  static NotificationDetails _getNotificationDetails(Task task, {bool urgent = false}) {
    final priority = urgent ? Priority.high : Priority.defaultPriority;
    final importance = urgent ? Importance.high : Importance.defaultImportance;

    return NotificationDetails(
      android: AndroidNotificationDetails(
        'task_reminders',
        'תזכורות משימות',
        channelDescription: 'התראות על משימות קרובות',
        priority: priority,
        importance: importance,
        icon: '@mipmap/ic_launcher',
        color: _getTaskColor(task.priority),
        enableVibration: true,
        playSound: true,
        actions: [
          const AndroidNotificationAction(
            'mark_done',
            'סמן כהושלם',
            showsUserInterface: false,
          ),
          const AndroidNotificationAction(
            'snooze',
            'דחה ל-15 דק',
            showsUserInterface: false,
          ),
        ],
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: 'task_reminder',
        threadIdentifier: 'task_${task.id}',
      ),
    );
  }

  /// Get notification details for daily summary
  static NotificationDetails _getDailySummaryNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_summary',
        'סיכום יומי',
        channelDescription: 'סיכום יומי של משימות',
        priority: Priority.defaultPriority,
        importance: Importance.defaultImportance,
        icon: '@mipmap/ic_launcher',
        enableVibration: false,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: 'daily_summary',
      ),
    );
  }

  /// Get notification details for celebrations
  static NotificationDetails _getCelebrationNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'celebrations',
        'חגיגות',
        channelDescription: 'חגיגות השלמת משימות',
        priority: Priority.high,
        importance: Importance.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        enableLights: true,
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: 'celebration',
        presentSound: true,
        presentAlert: true,
      ),
    );
  }

  /// Get task color based on priority
  static Color _getTaskColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.important:
        return const Color(0xFFFF5252);
      case TaskPriority.later:
        return const Color(0xFF9C27B0);
      case TaskPriority.simple:
        return const Color(0xFF2196F3);
    }
  }

  /// Handle notification tap
  static void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      _handlePayload(payload);
    }
  }

  /// Handle Firebase messaging background messages
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    if (kDebugMode) {
      print('Background message: ${message.messageId}');
    }
  }

  /// Handle Firebase messaging foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Foreground message: ${message.notification?.title}');
    }

    // Show local notification for foreground messages
    if (message.notification != null) {
      _localNotifications.show(
        message.hashCode,
        message.notification!.title,
        message.notification!.body,
        _getDefaultNotificationDetails(),
        payload: message.data['payload'],
      );
    }
  }

  /// Handle notification tap from Firebase messaging
  static void _handleNotificationTap(RemoteMessage message) {
    final payload = message.data['payload'];
    if (payload != null) {
      _handlePayload(payload);
    }
  }

  /// Handle notification payload
  static void _handlePayload(String payload) {
    if (kDebugMode) {
      print('Notification payload: $payload');
    }

    // TODO: Navigate to appropriate screen based on payload
    // This will be implemented when we add navigation handling
  }

  /// Get default notification details
  static NotificationDetails _getDefaultNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'general',
        'כללי',
        channelDescription: 'התראות כלליות',
        priority: Priority.defaultPriority,
        importance: Importance.defaultImportance,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  /// Check if date is today
  static bool _isToday(tz.TZDateTime date) {
    final now = tz.TZDateTime.now(tz.local);
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  /// Get FCM token for this device
  static Future<String?> getFCMToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      if (kDebugMode) print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Show permission dialog
  static Future<bool> requestPermissions() async {
    return await _requestNotificationPermissions();
  }

  /// Clear all notifications
  static Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Get pending notifications
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }
}

/// Color extension for notification colors
extension Color on int {
  static const Color red = Color(0xFFFF5252);
  static const Color purple = Color(0xFF9C27B0);
  static const Color blue = Color(0xFF2196F3);
}
