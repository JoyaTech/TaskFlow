import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindflow/screens/login_screen.dart';
import 'package:introduction_screen/introduction_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IntroductionScreen(
        pages: [
          PageViewModel(
            title: "ברוך הבא ל-MindFlow!",
            body: "אפליקציית ניהול המשימות החכמה שלך.",
            image: _buildImage('assets/images/onboarding1.png'),
            decoration: _getPageDecoration(),
          ),
          PageViewModel(
            title: "ניהול משימות חכם",
            body: "צרו משימות, הנה על השלמות, וכל זה בקלות.",
            image: _buildImage('assets/images/onboarding2.png'),
            decoration: _getPageDecoration(),
          ),
          PageViewModel(
            title: "קול ותזכורות חכמות",
            body: "השתמש בזיהוי קולי ותזכורות שיזעיקו אותך בזמן.",
            image: _buildImage('assets/images/onboarding3.png'),
            decoration: _getPageDecoration(),
          ),
        ],
        done: const Text("התחל", style: TextStyle(fontWeight: FontWeight.w600)),
        onDone: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('onboarding_completed', true);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
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

  Widget _buildImage(String path) {
    return Align(
      child: Image.asset(path, width: 350),
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
