import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/demo_ai_providers.dart';

class DemoAIVoiceInputPage extends ConsumerStatefulWidget {
  const DemoAIVoiceInputPage({super.key});

  @override
  ConsumerState<DemoAIVoiceInputPage> createState() => _DemoAIVoiceInputPageState();
}

class _DemoAIVoiceInputPageState extends ConsumerState<DemoAIVoiceInputPage> {
  String _simulatedTranscript = '';
  final List<String> _demoTexts = [
    'פגישה עם הרופא מחר בשעה שלוש',
    'קנה חלב וביצים מהסופר',
    'תזכורת להתקשר לאמא בערב',
    'אני מרגיש המום עם כל המשימות',
  ];

  @override
  Widget build(BuildContext context) {
    final isProcessing = ref.watch(demoAITaskProcessingProvider);
    final voiceState = ref.watch(voiceInputProvider);

    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'הקלטה קולית חכמה - דמו',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Demo notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.science, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'דמו - לא מקליט קול אמיתי',
                        style: TextStyle(
                          color: Colors.orange.shade200,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Microphone button
              GestureDetector(
                onTap: _simulateVoiceInput,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: voiceState == VoiceInputState.listening
                          ? [Colors.red.shade400, Colors.red.shade600]
                          : [Colors.grey.shade400, Colors.grey.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (voiceState == VoiceInputState.listening 
                            ? Colors.red : Colors.grey).withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    voiceState == VoiceInputState.listening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Status text
              Text(
                _getStatusText(voiceState, isProcessing),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Simulated transcript
              if (_simulatedTranscript.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _simulatedTranscript,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 40),

              // Process button
              if (_simulatedTranscript.isNotEmpty && voiceState == VoiceInputState.idle)
                ElevatedButton(
                  onPressed: isProcessing ? null : _processTranscript,
                  child: isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('עבד עם AI'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _simulateVoiceInput() {
    if (ref.read(voiceInputProvider) == VoiceInputState.listening) {
      // Stop listening
      ref.read(voiceInputProvider.notifier).finishProcessing();
    } else {
      // Start listening simulation
      ref.read(voiceInputProvider.notifier).startListening();
      
      // Simulate transcript after delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _simulatedTranscript = (_demoTexts..shuffle()).first;
          });
          ref.read(voiceInputProvider.notifier).finishProcessing();
        }
      });
    }
  }

  Future<void> _processTranscript() async {
    final result = await ref
        .read(demoAITaskProcessingProvider.notifier)
        .processVoiceInput(_simulatedTranscript);
    
    if (result != null && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('נוצר מקול!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('שמעתי: "$_simulatedTranscript"'),
              const SizedBox(height: 8),
              Text('נוצרה משימה: ${result.mainTask.title}'),
              if (result.subTasks.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('+ ${result.subTasks.length} תת-משימות'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Back to main
              },
              child: const Text('סגור'),
            ),
          ],
        ),
      );
    }
  }

  String _getStatusText(VoiceInputState state, bool isProcessing) {
    if (isProcessing) return 'מעבד בעזרת AI...';
    
    switch (state) {
      case VoiceInputState.listening:
        return 'מקליט... (סימולציה)';
      case VoiceInputState.processing:
        return 'מעבד...';
      case VoiceInputState.error:
        return 'שגיאה בזיהוי קול';
      case VoiceInputState.idle:
      default:
        return 'לחץ על המיקרופון לדמו';
    }
  }
}
