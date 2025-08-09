import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindflow/services/secure_storage_service.dart';
import '../providers/demo_ai_providers.dart';
import '../providers/ai_task_providers.dart';
import '../pages/demo_ai_voice_input_page.dart';
import '../pages/demo_ai_smart_input_page.dart';
import '../pages/ai_voice_input_page.dart';
import '../pages/ai_smart_input_page.dart';

/// Smart AI-powered FloatingActionButton that automatically switches between demo and real modes
class SmartAITaskFab extends ConsumerStatefulWidget {
  const SmartAITaskFab({super.key});

  @override
  ConsumerState<SmartAITaskFab> createState() => _SmartAITaskFabState();
}

class _SmartAITaskFabState extends ConsumerState<SmartAITaskFab>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  bool _hasApiKey = false;
  bool _isCheckingApiKey = true;

  @override
  void initState() {
    super.initState();
    
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

    _rotateController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_rotateController);

    _pulseController.repeat(reverse: true);
    _checkApiKey();
  }

  Future<void> _checkApiKey() async {
    try {
      final secureStorage = SecureStorageService();
      final openaiKey = await secureStorage.getOpenAIApiKeyInstance();
      final geminiKey = await secureStorage.getGeminiApiKeyInstance();
      
      setState(() {
        _hasApiKey = (openaiKey != null && openaiKey.isNotEmpty) || 
                    (geminiKey != null && geminiKey.isNotEmpty);
        _isCheckingApiKey = false;
      });
    } catch (e) {
      setState(() {
        _hasApiKey = false;
        _isCheckingApiKey = false;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingApiKey) {
      return FloatingActionButton.extended(
        onPressed: null,
        icon: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: const Text('בודק...'),
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
      );
    }

    final isProcessing = _hasApiKey 
        ? false // TODO: Watch real processing state
        : ref.watch(demoAITaskProcessingProvider);

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
                isProcessing 
                    ? 'מעבד...' 
                    : _hasApiKey 
                        ? 'AI חכם' 
                        : 'AI דמו',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: isProcessing 
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
                  : _getAIButtonColor(),
              elevation: isProcessing ? 2 : 8,
              heroTag: "smart_ai_fab",
            ),
          ),
        );
      },
    );
  }

  Color _getAIButtonColor() {
    if (_hasApiKey) {
      return const Color(0xFF6B46C1); // Purple for real AI
    } else {
      return const Color(0xFFFF8C00); // Orange for demo mode
    }
  }

  void _showAIMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SmartAIMenuBottomSheet(
        hasApiKey: _hasApiKey,
        onApiKeyNeeded: () {
          Navigator.pop(context);
          _navigateToSettings();
        },
        onRefreshApiKey: () async {
          await _checkApiKey();
          Navigator.pop(context);
          _showAIMenu(); // Reopen with updated status
        },
      ),
    );
  }

  void _navigateToSettings() {
    // Navigate to settings page - you can implement this
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('נווט להגדרות כדי להוסיף API key'),
        action: SnackBarAction(
          label: 'הגדרות',
          onPressed: () {
            // TODO: Navigate to settings page
          },
        ),
      ),
    );
  }
}

class SmartAIMenuBottomSheet extends ConsumerWidget {
  final bool hasApiKey;
  final VoidCallback onApiKeyNeeded;
  final VoidCallback onRefreshApiKey;

  const SmartAIMenuBottomSheet({
    super.key,
    required this.hasApiKey,
    required this.onApiKeyNeeded,
    required this.onRefreshApiKey,
  });

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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Mode indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (hasApiKey ? Colors.green : Colors.orange).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (hasApiKey ? Colors.green : Colors.orange).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasApiKey ? Icons.api : Icons.science,
                    color: hasApiKey ? Colors.green : Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasApiKey ? 'REAL AI MODE - API Connected' : 'DEMO MODE - No API Required',
                    style: TextStyle(
                      color: (hasApiKey ? Colors.green : Colors.orange).shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            if (!hasApiKey) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: onApiKeyNeeded,
                    icon: Icon(Icons.key, size: 16),
                    label: const Text('הוסף API Key'),
                  ),
                  TextButton.icon(
                    onPressed: onRefreshApiKey,
                    icon: Icon(Icons.refresh, size: 16),
                    label: const Text('רענן'),
                  ),
                ],
              ),
            ],
            
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
              hasApiKey 
                  ? 'בחר איך תרצה ליצור משימות עם AI אמיתי'
                  : 'בחר איך תרצה ליצור משימות (דמו)',
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
              subtitle: hasApiKey 
                  ? 'תגיד מה אתה צריך והאפליקציה תבין'
                  : 'תגיד מה אתה צריך והאפליקציה תבין (סימולציה)',
              color: Colors.red,
              onTap: () => _handleVoiceInput(context, ref),
            ),
            const SizedBox(height: 16),
            
            _buildAIOption(
              context: context,
              icon: Icons.edit_note,
              title: 'כתיבה חכמה',
              subtitle: hasApiKey 
                  ? 'כתוב בשפה טבעית והמערכת תבין'
                  : 'כתוב בשפה טבעית והמערכת תבין (דמו)',
              color: Colors.blue,
              onTap: () => _handleSmartInput(context, ref),
            ),
            const SizedBox(height: 16),
            
            _buildAIOption(
              context: context,
              icon: Icons.email,
              title: 'סריקת אימיילים',
              subtitle: hasApiKey 
                  ? 'המר אימיילים למשימות אוטומטית'
                  : 'המר אימיילים למשימות אוטומטית (סימולציה)',
              color: Colors.green,
              onTap: () => _handleEmailScan(context, ref),
            ),
            const SizedBox(height: 16),
            
            _buildAIOption(
              context: context,
              icon: Icons.psychology_alt,
              title: 'אני מרגיש המום',
              subtitle: hasApiKey 
                  ? 'קבל עזרה להתמודדות עם עומס'
                  : 'קבל עזרה להתמודדות עם עומס (דמו)',
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
              child: Icon(icon, color: color, size: 24),
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

  void _handleVoiceInput(BuildContext context, WidgetRef ref) {
    Navigator.pop(context);
    
    if (hasApiKey) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AIVoiceInputPage(),
        ),
      );
    } else {
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
    
    if (hasApiKey) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AISmartInputPage(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const DemoAISmartInputPage(),
        ),
      );
    }
  }

  void _handleEmailScan(BuildContext context, WidgetRef ref) {
    Navigator.pop(context);
    
    if (hasApiKey) {
      // TODO: Trigger real email scan
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('סורק אימיילים עם AI אמיתי...'),
        ),
      );
    } else {
      ref.read(demoAITaskProcessingProvider.notifier).scanEmails();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('סורק אימיילים למשימות חדשות... (דמו)'),
        ),
      );
    }
  }

  void _handleOverwhelmedState(BuildContext context, WidgetRef ref) {
    Navigator.pop(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.favorite, color: Colors.pink, size: 24),
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
              if (hasApiKey) {
                // TODO: Create real optimized tasks for overwhelmed state
              } else {
                ref.read(demoAITaskProcessingProvider.notifier)
                    .handleOverwhelmedState();
              }
            },
            child: Text('עזור לי לפרק משימות${hasApiKey ? '' : ' (דמו)'}'),
          ),
        ],
      ),
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
