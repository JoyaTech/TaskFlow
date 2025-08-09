import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/demo_ai_providers.dart';

class DemoAISmartInputPage extends ConsumerStatefulWidget {
  const DemoAISmartInputPage({super.key});

  @override
  ConsumerState<DemoAISmartInputPage> createState() => _DemoAISmartInputPageState();
}

class _DemoAISmartInputPageState extends ConsumerState<DemoAISmartInputPage> {
  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isProcessing = ref.watch(demoAITaskProcessingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('כתיבה חכמה - דמו'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.science, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'זה דמו - אין צורך ב-API של OpenAI',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'כתוב משהו...',
                hintText: 'למשל: "פגישה עם רופא מחר בשעה 3" או "קנה חלב"',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isProcessing ? null : () async {
                  final text = _textController.text.trim();
                  if (text.isNotEmpty) {
                    final result = await ref
                        .read(demoAITaskProcessingProvider.notifier)
                        .processTextInput(text);
                    
                    if (result != null && mounted) {
                      _showSuccess(result);
                    }
                  }
                },
                child: isProcessing 
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('מעבד עם AI...'),
                        ],
                      )
                    : const Text('צור משימות חכמות'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccess(DemoTaskCreationResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('נוצר בהצלחה!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('נוצרה משימה: ${result.mainTask.title}'),
            if (result.subTasks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('+ ${result.subTasks.length} תת-משימות'),
            ],
            const SizedBox(height: 8),
            Text('רמת ביטחון: ${(result.confidence * 100).round()}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('אישור'),
          ),
        ],
      ),
    );
  }
}
