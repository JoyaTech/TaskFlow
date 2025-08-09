import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:path_provider/path_provider.dart';
import '../providers/ai_task_providers.dart';
import '../widgets/voice_visualizer.dart';

class AIVoiceInputPage extends ConsumerStatefulWidget {
  const AIVoiceInputPage({super.key});

  @override
  ConsumerState<AIVoiceInputPage> createState() => _AIVoiceInputPageState();
}

class _AIVoiceInputPageState extends ConsumerState<AIVoiceInputPage>
    with TickerProviderStateMixin {
  late stt.SpeechToText _speech;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  String _currentText = '';
  bool _isInitialized = false;
  Timer? _silenceTimer;
  
  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _initializeSpeech() async {
    _speech = stt.SpeechToText();
    bool available = await _speech.initialize(
      onError: (error) {
        print('Speech recognition error: $error');
        ref.read(voiceInputProvider.notifier).setError(error.errorMsg);
      },
      onStatus: (status) {
        print('Speech recognition status: $status');
        if (status == 'done') {
          _stopListening();
        }
      },
    );
    
    setState(() {
      _isInitialized = available;
    });
    
    if (available) {
      _startListening();
    }
  }

  void _startListening() async {
    if (!_isInitialized) return;
    
    ref.read(voiceInputProvider.notifier).startListening();
    _pulseController.repeat(reverse: true);
    _waveController.repeat();
    
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _currentText = result.recognizedWords;
        });
        
        // Reset silence timer
        _silenceTimer?.cancel();
        _silenceTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) {
            _stopListening();
          }
        });
      },
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'he_IL', // Hebrew locale
      cancelOnError: true,
      listenMode: stt.ListenMode.search,
    );
  }

  void _stopListening() async {
    await _speech.stop();
    _silenceTimer?.cancel();
    _pulseController.stop();
    _waveController.stop();
    
    if (_currentText.isNotEmpty) {
      ref.read(voiceInputProvider.notifier).stopListening();
      await _processVoiceInput();
    } else {
      ref.read(voiceInputProvider.notifier).finishProcessing();
    }
  }

  Future<void> _processVoiceInput() async {
    try {
      // For demo purposes, we'll process the text directly
      // In a real implementation, you'd save the audio file and use it
      final result = await ref
          .read(aiTaskProcessingProvider.notifier)
          .processTextInput(_currentText);
      
      if (result != null && mounted) {
        _showTaskCreationResult(result);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('שגיאה בעיבוד הקול: $e');
      }
    } finally {
      ref.read(voiceInputProvider.notifier).finishProcessing();
    }
  }

  void _showTaskCreationResult(TaskCreationResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: Colors.green,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('משימה נוצרה בהצלחה!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.wasOptimized)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'המשימה אופטמה במיוחד עבורך',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            
            Text(
              'רמת ביטחון: ${(result.confidence * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _getConfidenceColor(result.confidence),
              ),
            ),
            
            if (result.recommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'המלצות:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...result.recommendations.map((recommendation) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: Colors.grey.shade600)),
                      Expanded(
                        child: Text(
                          recommendation,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to main screen
            },
            child: const Text('סגור'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startListening(); // Record another task
            },
            child: const Text('הקלט עוד'),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            const Text('שגיאה'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('אישור'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startListening();
            },
            child: const Text('נסה שוב'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _silenceTimer?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceInputProvider);
    final isProcessing = ref.watch(aiTaskProcessingProvider);

    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'הקלטה קולית חכמה',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Voice visualizer
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: VoiceVisualizer(
                    isListening: voiceState == VoiceInputState.listening,
                    isProcessing: isProcessing,
                    waveController: _waveController,
                  ),
                );
              },
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
            
            // Current text
            if (_currentText.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  _currentText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            
            const SizedBox(height: 40),
            
            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (voiceState == VoiceInputState.listening) ...[
                  FloatingActionButton(
                    onPressed: _stopListening,
                    backgroundColor: Colors.red,
                    heroTag: "stop",
                    child: const Icon(Icons.stop, color: Colors.white),
                  ),
                ] else if (!isProcessing) ...[
                  FloatingActionButton(
                    onPressed: _startListening,
                    backgroundColor: Colors.green,
                    heroTag: "start",
                    child: const Icon(Icons.mic, color: Colors.white),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Helper text
            Text(
              _getHelperText(voiceState, isProcessing),
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(VoiceInputState state, bool isProcessing) {
    if (isProcessing) return 'מעבד בעזרת AI...';
    
    switch (state) {
      case VoiceInputState.listening:
        return 'מקשיב...';
      case VoiceInputState.processing:
        return 'מעבד...';
      case VoiceInputState.error:
        return 'שגיאה בזיהוי קול';
      case VoiceInputState.idle:
      default:
        return 'מוכן להקלטה';
    }
  }

  String _getHelperText(VoiceInputState state, bool isProcessing) {
    if (isProcessing) return 'בודק מה אתה צריך ויוצר משימות מתאימות';
    
    switch (state) {
      case VoiceInputState.listening:
        return 'תגיד מה אתה צריך לעשות...';
      case VoiceInputState.processing:
        return 'מפרש את מה ששמעתי...';
      case VoiceInputState.error:
        return 'לחץ על המיקרופון כדי לנסות שוב';
      case VoiceInputState.idle:
      default:
        return 'לחץ על המיקרופון כדי להתחיל';
    }
  }
}
