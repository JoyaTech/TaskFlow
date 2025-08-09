import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Zero-friction brain dump page for ADHD users
/// Designed to capture fleeting thoughts with minimal barriers
class BrainDumpPage extends ConsumerStatefulWidget {
  const BrainDumpPage({super.key});

  @override
  ConsumerState<BrainDumpPage> createState() => _BrainDumpPageState();
}

class _BrainDumpPageState extends ConsumerState<BrainDumpPage> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasContent = false;
  bool _isSaving = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    // Auto-focus for zero friction
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasContent = _textController.text.trim().isNotEmpty;
    });
  }

  Future<void> _saveBrainDump() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // TODO: Connect to brain dump provider when we create it
      // For now, simulate saving
      await Future.delayed(const Duration(milliseconds: 800));
      
      setState(() {
        _isSaving = false;
        _isSaved = true;
      });

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(width: 12),
                const Text('המחשבות נשמרו בהצלחה! 🧠✨'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // Auto-dismiss after success
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בשמירה: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.psychology, size: 24),
            const SizedBox(width: 8),
            const Text('זרם המחשבות'),
            if (_isSaved) ...[
              const SizedBox(width: 12),
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ).animate().scale(delay: 200.ms),
            ],
          ],
        ),
        actions: [
          // Word counter
          if (_hasContent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_getWordCount()} מילים',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ).animate(target: _hasContent ? 1 : 0).slideX().fade(),

          // Save button
          if (_hasContent && !_isSaved)
            IconButton.filled(
              onPressed: _isSaving ? null : _saveBrainDump,
              icon: _isSaving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.save),
              tooltip: 'שמור מחשבות',
            ).animate(target: _hasContent ? 1 : 0).slideX().fade(),
        ],
      ),
      body: Column(
        children: [
          // Helpful prompt for ADHD users
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'זה המקום שלך לשפוך את כל המחשבות',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• כתוב כל מה שעולה לך בראש\n• אל תדאג לסדר או לדקדוק\n• אחר כך נוכל להפוך את זה למשימות',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ).animate().slideY(begin: -0.3).fadeIn(),

          // Main text input
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _focusNode.hasFocus
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                  width: _focusNode.hasFocus ? 2 : 1,
                ),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                ),
                decoration: const InputDecoration(
                  hintText: 'התחל לכתוב את המחשבות שלך כאן...\n\nדוגמאות:\n- לקנות חלב\n- להתקשר לרופא\n- לסיים פרויקט עבודה\n- רעיון למתנה ליום הולדת\n\nכל מה שעולה בראש!',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                textDirection: TextDirection.rtl,
                textInputAction: TextInputAction.newline,
              ),
            ).animate().slideY(begin: 0.3).fadeIn(delay: 200.ms),
          ),

          // Bottom tips
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.tips_and_updates,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  'טיפ: תוכל להמיר את הרשימות למשימות אמיתיות מאוחר יותר',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ).animate(delay: 400.ms).fadeIn(),
        ],
      ),
    );
  }

  int _getWordCount() {
    final text = _textController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }
}
