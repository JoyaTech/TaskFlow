import 'package:flutter/material.dart';
import '../widgets/custom_graphics.dart';

/// MindFlow Graphics Demo Screen
/// Showcases all ADHD-focused, Hebrew-first graphics components
/// This demonstrates the comprehensive graphics implementation

class GraphicsDemoScreen extends StatefulWidget {
  const GraphicsDemoScreen({Key? key}) : super(key: key);

  @override
  State<GraphicsDemoScreen> createState() => _GraphicsDemoScreenState();
}

class _GraphicsDemoScreenState extends State<GraphicsDemoScreen>
    with TickerProviderStateMixin {
  VoiceState _voiceState = VoiceState.idle;
  bool _isVoiceAnimating = false;
  bool _isTimerRunning = false;
  Duration _remainingTime = const Duration(minutes: 25);
  final Duration _totalTime = const Duration(minutes: 25);
  double _progressBarValue = 0.7;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // Hebrew RTL support
      child: Scaffold(
        backgroundColor: MindFlowGraphics.softBackground,
        appBar: AppBar(
          title: const Text(
            'מדריך גרפיקות MindFlow',
            style: TextStyle(
              fontFamily: 'NotoSansHebrew',
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: MindFlowGraphics.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Voice Interface Demo
              _buildSection(
                'מערכת קול חכמה', // "Smart Voice System"
                [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildVoiceStateDemo(VoiceState.idle, 'מנוחה'),
                      _buildVoiceStateDemo(VoiceState.listening, 'מאזין'),
                      _buildVoiceStateDemo(VoiceState.processing, 'מעבד'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  MindFlowGraphics.audioWaveVisualizer(
                    isActive: _voiceState != VoiceState.idle,
                    waveAmplitudes: const [0.2, 0.8, 0.4, 0.9, 0.3, 0.6, 0.7],
                  ),
                  const SizedBox(height: 20),
                  MindFlowGraphics.hebrewVoiceTutorial(
                    hebrewText: 'צור משימה חדשה',
                    englishHint: 'Create a new task',
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Section 2: ADHD-Specific Components
              _buildSection(
                'רכיבי ADHD מותאמים', // "ADHD-Adapted Components"
                [
                  MindFlowGraphics.adhdTaskCard(
                    title: 'להתקשר לרופא השיניים',
                    subtitle: 'עד יום שני הקרוב',
                    isCompleted: false,
                    onTap: () => _showSnackBar('Task tapped!'),
                  ),
                  MindFlowGraphics.adhdTaskCard(
                    title: 'לסיים פרויקט העבודה',
                    subtitle: 'הושלם בהצלחה!',
                    isCompleted: true,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: MindFlowGraphics.pomodoroTimer(
                      remainingTime: _remainingTime,
                      totalTime: _totalTime,
                      isPaused: !_isTimerRunning,
                      onPlayPause: _toggleTimer,
                      onStop: _stopTimer,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: MindFlowGraphics.gentleBreakReminder(
                      message: 'זמן להפסקה מרגיעה',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Section 3: Gamification System
              _buildSection(
                'מערכת הישגים', // "Achievement System"
                [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          MindFlowGraphics.achievementBadge(
                            type: AchievementType.firstTask,
                            tier: 1,
                            isUnlocked: true,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'משימה ראשונה',
                            style: TextStyle(
                              fontFamily: 'NotoSansHebrew',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          MindFlowGraphics.achievementBadge(
                            type: AchievementType.weekStreak,
                            tier: 3,
                            isUnlocked: true,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'רצף שבועי',
                            style: TextStyle(
                              fontFamily: 'NotoSansHebrew',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          MindFlowGraphics.achievementBadge(
                            type: AchievementType.focusChampion,
                            tier: 5,
                            isUnlocked: false,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'אלוף ריכוז',
                            style: TextStyle(
                              fontFamily: 'NotoSansHebrew',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  MindFlowGraphics.hebrewProgressBar(
                    progress: _progressBarValue,
                    label: 'התקדמות שבועית',
                    progressColor: MindFlowGraphics.successGreen,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'רמה נוכחית: ',
                        style: TextStyle(
                          fontFamily: 'NotoSansHebrew',
                          fontSize: 16,
                        ),
                      ),
                      MindFlowGraphics.levelIndicator(
                        currentLevel: 3,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Section 4: Onboarding Illustrations
              _buildSection(
                'איורי הדרכה', // "Onboarding Illustrations"
                [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          MindFlowGraphics.voiceWaveIllustration(size: 100),
                          const SizedBox(height: 8),
                          const Text(
                            'קלט קולי',
                            style: TextStyle(
                              fontFamily: 'NotoSansHebrew',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          MindFlowGraphics.taskBreakdownIllustration(size: 100),
                          const SizedBox(height: 8),
                          const Text(
                            'פירוק משימות',
                            style: TextStyle(
                              fontFamily: 'NotoSansHebrew',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          MindFlowGraphics.focusFlowIllustration(size: 100),
                          const SizedBox(height: 8),
                          const Text(
                            'זרימת ריכוז',
                            style: TextStyle(
                              fontFamily: 'NotoSansHebrew',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Section 5: Celebration & Empty States
              _buildSection(
                'חגיגות ומצבים ריקים', // "Celebrations & Empty States"
                [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      MindFlowGraphics.celebrationStar(),
                      MindFlowGraphics.celebrationCheck(),
                      MindFlowGraphics.celebrationCircle(progress: 0.7),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          MindFlowGraphics.allDoneIllustration(),
                          const SizedBox(height: 8),
                          const Text(
                            'הכל הושלם!',
                            style: TextStyle(
                              fontFamily: 'NotoSansHebrew',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          MindFlowGraphics.emptyMindIllustration(),
                          const SizedBox(height: 8),
                          const Text(
                            'מחשבה ריקה',
                            style: TextStyle(
                              fontFamily: 'NotoSansHebrew',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Section 6: Custom Icons
              _buildSection(
                'סמלים מותאמים', // "Custom Icons"
                [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          MindFlowGraphics.taskIcon(
                            color: MindFlowGraphics.primaryBlue,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          const Text('משימה'),
                        ],
                      ),
                      Column(
                        children: [
                          MindFlowGraphics.noteIcon(
                            color: MindFlowGraphics.professionalPurple,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          const Text('הערה'),
                        ],
                      ),
                      Column(
                        children: [
                          MindFlowGraphics.eventIcon(
                            color: MindFlowGraphics.successGreen,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          const Text('אירוע'),
                        ],
                      ),
                      Column(
                        children: [
                          MindFlowGraphics.priorityIcon(
                            color: MindFlowGraphics.warningAmber,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          const Text('דחיפות'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'NotoSansHebrew',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceStateDemo(VoiceState state, String label) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() {
            _voiceState = state;
            _isVoiceAnimating = state != VoiceState.idle;
          }),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _voiceState == state 
                  ? MindFlowGraphics.primaryBlue.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: _voiceState == state
                  ? Border.all(color: MindFlowGraphics.primaryBlue, width: 2)
                  : null,
            ),
            child: MindFlowGraphics.voiceMicrophone(
              state: state,
              isAnimating: _voiceState == state && _isVoiceAnimating,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'NotoSansHebrew',
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _toggleTimer() {
    setState(() {
      _isTimerRunning = !_isTimerRunning;
    });
    _showSnackBar(_isTimerRunning ? 'Timer started!' : 'Timer paused!');
  }

  void _stopTimer() {
    setState(() {
      _isTimerRunning = false;
      _remainingTime = _totalTime;
    });
    _showSnackBar('Timer stopped!');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: MindFlowGraphics.primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
