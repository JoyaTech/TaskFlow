import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindflow/theme.dart';
import 'package:mindflow/services/notification_service.dart';
import 'package:mindflow/services/mock_database_service.dart';
import 'package:mindflow/core/router.dart';
import 'package:mindflow/demo_app.dart';
import 'firebase_options.dart';

// Set to true to run the demo version
const bool kUseDemo = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kUseDemo) {
    // Run the demo version without Firebase dependencies
    runApp(const DemoApp());
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
    // Initialize mock database
    await MockDatabaseService.initialize();
    
    // Initialize notifications
    await NotificationService.initialize();
    
    print('✅ All services initialized successfully');
  } catch (e) {
    print('❌ Error initializing services: $e');
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'TaskFlow - עוזר המשימות החכם',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
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
