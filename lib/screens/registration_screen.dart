import 'package:flutter/material.dart';
import 'package:mindflow/services/auth_service.dart';
import 'package:mindflow/home_page.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('רישום ל-MindFlow'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            
            // Welcome text
            Text(
              'ברוך הבא ל-MindFlow!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'צור חשבון חדש כדי להתחיל לנהל את המשימות שלך',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 48),
            
            // Name field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'שם פרטי',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            
            // Email field
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'כתובת אימייל',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            
            // Password field
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'סיסמה',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: 'לפחות 6 תווים',
              ),
              obscureText: true,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            
            // Confirm password field
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'אישור סיסמה',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _register(),
            ),
            
            const SizedBox(height: 32),
            
            // Register button
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'הרשם',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
            
            const SizedBox(height: 24),
            
            // Back to login
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('כבר יש לך חשבון? '),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('התחבר'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _register() async {
    // Validation
    if (_nameController.text.trim().isEmpty) {
      _showError('נא להזין שם פרטי');
      return;
    }

    if (!AuthService.isValidEmail(_emailController.text.trim())) {
      _showError('נא להזין כתובת אימייל תקינה');
      return;
    }

    if (!AuthService.isValidPassword(_passwordController.text)) {
      _showError('הסיסמה חייבת להכיל לפחות 6 תווים');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('הסיסמאות לא זהות');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await AuthService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );
      
      // Navigate to home page
      if (mounted) context.go('/home');
    } on AuthException catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
