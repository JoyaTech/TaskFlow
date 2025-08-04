import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mindflow/theme.dart';
import 'package:mindflow/services/auth_service.dart';
import 'package:mindflow/services/notification_service.dart';
import 'package:mindflow/services/local_database_service.dart';
import 'package:mindflow/screens/auth_wrapper.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize services
  await _initializeServices();
  
  runApp(const MyApp());
}

/// Initialize all app services
Future<void> _initializeServices() async {
  try {
    // Initialize local database
    await LocalDatabaseService.database;
    
    // Initialize notifications
    await NotificationService.initialize();
    
    print('✅ All services initialized successfully');
  } catch (e) {
    print('❌ Error initializing services: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindFlow - עוזר המשימות הישראלי',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
      locale: const Locale('he', 'IL'),
      // Add Hebrew localization support
      supportedLocales: const [
        Locale('he', 'IL'),
        Locale('en', 'US'),
      ],
    );
  }
}
