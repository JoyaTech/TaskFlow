# MindFlow - Hebrew Task Management and Voice Assistant

![Hebrew RTL Support](https://img.shields.io/badge/Hebrew-RTL%20Support-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.6.0%2B-brightgreen)
![Firebase](https://img.shields.io/badge/Firebase-Integrated-orange)

MindFlow is a Hebrew-first task management and voice assistant app designed specifically for users with ADHD, featuring natural language voice commands, Google Calendar integration, and gamified positive reinforcement.

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

## 🌟 Features

- **Task Management**: Create, edit, and delete tasks with priority levels and due date reminders.
- **Voice Assistant**: Hebrew voice commands for task creation and management.
- **Focus Mode**: Pomodoro timer with statistics and habit tracking.
- **Integration**: Google Calendar sync and email task summaries.
- **Hebrew-First Design**: RTL support and culturally appropriate UX.
- **Security**: Enhanced security measures with user authentication.

## 🛠 Architecture Overview

- **State Management**: Utilizing Riverpod for state control.
- **Navigation**: Managed by GoRouter.
- **Database Layer**: Firebase Firestore with security rules.
- **Voice Service**: Integrated Hebrew Speech-to-Text API.

```
lib/
├── main.dart                    # App entry point
├── theme.dart                   # App themes
├── core/
│   ├── router.dart              # App navigation
├── services/
│   ├── auth_service.dart        # User authentication logic
│   ├── database_service.dart    # Database operations
│   ├── voice_service.dart       # Voice command handling
├── providers/
│   └── task_providers.dart      # Task state management
└── screens/
    ├── home_page.dart           # Main screen
    ├── settings_page.dart       # App settings
    └── focus_timer_screen.dart  # Focus mode
```

## 🤝 Contributing

We welcome contributions from the community! Please read our [contribution guidelines](CONTRIBUTING.md) for more details.

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 📞 Support

For help and support, please open an issue on GitHub or contact the maintainers.
