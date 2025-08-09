import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../providers/demo_ai_providers.dart';
import '../pages/demo_ai_voice_input_page.dart';
import '../pages/demo_ai_smart_input_page.dart';

/// Demo AI-powered FloatingActionButton - The "Magic" Button for MindFlow
class DemoAITaskFab extends ConsumerStatefulWidget {
  const DemoAITaskFab({super.key});

  @override
  ConsumerState<DemoAITaskFab> createState() => _DemoAITaskFabState();
}

class _DemoAITaskFabState extends ConsumerState<DemoAITaskFab>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for the AI magic effect
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Rotate animation for processing state
    _rotateController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_rotateController);

    // Start subtle pulse animation
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing = ref.watch(demoAITaskProcessingProvider);

    // Show rotating animation when processing
    if (isProcessing) {
      _rotateController.repeat();
    } else {
      _rotateController.stop();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _rotateAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Transform.rotate(
            angle: isProcessing ? _rotateAnimation.value * 2 * 3.14159 : 0,
            child: FloatingActionButton.extended(
              onPressed: isProcessing ? null : _showAIMenu,
              icon: Icon(
                isProcessing ? Icons.auto_awesome : Icons.psychology,
                color: Colors.white,
                size: 28,
              ),
              label: Text(
                isProcessing ? 'מעבד...' : 'AI חכם',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: isProcessing 
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
                  : _getAIButtonColor(context),
              elevation: isProcessing ? 2 : 8,
              heroTag: "demo_ai_fab",
            ),
          ),
        );
      },
    );
  }

  Color _getAIButtonColor(BuildContext context) {
    // Gradient-like effect by using a vibrant color
    return const Color(0xFF6B46C1); // Purple color for AI magic
  }

  void _showAIMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DemoAIMenuBottomSheet(),
    );
  }
}

/// Bottom sheet with AI options - Demo Version
class DemoAIMenuBottomSheet extends ConsumerWidget {
  const DemoAIMenuBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Demo badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.science, color: Colors.orange, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'DEMO MODE - No API Required',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'עוזר AI החכם שלך',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Text(
              'בחר איך תרצה ליצור משימות בצורה חכמה (דמו)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),

            // AI Options
            _buildAIOption(
              context: context,
              icon: Icons.mic,
              title: 'הקלטה קולית חכמה',
              subtitle: 'תגיד מה אתה צריך והאפליקציה תבין (סימולציה)',
              color: Colors.red,
              onTap: () => _handleVoiceInput(context, ref),
            ),
            const SizedBox(height: 16),
            
            _buildAIOption(
              context: context,
              icon: Icons.edit_note,
              title: 'כתיבה חכמה',
              subtitle: 'כתוב בשפה טבעית והמערכת תבין (דמו)',
              color: Colors.blue,
              onTap: () => _handleSmartInput(context, ref),
            ),
            const SizedBox(height: 16),
            
            _buildAIOption(
              context: context,
              icon: Icons.email,
              title: 'סריקת אימיילים',
              subtitle: 'המר אימיילים למשימות אוטומטית (סימולציה)',
              color: Colors.green,
              onTap: () => _handleEmailScan(context, ref),
            ),
            const SizedBox(height: 16),
            
            _buildAIOption(
              context: context,
              icon: Icons.psychology_alt,
              title: 'אני מרגיש המום',
              subtitle: 'קבל עזרה להתמודדות עם עומס (דמו)',
              color: Colors.orange,
              onTap: () => _handleOverwhelmedState(context, ref),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAIOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleVoiceInput(BuildContext context, WidgetRef ref) async {
    Navigator.pop(context);

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const DemoAIVoiceInputPage(),
        ),
      );
    }
  }

  void _handleSmartInput(BuildContext context, WidgetRef ref) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DemoAISmartInputPage(),
      ),
    );
  }

  void _handleEmailScan(BuildContext context, WidgetRef ref) {
    Navigator.pop(context);
    // Trigger email scan
    ref.read(demoAITaskProcessingProvider.notifier).scanEmails();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('סורק אימיילים למשימות חדשות... (דמו)'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        action: SnackBarAction(
          label: 'הצג',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to results (would show demo results)
          },
        ),
      ),
    );
  }

  void _handleOverwhelmedState(BuildContext context, WidgetRef ref) {
    Navigator.pop(context);
    
    // Show overwhelmed support dialog
    showDialog(
      context: context,
      builder: (context) => const OverwhelmedSupportDialog(),
    );
  }
}

/// Dialog for helping overwhelmed users - reused from original
class OverwhelmedSupportDialog extends StatelessWidget {
  const OverwhelmedSupportDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.favorite,
            color: Colors.pink,
            size: 24,
          ),
          const SizedBox(width: 8),
          const Text('אתה לא לבד 💜'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'הרגשה של המום היא חלק מהחוויה. בואו ננסה להקל:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          
          _buildSupportOption(
            context: context,
            icon: Icons.spa,
            text: 'נשימה עמוקה - תחזור עוד 5 דקות',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          
          _buildSupportOption(
            context: context,
            icon: Icons.list_alt,
            text: 'צור 3 משימות קטנות במקום גדולה',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          
          _buildSupportOption(
            context: context,
            icon: Icons.schedule,
            text: 'דחה משימות לא דחופות למחר',
            color: Colors.orange,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('תודה'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            // TODO: Implement smart task breakdown demo
          },
          child: const Text('עזור לי לפרק משימות (דמו)'),
        ),
      ],
    );
  }

  Widget _buildSupportOption({
    required BuildContext context,
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
