import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindflow/providers/task_providers.dart';

class FocusTimerScreen extends ConsumerWidget {
  const FocusTimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusSession = ref.watch(focusSessionProvider);
    final focusNotifier = ref.read(focusSessionProvider.notifier);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('טיימר פוקוס'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timer,
              size: 120,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ),
            const SizedBox(height: 20),
            Text(
              _formatDuration(focusSession.remainingTime),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 40,
              ),
            ),
            const SizedBox(height: 40),
            if (focusSession.status == FocusSessionStatus.idle)
              ElevatedButton(
                onPressed: () => focusNotifier.startSession(),
                child: const Text('התחל סשן פוקוס'),
              ),
            if (focusSession.status == FocusSessionStatus.running)
              ElevatedButton(
                onPressed: () => focusNotifier.pauseSession(),
                child: const Text('השהה'),
              ),
            if (focusSession.status == FocusSessionStatus.paused)
              ElevatedButton(
                onPressed: () => focusNotifier.resumeSession(),
                child: const Text('חדש'),
              ),
            if (focusSession.status == FocusSessionStatus.running ||
                focusSession.status == FocusSessionStatus.paused)
              const SizedBox(height: 20),
            if (focusSession.status == FocusSessionStatus.running ||
                focusSession.status == FocusSessionStatus.paused)
              TextButton(
                onPressed: () => focusNotifier.stopSession(),
                child: const Text('עצור סשן'),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
