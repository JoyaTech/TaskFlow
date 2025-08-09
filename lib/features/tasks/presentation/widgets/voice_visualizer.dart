import 'dart:math' as math;
import 'package:flutter/material.dart';

class VoiceVisualizer extends StatelessWidget {
  final bool isListening;
  final bool isProcessing;
  final AnimationController waveController;

  const VoiceVisualizer({
    super.key,
    required this.isListening,
    required this.isProcessing,
    required this.waveController,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Sound waves
          if (isListening) ..._buildSoundWaves(),
          
          // Processing circles
          if (isProcessing) ..._buildProcessingCircles(),
          
          // Central microphone
          _buildCentralMic(),
        ],
      ),
    );
  }

  List<Widget> _buildSoundWaves() {
    return List.generate(3, (index) {
      final delay = index * 0.2;
      final size = 120.0 + (index * 30);
      
      return AnimatedBuilder(
        animation: waveController,
        builder: (context, child) {
          final animationValue = (waveController.value + delay) % 1.0;
          final opacity = 1.0 - animationValue;
          final scale = 0.5 + (animationValue * 0.5);
          
          return Transform.scale(
            scale: scale,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.blue.withOpacity(opacity * 0.6),
                  width: 2,
                ),
              ),
            ),
          );
        },
      );
    });
  }

  List<Widget> _buildProcessingCircles() {
    return List.generate(2, (index) {
      return AnimatedBuilder(
        animation: waveController,
        builder: (context, child) {
          final angle = (waveController.value * 2 * math.pi) + (index * math.pi);
          final radius = 60.0;
          final x = math.cos(angle) * radius;
          final y = math.sin(angle) * radius;
          
          return Transform.translate(
            offset: Offset(x, y),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purple.withOpacity(0.8),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildCentralMic() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isProcessing 
              ? [Colors.purple.shade400, Colors.purple.shade600]
              : isListening 
                  ? [Colors.red.shade400, Colors.red.shade600]
                  : [Colors.grey.shade400, Colors.grey.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (isProcessing 
                ? Colors.purple
                : isListening 
                    ? Colors.red
                    : Colors.grey).withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Icon(
        isProcessing 
            ? Icons.auto_awesome
            : isListening 
                ? Icons.mic
                : Icons.mic_none,
        color: Colors.white,
        size: 36,
      ),
    );
  }
}
