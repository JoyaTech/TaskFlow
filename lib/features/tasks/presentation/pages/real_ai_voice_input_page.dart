import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../providers/real_ai_providers.dart';
import '../widgets/voice_visualizer_widget.dart';

/// Real AI Voice Input Page - Uses actual voice recognition and AI processing
class RealAIVoiceInputPage extends ConsumerStatefulWidget {
  const RealAIVoiceInputPage({super.key});

  @override
  ConsumerState<RealAIVoiceInputPage> createState() => _RealAIVoiceInputPageState();
}

class _RealAIVoiceInputPageState extends ConsumerState<RealAIVoiceInputPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  late stt.SpeechToText _speechToText;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _transcribedText = '';
  String _lastWords = '';
  double _confidenceLevel = 0;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _initSpeech() async {
    _speechToText = stt.SpeechToText();
    _speechEnabled = await _speechToText.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (error) => print('Speech error: $error'),
    );
    setState(() {});
  }

  @override
  void dispose() {
    _animationController.dispose();
    _speechToText.cancel();
    super.dispose();
  }

  void _startListening() async {
    if (!_speechEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('זיהוי קול לא זמין במכשיר זה'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _transcribedText = result.recognizedWords;
          _lastWords = result.recognizedWords;
          _confidenceLevel = result.confidence;
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: "he_IL", // Hebrew locale
      cancelOnError: true,
      listenMode: stt.ListenMode.confirmation,
    );
    
    setState(() {
      _isListening = true;
    });
    _animationController.repeat(reverse: true);
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
    _animationController.stop();
    _animationController.reset();
  }

  void _processWithAI() {
    if (_transcribedText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('אנא הקלט משהו תחילה'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ref.read(realAITaskProcessingProvider.notifier)
        .processVoiceInput(_transcribedText);
  }

  void _clearText() {
    setState(() {
      _transcribedText = '';
      _lastWords = '';
      _confidenceLevel = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(realAITaskProcessingProvider);
    
    // Listen to AI processing results
    ref.listen<AIProcessingState>(realAITaskProcessingProvider, (previous, next) {
      if (next.generatedTasks.isNotEmpty && previous?.generatedTasks.isEmpty == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('נוצרו ${next.generatedTasks.length} משימות חדשות!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'צפה',
              onPressed: () => Navigator.pop(context),
            ),
          ),
        );
      }
      
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה: ${next.error}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'הגדרות',
              onPressed: () {
                // Navigate to settings
              },
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('הקלטה קולית חכמה'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          if (_transcribedText.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearText,
              tooltip: 'נקה טקסט',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getStatusColor().withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(),
                    color: _getStatusColor(),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusText(),
                    style: TextStyle(
                      color: _getStatusColor().shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Voice visualizer and microphone button
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Voice visualizer
                  if (_isListening) ...[
                    VoiceVisualizerWidget(
                      isListening: _isListening,
                      amplitude: _confidenceLevel,
                    ),
                    const SizedBox(height: 32),
                  ],
                  
                  // Microphone button
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isListening ? _scaleAnimation.value : 1.0,
                        child: GestureDetector(
                          onTap: _isListening ? _stopListening : _startListening,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: _isListening 
                                  ? Colors.red.withOpacity(0.8)
                                  : Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isListening ? Colors.red : Theme.of(context).colorScheme.primary)
                                      .withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: _isListening ? 10 : 0,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Text(
                    _isListening 
                        ? 'מאזין... תגיד מה אתה צריך'
                        : _speechEnabled
                            ? 'לחץ כדי להתחיל הקלטה'
                            : 'זיהוי קול לא זמין',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Transcribed text display
            if (_transcribedText.isNotEmpty) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.transcript,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'טקסט שזוהה:',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_confidenceLevel > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getConfidenceColor().withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${(_confidenceLevel * 100).round()}%',
                              style: TextStyle(
                                color: _getConfidenceColor(),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _transcribedText,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              
              // Process button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: aiState.isProcessing ? null : _processWithAI,
                  icon: aiState.isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    aiState.isProcessing 
                        ? 'AI מעבד...' 
                        : 'צור משימות עם AI',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            
            // Generated tasks preview
            if (aiState.generatedTasks.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'נוצרו ${aiState.generatedTasks.length} משימות:',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...aiState.generatedTasks.take(3).map((task) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• ${task.title}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade700,
                        ),
                      ),
                    )),
                    if (aiState.generatedTasks.length > 3)
                      Text(
                        'ועוד ${aiState.generatedTasks.length - 3}...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (!_speechEnabled) return Colors.grey;
    if (_isListening) return Colors.red;
    return Theme.of(context).colorScheme.primary;
  }

  IconData _getStatusIcon() {
    if (!_speechEnabled) return Icons.mic_off;
    if (_isListening) return Icons.mic;
    return Icons.mic_none;
  }

  String _getStatusText() {
    if (!_speechEnabled) return 'זיהוי קול לא זמין';
    if (_isListening) return 'מאזין לקול...';
    return 'מוכן להקלטה';
  }

  Color _getConfidenceColor() {
    if (_confidenceLevel >= 0.7) return Colors.green;
    if (_confidenceLevel >= 0.4) return Colors.orange;
    return Colors.red;
  }
}
