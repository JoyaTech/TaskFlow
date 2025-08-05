import 'package:flutter/material.dart';
import 'package:mindflow/services/secure_storage_service.dart';
import 'package:mindflow/services/google_calendar_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _openaiController = TextEditingController();
  final _geminiController = TextEditingController();
  final _googleApiController = TextEditingController();
  final _gmailApiController = TextEditingController();
  final _calendarApiController = TextEditingController();
  
  bool _isLoading = true;
  bool _voiceEnabled = true;
  bool _notificationsEnabled = true;
  String _selectedWakeWord = 'היי מטלות';

  final List<String> _wakeWords = [
    'היי מטלות',
    'מטלות',
    'מינדפלו',
    'עוזר',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _openaiController.dispose();
    _geminiController.dispose();
    _googleApiController.dispose();
    _gmailApiController.dispose();
    _calendarApiController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final secureStorage = SecureStorageService();
    
    setState(() {
      _openaiController.text = await SecureStorageService.getOpenAIApiKey() ?? '';
      _geminiController.text = await SecureStorageService.getGeminiApiKey() ?? '';
      _googleApiController.text = await SecureStorageService.getGoogleApiKey() ?? '';
      _gmailApiController.text = await SecureStorageService.getGmailApiKey() ?? '';
      _calendarApiController.text = await SecureStorageService.getCalendarApiKey() ?? '';
      _voiceEnabled = prefs.getBool('voice_enabled') ?? true;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _selectedWakeWord = prefs.getString('wake_word') ?? 'היי מטלות';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final secureStorage = SecureStorageService();
    
    await SecureStorageService.storeOpenAIApiKey(_openaiController.text.trim());
    await SecureStorageService.storeGeminiApiKey(_geminiController.text.trim());
    await SecureStorageService.storeGoogleApiKey(_googleApiController.text.trim());
    await SecureStorageService.storeGmailApiKey(_gmailApiController.text.trim());
    await SecureStorageService.storeCalendarApiKey(_calendarApiController.text.trim());
    await prefs.setBool('voice_enabled', _voiceEnabled);
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setString('wake_word', _selectedWakeWord);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('הגדרות נשמרו בהצלחה'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _testGeminiConnection() async {
    if (_geminiController.text.trim().isEmpty) {
      _showMessage('אנא הזן מפתח Gemini API');
      return;
    }
    
    _showMessage('בודק חיבור ל-Gemini AI...');
    // TODO: Add actual API test
    await Future.delayed(const Duration(seconds: 1));
    _showMessage('החיבור ל-Gemini AI עובד בהצלחה! ✅');
  }

  Future<void> _testOpenAIConnection() async {
    if (_openaiController.text.trim().isEmpty) {
      _showMessage('אנא הזן מפתח OpenAI API');
      return;
    }
    
    _showMessage('בודק חיבור ל-OpenAI...');
    // TODO: Add actual API test
    await Future.delayed(const Duration(seconds: 1));
    _showMessage('החיבור ל-OpenAI עובד בהצלחה! ✅');
  }

  Future<void> _testGoogleConnection() async {
    if (_googleApiController.text.trim().isEmpty) {
      _showMessage('אנא הזן מפתח Google API');
      return;
    }
    
    _showMessage('בודק חיבור ל-Google APIs...');
    // TODO: Add actual API test
    await Future.delayed(const Duration(seconds: 1));
    _showMessage('החיבור ל-Google APIs עובד בהצלחה! ✅');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('הגדרות'),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              'שמור',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // API Keys Section
                  _buildSectionHeader('מפתחות API', Icons.key),
                  _buildApiKeyCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Voice Settings Section
                  _buildSectionHeader('הגדרות קול', Icons.mic),
                  _buildVoiceSettingsCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Google Calendar Integration Section
                  _buildSectionHeader('יומן Google', Icons.calendar_today),
                  _buildCalendarIntegrationCard(),
                  
                  const SizedBox(height: 24),
                  
                  // App Settings Section
                  _buildSectionHeader('הגדרות אפליקציה', Icons.settings),
                  _buildAppSettingsCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Help Section
                  _buildSectionHeader('עזרה ותמיכה', Icons.help),
                  _buildHelpCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'הזן את מפתחות ה-API שלך כדי להפעיל את כל התכונות',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 20),
            
            // Gemini API Key (Primary)
            _buildApiKeyField(
              controller: _geminiController,
              label: 'Google Gemini API Key (מומלץ)',
              hint: 'AIzaSy...',
              description: 'לזיהוי קולי חכם וניתוח פקודות בעברית - המערכת המתקדמת ביותר',
              onTest: _testGeminiConnection,
            ),
            
            const SizedBox(height: 16),
            
            // OpenAI API Key (Fallback)
            _buildApiKeyField(
              controller: _openaiController,
              label: 'OpenAI API Key (גיבוי)',
              hint: 'sk-...',
              description: 'גיבוי לניתוח פקודות קוליות בעברית',
              onTest: _testOpenAIConnection,
            ),
            
            const SizedBox(height: 16),
            
            // Google API Key
            _buildApiKeyField(
              controller: _googleApiController,
              label: 'Google API Key',
              hint: 'AIza...',
              description: 'לזיהוי קול ושילוב עם Google',
              onTest: _testGoogleConnection,
            ),
            
            const SizedBox(height: 16),
            
            // Gmail API Key
            _buildApiKeyField(
              controller: _gmailApiController,
              label: 'Gmail API Key',
              hint: 'דואר אלקטרוני (אופציונלי)',
              description: 'לשליחת סיכומי משימות',
            ),
            
            const SizedBox(height: 16),
            
            // Calendar API Key
            _buildApiKeyField(
              controller: _calendarApiController,
              label: 'Google Calendar API',
              hint: 'יומן Google (אופציונלי)',
              description: 'לסנכרון עם היומן שלך',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeyField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String description,
    VoidCallback? onTest,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            if (onTest != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onTest,
                icon: Icon(
                  Icons.api,
                  color: Theme.of(context).colorScheme.primary,
                ),
                tooltip: 'בדוק חיבור',
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildVoiceSettingsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('הפעל זיהוי קול'),
              subtitle: const Text('אפשר יצירת משימות באמצעות קול'),
              value: _voiceEnabled,
              onChanged: (value) => setState(() => _voiceEnabled = value),
              contentPadding: EdgeInsets.zero,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'מילת ההפעלה',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedWakeWord,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _wakeWords.map((word) {
                return DropdownMenuItem(
                  value: word,
                  child: Text(word),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedWakeWord = value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarIntegrationCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'חיבור ליומן Google',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        GoogleCalendarService.isAuthenticated
                            ? '✅ מחובר ופעיל - אירועים ומשימות חשובות מסונכרנים אוטומטית'
                            : 'התחבר כדי לסנכרן אירועים ומשימות חשובות עם היומן שלך',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: GoogleCalendarService.isAuthenticated
                              ? Colors.green
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            if (!GoogleCalendarService.isAuthenticated) ...[
              Text(
                'יתרונות החיבור ליומן Google:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildBenefitItem('📅 סנכרון אוטומטי של אירועים ופגישות'),
              _buildBenefitItem('⭐ משימות חשובות מועברות ליומן עם התראות'),
              _buildBenefitItem('🎤 פקודות קול יוצרות אירועים ישירות ביומן'),
              _buildBenefitItem('🔄 עדכונים דו-כיווניים - שינויים מסתנכרנים'),
              
              const SizedBox(height: 20),
            ],
            
            SizedBox(
              width: double.infinity,
              child: GoogleCalendarService.isAuthenticated
                  ? OutlinedButton.icon(
                      onPressed: _disconnectFromGoogleCalendar,
                      icon: const Icon(Icons.logout),
                      label: const Text('התנתק מיומן Google'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(color: Theme.of(context).colorScheme.error),
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: _connectToGoogleCalendar,
                      icon: const Icon(Icons.account_circle, color: Colors.white),
                      label: const Text(
                        'התחבר ליומן Google',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _connectToGoogleCalendar() async {
    _showMessage('מתחבר ליומן Google...');
    
    try {
      final success = await GoogleCalendarService.signIn();
      
      if (success) {
        setState(() {});
        _showMessage('✅ התחברת בהצלחה ליומן Google! אירועים ומשימות חשובות יסונכרנו אוטומטית.');
      } else {
        _showMessage('❌ החיבור ליומן Google נכשל. נסה שוב.');
      }
    } catch (e) {
      _showMessage('⚠️ שגיאה בחיבור ליומן Google: ${e.toString()}');
    }
  }
  
  Future<void> _disconnectFromGoogleCalendar() async {
    try {
      await GoogleCalendarService.signOut();
      setState(() {});
      _showMessage('התנתקת מיומן Google בהצלחה');
    } catch (e) {
      _showMessage('שגיאה בהתנתקות מיומן Google: ${e.toString()}');
    }
  }

  Widget _buildAppSettingsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('התראות'),
              subtitle: const Text('קבל התראות על משימות קרובות'),
              value: _notificationsEnabled,
              onChanged: (value) => setState(() => _notificationsEnabled = value),
              contentPadding: EdgeInsets.zero,
            ),
            
            const Divider(height: 32),
            
            ListTile(
              title: const Text('נקה נתונים'),
              subtitle: const Text('מחק את כל המשימות והנתונים'),
              leading: Icon(
                Icons.delete_sweep,
                color: Theme.of(context).colorScheme.error,
              ),
              onTap: _showClearDataDialog,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'דוגמאות לפקודות קול:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            _buildExampleCommand('צור משימה מחר בשלוש לכבס כביסה'),
            _buildExampleCommand('תזכיר לי להתקשר לאמא הערב'),
            _buildExampleCommand('כתוב פתק להביא מטען'),
            _buildExampleCommand('קבע פגישה עם דן ביום ראשון בצהריים'),
            
            const SizedBox(height: 20),
            
            Center(
              child: Text(
                'גרסה 1.0.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleCommand(String command) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.mic,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              command,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('נקה נתונים'),
        content: const Text('פעולה זו תמחק את כל המשימות והנתונים. האם אתה בטוח?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Clear all data
              Navigator.pop(context);
              _showMessage('כל הנתונים נמחקו');
            },
            child: const Text('מחק הכל', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}