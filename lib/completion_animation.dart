import 'package:flutter/material.dart';

class CompletionAnimation extends StatefulWidget {
  final VoidCallback? onComplete;

  const CompletionAnimation({super.key, this.onComplete});

  @override
  State<CompletionAnimation> createState() => _CompletionAnimationState();
}

class _CompletionAnimationState extends State<CompletionAnimation>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _confettiController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _confettiAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _confettiAnimation = CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeOut,
    );

    _startAnimation();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _scaleController.forward();
    _fadeController.forward();
    _confettiController.forward();

    await Future.delayed(const Duration(milliseconds: 2000));
    if (widget.onComplete != null) {
      widget.onComplete!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Confetti particles
            AnimatedBuilder(
              animation: _confettiAnimation,
              builder: (context, child) {
                return SizedBox(
                  width: 200,
                  height: 200,
                  child: CustomPaint(
                    painter: ConfettiPainter(_confettiAnimation.value),
                  ),
                );
              },
            ),

            // Main celebration icon
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Celebration text
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    children: [
                      Text(
                        '🎉 כל הכבוד! 🎉',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'משימה הושלמה בהצלחה',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // Motivational message
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value * 0.8,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getMotivationalMessage(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.4,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getMotivationalMessage() {
    final messages = [
      'אתה על הדרך הנכונה! 💪',
      'כל משימה קטנה היא צעד גדול קדימה 🚀',
      'הצלחת! המשך את המומנטום הזה ✨',
      'גאה בך! אתה עושה זאת נהדר 🌟',
      'עוד משימה הושלמה! אתה בלתי עצור 🔥',
      'כל הכבוד על ההתמדה! 🎯',
    ];
    
    return messages[DateTime.now().millisecond % messages.length];
  }
}

class ConfettiPainter extends CustomPainter {
  final double progress;
  final List<ConfettiParticle> particles;

  ConfettiPainter(this.progress) : particles = _generateParticles();

  static List<ConfettiParticle> _generateParticles() {
    final particles = <ConfettiParticle>[];
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
    ];

    for (int i = 0; i < 30; i++) {
      particles.add(ConfettiParticle(
        x: 100 + (i % 10 - 5) * 20.0,
        y: 100 + (i ~/ 10 - 1) * 30.0,
        color: colors[i % colors.length],
        size: 4 + (i % 3) * 2.0,
        velocityX: (i % 7 - 3) * 2.0,
        velocityY: -50 - (i % 5) * 10.0,
      ));
    }

    return particles;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final particle in particles) {
      final currentX = particle.x + particle.velocityX * progress;
      final currentY = particle.y + particle.velocityY * progress + 980 * progress * progress / 2;

      // Only draw particles that are still visible
      if (currentY < size.height + 50) {
        paint.color = particle.color.withValues(alpha: 1.0 - progress);
        canvas.drawCircle(
          Offset(currentX, currentY),
          particle.size,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class ConfettiParticle {
  final double x;
  final double y;
  final Color color;
  final double size;
  final double velocityX;
  final double velocityY;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.velocityX,
    required this.velocityY,
  });
}

// Helper widget to show celebration overlay
class CelebrationOverlay {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => CompletionAnimation(
        onComplete: () => Navigator.of(context).pop(),
      ),
    );
  }
}