# MindFlow - AI-Powered ADHD Task Management 🧠✨

<div align="center">

![Hebrew RTL Support](https://img.shields.io/badge/Hebrew-RTL%20Support-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.19.0%2B-brightgreen)
![Firebase](https://img.shields.io/badge/Firebase-Integrated-orange)
![OpenAI](https://img.shields.io/badge/OpenAI-Integrated-purple)
![Gemini](https://img.shields.io/badge/Gemini-AI-blue)
![ADHD](https://img.shields.io/badge/ADHD-Friendly-green)

**Advanced AI-Powered Task Management System with Voice Recognition and Natural Language Processing**

*Specially designed for ADHD minds with comprehensive Hebrew/RTL support*

</div>

## 🚀 Latest Major Update: Complete AI Integration

### ✨ New AI Features (Just Added!)
- **🤖 Auto Smart AI FAB**: Automatically detects API keys and switches between demo/real AI modes
- **🎤 AI Voice Task Creation**: Hebrew voice recognition with OpenAI/Gemini processing  
- **📝 Smart Text Input**: Natural language processing for intuitive task creation
- **📧 AI Email Scanning**: Convert emails to actionable tasks automatically
- **🧠 Overwhelmed State Helper**: ADHD-friendly AI task breakdown and prioritization
- **🎨 Voice Visualizer**: Real-time audio visualization during voice input
- **🔄 Demo Mode**: Full-featured demo system that works without any API keys

MindFlow is a Hebrew-first, AI-powered task management system designed specifically for users with ADHD, featuring advanced voice commands, intelligent task processing, and comprehensive accessibility support.

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (3.6.0+)
- Firebase CLI
- Android Studio / Xcode

### Installation

1. Clone the repository.
   ```bash
   git clone https://github.com/yourusername/mindflow.git
   cd mindflow
   ```
2. Install dependencies.
   ```bash
   flutter pub get
   ```
3. Configure Firebase with your project settings.

4. Run the app.
   ```bash
   flutter run
   ```

## 🌟 Core Features

### 🤖 AI-Powered Task Creation
- **Dual AI Support**: OpenAI GPT & Google Gemini integration
- **Hebrew Voice Recognition**: Native RTL voice processing with real-time transcription
- **Smart Text Processing**: Natural language understanding for task extraction
- **Demo Mode**: Full AI simulation without requiring API keys
- **Automatic Fallback**: Seamless switching between AI providers

### 📱 Advanced Task Management
- **Intelligent Task Creation**: AI-powered priority and date detection
- **Visual Progress Tracking**: Real-time statistics and completion rates
- **Advanced Filtering**: Smart categorization and search capabilities
- **Flexible Workflows**: Adapt to changing ADHD priorities
- **Cloud Synchronization**: Real-time sync across all devices

### 🧠 ADHD-Specific Features  
- **Brain Dump Mode**: Quick thought capture without structure
- **Overwhelmed State Management**: AI-powered task breakdown assistance
- **Visual Cues & Animations**: Engaging, distraction-friendly interface
- **Minimal Friction**: Quick actions with gesture support
- **Gentle Reminders**: Non-intrusive notification system

### 🌐 Integration & Accessibility
- **Google Calendar Sync**: Seamless calendar integration
- **Email Task Extraction**: AI-powered email to task conversion
- **Hebrew-First Design**: Complete RTL support and cultural adaptation
- **Voice Accessibility**: Screen reader compatible with audio feedback
- **Cross-Platform**: Works on Android, iOS, Web, and Desktop

## 🏗️ Advanced Architecture

### Clean Architecture with AI Integration
- **State Management**: Riverpod with AsyncNotifier for AI processing
- **AI Providers**: Modular OpenAI/Gemini integration with automatic fallback
- **Database Layer**: Firebase Firestore with offline capabilities
- **Voice Processing**: Real-time Hebrew Speech-to-Text with AI enhancement
- **Security**: Encrypted API key storage with secure retrieval

### Updated Project Structure
```
lib/
├── main.dart                           # App entry point
├── theme.dart                          # Advanced theming system
├── core/
│   ├── router.dart                     # Navigation management
├── services/
│   ├── auth_service.dart               # User authentication
│   ├── database_service.dart           # Firebase operations  
│   ├── secure_storage_service.dart     # Encrypted API key storage
│   ├── voice_service.dart              # Voice recognition
│   └── ai_service.dart                 # AI provider management
├── features/
│   ├── tasks/
│   │   ├── domain/                     # Business logic & entities
│   │   │   ├── entities/task.dart      # Task entity
│   │   │   └── usecases/create_task_with_ai.dart
│   │   ├── data/                       # Data sources & repositories
│   │   └── presentation/               # UI, pages, widgets & providers
│   │       ├── providers/
│   │       │   ├── real_ai_providers.dart     # Production AI
│   │       │   ├── demo_ai_providers.dart     # Demo AI simulation
│   │       │   └── task_providers.dart        # Task state management
│   │       ├── widgets/
│   │       │   ├── auto_smart_ai_fab.dart     # Adaptive AI FAB
│   │       │   ├── voice_visualizer.dart      # Audio visualization
│   │       │   └── task_item_widget.dart      # Task display
│   │       └── pages/
│   │           ├── task_list_page.dart        # Main task interface
│   │           ├── demo_ai_voice_input_page.dart  # Voice input (demo)
│   │           └── demo_ai_smart_input_page.dart  # Text input (demo)
│   ├── brain_dump/                     # ADHD quick capture
│   └── gmail/                          # Email integration (future)
└── settings_page.dart                  # Comprehensive settings with API keys
```

## 🚀 Getting Started with AI Features

### Option 1: Demo Mode (No Setup Required)
```bash
git clone https://github.com/JoyaTech/TaskFlow.git
cd TaskFlow
flutter pub get
flutter run
```
**The app works immediately in demo mode!** All AI features are simulated.

### Option 2: Full AI Integration
1. **Get API Keys** (optional):
   - [Google AI Studio](https://aistudio.google.com/app/apikey) - Gemini API (recommended for Hebrew)
   - [OpenAI Platform](https://platform.openai.com/api-keys) - GPT API (fallback)

2. **Add Keys in App**:
   - Launch app → Tap AI FAB → "הוסף API Key"
   - Enter your API keys in settings
   - FAB automatically turns purple when AI is ready!

3. **Enable Voice Recognition** (mobile only):
   ```yaml
   dependencies:
     speech_to_text: ^6.3.0
   ```

## 🎯 Usage Examples

### Voice Task Creation
```
1. Tap purple AI FAB 🧠
2. Select "הקלטה קולית חכמה" 🎤
3. Say: "תזכיר לי להתקשר לדן מחר בשלוש אחרי הצהריים"
4. AI creates: "התקשר לדן" - Due: Tomorrow 3:00 PM - Priority: Medium
```

### Smart Text Input
```
1. AI FAB → "כתיבה חכמה" ✏️
2. Type: "קניות לשבת חלב לחם וביצים עד יום חמישי"
3. AI extracts: "קניות לשבת" - Items: [חלב, לחם, ביצים] - Due: Thursday
```

### Overwhelmed State Help
```
1. AI FAB → "אני מרגיש המום" 🧠
2. AI analyzes your current tasks
3. Suggests 3-5 small, manageable actions for today
4. Provides emotional support and breathing reminders
```

## 📊 Repository Insights

### Latest Commits
- ✅ **Major AI Integration**: 19 files added, 5,431+ lines
- ✅ **Real AI Providers**: OpenAI & Gemini integration
- ✅ **Auto Smart AI FAB**: Adaptive UI based on API availability 
- ✅ **Demo AI System**: Full simulation without external APIs
- ✅ **Hebrew Voice Processing**: RTL voice recognition support

### Technical Metrics
- **Language**: Dart (Flutter)
- **Architecture**: Clean Architecture + Riverpod
- **Lines of Code**: 15,000+
- **AI Features**: 8 new intelligent components
- **Test Coverage**: Unit & Widget tests included

### Development Activity
```bash
# View recent changes
git log --oneline -10

# See AI integration stats  
git diff --stat HEAD~1

# Analyze code complexity
flutter analyze
```

## 🤝 Contributing

### Development Workflow
1. **Fork** this repository
2. **Test Demo Mode**: No API keys needed for development
3. **Create Feature Branch**: `git checkout -b feature/ai-enhancement`
4. **Develop & Test**: Use demo AI for rapid iteration
5. **Document in Hebrew**: Add Hebrew comments for ADHD features
6. **Submit PR**: Detailed description with demo screenshots

### Code Standards
- **Clean Architecture**: Maintain domain/data/presentation separation
- **AI Safety**: Always provide fallbacks and error handling
- **ADHD Consideration**: Keep interfaces simple and forgiving
- **Hebrew Support**: All user-facing text in Hebrew with RTL support

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **OpenAI & Google**: AI API providers enabling intelligent task processing
- **Flutter Community**: Amazing framework and ecosystem
- **ADHD Community**: Invaluable feedback on accessibility and UX
- **Hebrew Localization**: Community contributors for RTL support

---

<div align="center">

**🌟 Built with ❤️ for the ADHD community**

*Making task management intuitive, supportive, and accessible*

[⭐ Star this repo](https://github.com/JoyaTech/TaskFlow) • [🐛 Report Issues](https://github.com/JoyaTech/TaskFlow/issues) • [💬 Discussions](https://github.com/JoyaTech/TaskFlow/discussions)

**Repository**: `https://github.com/JoyaTech/TaskFlow.git`

</div>
