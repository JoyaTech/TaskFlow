import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:introduction_screen/introduction_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IntroductionScreen(
        pages: [
          PageViewModel(
            title: "ברוך הבא ל-FocusFlow!",
            body: "אפליקציית ניהול המשימות החכמה שלך.",
            image: _buildWelcomeImage(),
            decoration: _getPageDecoration(),
          ),
          PageViewModel(
            title: "ניהול משימות חכם",
            body: "צרו משימות, הנה על השלמות, וכל זה בקלות.",
            image: _buildIcon(Icons.task_alt, Colors.green),
            decoration: _getPageDecoration(),
          ),
          PageViewModel(
            title: "קול ותזכורות חכמות",
            body: "השתמש בזיהוי קולי ותזכורות שיזעיקו אותך בזמן.",
            image: _buildIcon(Icons.record_voice_over, Colors.orange),
            decoration: _getPageDecoration(),
          ),
        ],
        done: const Text("התחל", style: TextStyle(fontWeight: FontWeight.w600)),
        onDone: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('onboarding_completed', true);
          if (context.mounted) {
            context.go('/auth');
          }
        },
        next: const Icon(Icons.arrow_forward),
        showSkipButton: true,
        skip: const Text('דלג'),
        dotsDecorator: const DotsDecorator(
          size: Size(10.0, 10.0),
          color: Color(0xFFBDBDBD),
          activeSize: Size(22.0, 10.0),
          activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(25.0)),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeImage() {
    return Align(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          'assets/images/welcome.jpeg',
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildIcon(Icons.psychology, Colors.blue);
          },
        ),
      ),
    );
  }

  Widget _buildIcon(IconData icon, Color color) {
    return Align(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 60,
          color: color,
        ),
      ),
    );
  }

  PageDecoration _getPageDecoration() {
    return const PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
      bodyTextStyle: TextStyle(fontSize: 20.0),
      imagePadding: EdgeInsets.all(24),
    );
  }
}
