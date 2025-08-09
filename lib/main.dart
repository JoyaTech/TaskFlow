import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart';
import 'providers/theme_provider.dart';
import 'package:mindflow/services/notification_service.dart';
import 'package:mindflow/services/database_service.dart';
import 'package:mindflow/core/router.dart';
import 'package:mindflow/features/tasks/presentation/pages/task_list_page.dart';
import 'package:mindflow/demo_app.dart';
import 'firebase_options.dart';

// Set to false to use the Clean Architecture version, true for demo
const bool kUseDemo = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kUseDemo) {
    // Run the demo version without Firebase dependencies
    runApp(const ProviderScope(child: DemoApp()));
    return;
  }
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize services
  await _initializeServices();
  
  runApp(const ProviderScope(child: MyApp()));
}

/// Initialize all app services
Future<void> _initializeServices() async {
  try {
    // 🗄️ PRODUCTION FIX: Initialize SQLite database service
    await DatabaseService.initialize();
    
    // Initialize notifications
    await NotificationService.initialize();
    
    print('✅ All services initialized successfully');
  } catch (e) {
    print('❌ Error initializing services: $e');
    rethrow; // Re-throw to prevent app from starting with broken database
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    
    return MaterialApp(
      title: 'MindFlow - עוזר המשימות החכם',
      debugShowCheckedModeBanner: false,
      theme: themeState.lightTheme,
      darkTheme: themeState.darkTheme,
      themeMode: themeState.materialThemeMode,
      home: const TaskListPage(), // Direct to Clean Architecture page
      locale: const Locale('he', 'IL'),
      // Add Hebrew localization support
      supportedLocales: const [
        Locale('he', 'IL'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
