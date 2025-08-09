import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ai_task_providers.dart';

class AISmartInputPage extends ConsumerStatefulWidget {
  const AISmartInputPage({super.key});

  @override
  ConsumerState<AISmartInputPage> createState() => _AISmartInputPageState();
}

class _AISmartInputPageState extends ConsumerState<AISmartInputPage>
    with TickerProviderStateMixin {
  
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  
  late AnimationController _suggestionController;
  late Animation<double> _suggestionAnimation;

  // Example suggestions (in real app, these would come from AI)
  final List<String> _exampleSuggestions = [
    'קח תרופה בשעה 9 בבוקר',
    'פגישה עם דר. כהן ביום שני',
    'קנה חלב וביצים מהסופר',
    'שלח דו"ח עד יום חמישי',
    'התקשר לאמא בערב',
    'תזכורת ליום הולדת של רן',
  ];

  @override
  void initState() {
    super.initState();
    
    _suggestionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _suggestionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _suggestionController,
      curve: Curves.easeOut,
    ));

    _textController.addListener(_onTextChanged);
    
    // Auto-focus and show keyboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onTextChanged() {
    final text = _textController.text;
    ref.read(smartInputProvider.notifier).updateInput(text);
    
    // Debounce AI suggestions
    _debounceTimer?.cancel();
    if (text.length > 3) {
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        _generateSuggestions(text);
      });
    } else {
      ref.read(smartInputProvider.notifier).updateSuggestions([]);
      _suggestionController.reverse();
    }
  }

  void _generateSuggestions(String input) {
    // Simple suggestion logic - in real app, this would use AI
    final suggestions = _exampleSuggestions
        .where((suggestion) => 
            suggestion.toLowerCase().contains(input.toLowerCase()) ||
            input.toLowerCase().contains(suggestion.split(' ').first.toLowerCase())
        )
        .take(3)
        .toList();
    
    ref.read(smartInputProvider.notifier).updateSuggestions(suggestions);
    
    if (suggestions.isNotEmpty) {
      _suggestionController.forward();
    } else {
      _suggestionController.reverse();
    }
  }

  Future<void> _processInput() async {
    final input = _textController.text.trim();
    if (input.isEmpty) return;

    try {
      ref.read(smartInputProvider.notifier).setProcessing(true);
      
      final result = await ref
          .read(aiTaskProcessingProvider.notifier)
          .processTextInput(input);
      
      if (result != null && mounted) {
        _showSuccess(result);
      }
    } catch (e) {
      if (mounted) {
        _showError('שגיאה ביצירת המשימה: $e');
      }
    } finally {
      ref.read(smartInputProvider.notifier).setProcessing(false);
    }
  }

  void _showSuccess(TaskCreationResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            const Text('נוצר בהצלחה!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.wasOptimized)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.withOpacity(0.1), Colors.blue.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.purple, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI אופטימיזציה',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'המשימה הותאמה לצרכים שלך',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            if (result.subTasks.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.list_alt, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'נוצרו ${result.subTasks.length} תת-משימות',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'המשימה פורקה לשלבים קטנים להקלה עליך',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Text(
                  'רמת ביטחון: ${(result.confidence * 100).round()}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _reset();
            },
            child: const Text('צור עוד'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Back to main screen
            },
            child: const Text('סיום'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'נסה שוב',
          textColor: Colors.white,
          onPressed: _processInput,
        ),
      ),
    );
  }

  void _reset() {
    _textController.clear();
    ref.read(smartInputProvider.notifier).reset();
    _suggestionController.reset();
    _focusNode.requestFocus();
  }

  void _selectSuggestion(String suggestion) {
    _textController.text = suggestion;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    ref.read(smartInputProvider.notifier).updateSuggestions([]);
    _suggestionController.reverse();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    _suggestionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final smartInputState = ref.watch(smartInputProvider);
    final isProcessing = ref.watch(aiTaskProcessingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('כתיבה חכמה'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          if (!isProcessing)
            IconButton(
              onPressed: _reset,
              icon: const Icon(Icons.refresh),
              tooltip: 'נקה הכל',
            ),
        ],
      ),
      body: Column(
        children: [
          // Header with instruction
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'תכתוב, האפליקציה תבין',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'כתוב בשפה טבעית מה אתה צריך לעשות. המערכת תיצור משימות מתאימות עם תאריכים, עדיפויות והמלצות אישיות.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Input field
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _focusNode.hasFocus 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: 6,
                      minLines: 3,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _processInput(),
                      decoration: InputDecoration(
                        hintText: 'למשל: "פגישה עם הרופא מחר בשעה 3" או "קנה חלב וביצים עד סוף השבוע"',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          height: 1.4,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Suggestions
                  AnimatedBuilder(
                    animation: _suggestionAnimation,
                    builder: (context, child) {
                      if (smartInputState.suggestions.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Transform.scale(
                        scale: _suggestionAnimation.value,
                        child: Opacity(
                          opacity: _suggestionAnimation.value,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    size: 20,
                                    color: Colors.amber.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'הצעות:',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...smartInputState.suggestions.map(
                                (suggestion) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: InkWell(
                                    onTap: () => _selectSuggestion(suggestion),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                        ),
                                        color: Colors.amber.withOpacity(0.05),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.touch_app,
                                            size: 16,
                                            color: Colors.amber.shade600,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              suggestion,
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const Spacer(),

                  // Create button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_textController.text.trim().isEmpty || isProcessing) 
                          ? null 
                          : _processInput,
                      icon: isProcessing
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(
                        isProcessing ? 'מעבד עם AI...' : 'צור משימות חכמות',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
