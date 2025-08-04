import 'package:flutter/material.dart';
import 'package:mindflow/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('שכחת סיסמה?'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            
            // Icon
            Icon(
              Icons.lock_reset,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              'איפוס סיסמה',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Description
            Text(
              _emailSent
                  ? 'נשלח לך אימייל עם הוראות לאיפוס הסיסמה. אנא בדוק את תיבת הדואר שלך.'
                  : 'הזן את כתובת האימייל שלך ונשלח לך הוראות לאיפוס הסיסמה.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            if (!_emailSent) ...[
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
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _sendResetEmail(),
              ),
              
              const SizedBox(height: 24),
              
              // Send button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _sendResetEmail,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'שלח אימייל לאיפוס',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
            ] else ...[
              // Success actions
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'חזור למסך התחברות',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: _sendResetEmail,
                child: const Text('לא קיבלת אימייל? שלח שוב'),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Back to login
            if (!_emailSent)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('חזור לכניסה'),
              ),
          ],
        ),
      ),
    );
  }

  void _sendResetEmail() async {
    if (!AuthService.isValidEmail(_emailController.text.trim())) {
      _showError('נא להזין כתובת אימייל תקינה');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await AuthService.sendPasswordResetEmail(_emailController.text.trim());
      
      if (mounted) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      _showError(e.toString());
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
