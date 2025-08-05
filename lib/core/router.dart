import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindflow/screens/auth_wrapper.dart';
import 'package:mindflow/screens/onboarding_screen.dart';
import 'package:mindflow/screens/login_screen.dart';
import 'package:mindflow/screens/registration_screen.dart';
import 'package:mindflow/screens/forgot_password_screen.dart';
import 'package:mindflow/screens/search_screen.dart';
import 'package:mindflow/screens/focus_timer_screen.dart';
import 'package:mindflow/screens/analytics_screen.dart';
import 'package:mindflow/settings_page.dart';
import 'package:mindflow/services/auth_service.dart';
import 'package:mindflow/home_page.dart';
import 'package:mindflow/brain_dump_page.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authState = ref.watch(authStateProvider);
      final isAuthenticated = authState.asData?.value != null;
      
      // If user is not authenticated and trying to access protected routes
      if (!isAuthenticated && state.fullPath?.startsWith('/home') == true) {
        return '/auth';
      }
      
      // If user is authenticated and trying to access auth routes
      if (isAuthenticated && state.fullPath?.startsWith('/auth') == true) {
        return '/home';
      }
      
      return null;
    },
    routes: [
      // Root route - determines initial screen
      GoRoute(
        path: '/',
        builder: (context, state) => const AuthWrapper(),
      ),
      
      // Auth flow routes
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const LoginScreen(),
        routes: [
          GoRoute(
            path: 'register',
            builder: (context, state) => const RegistrationScreen(),
          ),
          GoRoute(
            path: 'forgot-password',
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
        ],
      ),
      
      // Main app routes
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainNavigationWrapper(),
        routes: [
          GoRoute(
            path: 'search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: 'brain-dump',
            builder: (context, state) => const BrainDumpPage(),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: 'focus',
            builder: (context, state) => const FocusTimerScreen(),
          ),
          GoRoute(
            path: 'analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: 'habits',
            builder: (context, state) => const HabitTrackerScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
  );
});

// Auth state provider
final authStateProvider = StreamProvider<firebase_auth.User?>((ref) {
  return AuthService.authStateChanges;
});

// Main navigation wrapper with bottom navigation
class MainNavigationWrapper extends ConsumerStatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  ConsumerState<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends ConsumerState<MainNavigationWrapper> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const HomePage(),
    const SearchScreen(),
    const FocusTimerScreen(),
    const AnalyticsScreen(),
    const SettingsPage(),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'בית',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'חיפוש',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'פוקוס',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'סטטיסטיקות',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'הגדרות',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0 ? const VoiceActionButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

// Voice action button for home screen
class VoiceActionButton extends StatefulWidget {
  const VoiceActionButton({super.key});

  @override
  State<VoiceActionButton> createState() => _VoiceActionButtonState();
}

class _VoiceActionButtonState extends State<VoiceActionButton>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    setState(() => _isListening = !_isListening);
    
    if (_isListening) {
      _animationController.repeat(reverse: true);
      // TODO: Start voice recognition
    } else {
      _animationController.stop();
      _animationController.reset();
      // TODO: Stop voice recognition
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isListening ? _scaleAnimation.value : 1.0,
          child: FloatingActionButton.large(
            onPressed: _toggleListening,
            backgroundColor: _isListening 
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)
              : Theme.of(context).colorScheme.primary,
            child: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              size: 32,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

// Placeholder screens for new features


class HabitTrackerScreen extends StatelessWidget {
  const HabitTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('מעקב הרגלים'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.track_changes, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'מעקב הרגלים בבנייה',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'כאן תוכל לעקוב אחר\nההרגלים הטובים שלך',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// Error screen
class ErrorScreen extends StatelessWidget {
  final Exception? error;
  
  const ErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('שגיאה'),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 100,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 20),
            const Text(
              'משהו השתבש',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              error?.toString() ?? 'שגיאה לא ידועה',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('חזור לעמוד הבית'),
            ),
          ],
        ),
      ),
    );
  }
}

// User model for auth state
class User {
  final String id;
  final String email;
  final String? displayName;
  
  const User({
    required this.id,
    required this.email,
    this.displayName,
  });
}
