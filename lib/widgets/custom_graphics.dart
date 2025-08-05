import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom graphics widgets following FocusFlow design style guide:
/// - Clean minimalism
/// - Monochromatic with subtle color touches
/// - Abstract and flowing
/// - High clarity and contrast

class FocusFlowGraphics {
  // Color palette based on the style guide
  static const Color primaryTint = Color(0xFF4A90E2); // Soft blue
  static const Color secondaryTint = Color(0xFF7FCDCD); // Soft teal
  static const Color neutralGray = Color(0xFF8E8E93);
  
  /// 1. ONBOARDING ILLUSTRATIONS
  
  // Illustration 1: "Smart Voice Input" - Wave becoming organized
  static Widget voiceWaveIllustration({double size = 200}) {
    return Container(
      width: size,
      height: size,
      child: CustomPaint(
        painter: VoiceWavePainter(),
      ),
    );
  }
  
  // Illustration 2: "Task Breakdown" - Complex shape breaking into simple ones
  static Widget taskBreakdownIllustration({double size = 200}) {
    return Container(
      width: size,
      height: size,
      child: CustomPaint(
        painter: TaskBreakdownPainter(),
      ),
    );
  }
  
  // Illustration 3: "Focus & Flow" - Chaotic lines becoming one flowing line
  static Widget focusFlowIllustration({double size = 200}) {
    return Container(
      width: size,
      height: size,
      child: CustomPaint(
        painter: FocusFlowPainter(),
      ),
    );
  }
  
  /// 2. EMPTY STATES
  
  // Empty State 1: "All Done!" - Calm waves
  static Widget allDoneIllustration({double size = 120}) {
    return Container(
      width: size,
      height: size,
      child: CustomPaint(
        painter: CalmWavesPainter(),
      ),
    );
  }
  
  // Empty State 2: "Empty Mind Box"
  static Widget emptyMindIllustration({double size = 120}) {
    return Container(
      width: size,
      height: size,
      child: CustomPaint(
        painter: EmptyMindPainter(),
      ),
    );
  }
  
  /// 3. CELEBRATION ICONS
  
  // Celebration 1: Minimalist star with radiating lines
  static Widget celebrationStar({double size = 60}) {
    return Container(
      width: size,
      height: size,
      child: CustomPaint(
        painter: CelebrationStarPainter(),
      ),
    );
  }
  
  // Celebration 2: Check mark becoming a leaf/wave
  static Widget celebrationCheck({double size = 60}) {
    return Container(
      width: size,
      height: size,
      child: CustomPaint(
        painter: CelebrationCheckPainter(),
      ),
    );
  }
  
  // Celebration 3: Expanding circle
  static Widget celebrationCircle({double size = 60, double progress = 1.0}) {
    return Container(
      width: size,
      height: size,
      child: CustomPaint(
        painter: CelebrationCirclePainter(progress: progress),
      ),
    );
  }
  
  /// 4. CUSTOM CATEGORY ICONS
  
  // Task icon: Circle with check
  static Widget taskIcon({double size = 24, Color? color}) {
    return Container(
      width: size,
      height: size,
      child: CustomPaint(
        painter: TaskIconPainter(color: color ?? Colors.black87),
      ),
    );
  }
  
  // Note icon: Square with wavy line
  static Widget noteIcon({double size = 24, Color? color}) {
    return Container(
      width: size,
      height: size,
      child: CustomPaint(
        painter: NoteIconPainter(color: color ?? Colors.black87),
      ),
    );
  }
  
  // Event icon: Minimalist calendar
  static Widget eventIcon({double size = 24, Color? color}) {
    return Container(
      width: size,
      height: size,
      child: CustomPaint(
        painter: EventIconPainter(color: color ?? Colors.black87),
      ),
    );
  }
  
  // Priority icon: Minimalist star
  static Widget priorityIcon({double size = 24, Color? color}) {
    return Container(
      width: size,
      height: size,
      child: CustomPaint(
        painter: PriorityIconPainter(color: color ?? Colors.black87),
      ),
    );
  }
}

/// CUSTOM PAINTERS IMPLEMENTATION

class VoiceWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = FocusFlowGraphics.primaryTint.withOpacity(0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final path = Path();
    
    // Chaotic wave on the left
    path.moveTo(20, size.height * 0.5);
    for (int i = 0; i < 5; i++) {
      double x = 20 + (i * 20);
      double y = size.height * 0.5 + (i % 2 == 0 ? -30 : 30) * (1 - i * 0.1);
      path.lineTo(x, y);
    }
    
    // Transition to organized line
    path.lineTo(size.width * 0.7, size.height * 0.5);
    path.lineTo(size.width - 20, size.height * 0.5);
    
    canvas.drawPath(path, paint);
    
    // Add subtle task box at the end
    final boxPaint = Paint()
      ..color = FocusFlowGraphics.neutralGray.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 40, size.height * 0.4, 30, 20),
        Radius.circular(4),
      ),
      boxPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TaskBreakdownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = FocusFlowGraphics.secondaryTint.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    // Large complex shape on the left
    final largePath = Path();
    largePath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(20, size.height * 0.2, 80, 80),
      Radius.circular(20),
    ));
    canvas.drawPath(largePath, paint);
    
    // Arrow indicating transformation
    final arrowPaint = Paint()
      ..color = FocusFlowGraphics.neutralGray
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(
      Offset(110, size.height * 0.5),
      Offset(140, size.height * 0.5),
      arrowPaint,
    );
    
    // Small simple shapes on the right
    final smallPaint = Paint()
      ..color = FocusFlowGraphics.primaryTint.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    
    // Three small rectangles
    for (int i = 0; i < 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            160,
            size.height * 0.3 + (i * 25),
            20,
            20,
          ),
          Radius.circular(4),
        ),
        smallPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FocusFlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final chaosPaint = Paint()
      ..color = FocusFlowGraphics.neutralGray.withOpacity(0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    // Chaotic lines on the left
    for (int i = 0; i < 8; i++) {
      canvas.drawLine(
        Offset(20 + (i * 10), 20 + (i * 5)),
        Offset(40 + (i * 8), size.height - 20 - (i * 8)),
        chaosPaint,
      );
    }
    
    // Single flowing line on the right
    final flowPaint = Paint()
      ..color = FocusFlowGraphics.primaryTint
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final flowPath = Path();
    flowPath.moveTo(size.width * 0.6, size.height * 0.3);
    flowPath.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.5,
      size.width - 20,
      size.height * 0.7,
    );
    
    canvas.drawPath(flowPath, flowPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CalmWavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = FocusFlowGraphics.secondaryTint.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    // Draw multiple gentle waves
    for (int i = 0; i < 3; i++) {
      final path = Path();
      double yOffset = size.height * 0.3 + (i * 20);
      
      path.moveTo(10, yOffset);
      for (double x = 10; x < size.width - 10; x += 20) {
        path.quadraticBezierTo(
          x + 10,
          yOffset + 8,
          x + 20,
          yOffset,
        );
      }
      
      canvas.drawPath(path, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EmptyMindPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = FocusFlowGraphics.neutralGray.withOpacity(0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    // Head outline
    final headPath = Path();
    headPath.addOval(Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.4),
      width: size.width * 0.6,
      height: size.height * 0.6,
    ));
    
    canvas.drawPath(headPath, paint);
    
    // Flowing lines inside representing clear thoughts
    final flowPaint = Paint()
      ..color = FocusFlowGraphics.primaryTint.withOpacity(0.4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    final innerPath = Path();
    innerPath.moveTo(size.width * 0.3, size.height * 0.4);
    innerPath.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.3,
      size.width * 0.7,
      size.height * 0.4,
    );
    
    canvas.drawPath(innerPath, flowPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CelebrationStarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = FocusFlowGraphics.primaryTint
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final center = Offset(size.width / 2, size.height / 2);
    
    // Star rays
    for (int i = 0; i < 8; i++) {
      double angle = (i * 45) * (3.14159 / 180);
      double length = i % 2 == 0 ? 20 : 12;
      
      canvas.drawLine(
        center,
        Offset(
          center.dx + length * cos(angle),
          center.dy + length * sin(angle),
        ),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CelebrationCheckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = FocusFlowGraphics.secondaryTint
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.5);
    path.lineTo(size.width * 0.45, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.4,
      size.width * 0.8,
      size.height * 0.3,
    );
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CelebrationCirclePainter extends CustomPainter {
  final double progress;
  
  CelebrationCirclePainter({required this.progress});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = FocusFlowGraphics.primaryTint.withOpacity(0.6 * (1 - progress))
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      (size.width / 2) * progress,
      paint,
    );
  }
  
  @override
  bool shouldRepaint(CelebrationCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class TaskIconPainter extends CustomPainter {
  final Color color;
  
  TaskIconPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    // Circle
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2 - 2,
      paint,
    );
    
    // Check mark
    final checkPaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final checkPath = Path();
    checkPath.moveTo(size.width * 0.3, size.height * 0.5);
    checkPath.lineTo(size.width * 0.45, size.height * 0.65);
    checkPath.lineTo(size.width * 0.7, size.height * 0.35);
    
    canvas.drawPath(checkPath, checkPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NoteIconPainter extends CustomPainter {
  final Color color;
  
  NoteIconPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    // Square
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
        Radius.circular(3),
      ),
      paint,
    );
    
    // Wavy line inside
    final wavyPaint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    final wavyPath = Path();
    wavyPath.moveTo(size.width * 0.2, size.height * 0.5);
    wavyPath.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.4,
      size.width * 0.6,
      size.height * 0.5,
    );
    wavyPath.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.6,
      size.width * 0.8,
      size.height * 0.5,
    );
    
    canvas.drawPath(wavyPath, wavyPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EventIconPainter extends CustomPainter {
  final Color color;
  
  EventIconPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    // Calendar base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 4, size.width - 4, size.height - 6),
        Radius.circular(2),
      ),
      paint,
    );
    
    // Calendar rings
    canvas.drawLine(
      Offset(size.width * 0.3, 2),
      Offset(size.width * 0.3, 8),
      paint,
    );
    
    canvas.drawLine(
      Offset(size.width * 0.7, 2),
      Offset(size.width * 0.7, 8),
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PriorityIconPainter extends CustomPainter {
  final Color color;
  
  PriorityIconPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    
    final starPath = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;
    
    // Simple 5-pointed star outline
    for (int i = 0; i < 5; i++) {
      double angle = (i * 72 - 90) * (3.14159 / 180);
      double x = center.dx + radius * cos(angle);
      double y = center.dy + radius * sin(angle);
      
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();
    
    canvas.drawPath(starPath, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Helper function for math
double cos(double angle) => math.cos(angle);
double sin(double angle) => math.sin(angle);
