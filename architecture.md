# MindFlow - Hebrew ADHD Task Assistant Architecture

## Overview
A Hebrew-first task management and voice assistant app designed specifically for users with ADHD, featuring natural language voice commands, Google Calendar integration, and gamified positive reinforcement.

## Core Features & Technical Implementation

### 1. Voice Recognition & Command Processing
- **Hebrew Speech-to-Text**: Google Speech-to-Text API for Hebrew language support
- **Intent Parsing**: OpenAI GPT for extracting task details (date/time, priority, action type)
- **Voice Trigger**: "היי מטלות" (Hey Tasks) or user-customizable wake word
- **Command Types**: Task creation, reminders, notes, calendar events, email summaries

### 2. Task Management System
- **Local Storage**: SQLite database for offline-first experience
- **Priority System**: "חשוב" (Important), "פשוט" (Simple), "אחר כך" (Later)
- **Task Categories**: Reminders, events, notes, emails
- **Smart Scheduling**: Natural language date/time parsing in Hebrew

### 3. Google Integration
- **Calendar Sync**: Google Calendar API for event management
- **Email Automation**: Gmail API for task summaries and confirmations
- **API Key Management**: Secure local storage with encryption

### 4. ADHD-Friendly UI/UX
- **Calming Theme**: Soft purples and blues from existing theme
- **Focus Mode**: Distraction-free task capture interface
- **Gamification**: Progress tracking, completion rewards, streak counters
- **Quick Capture**: Large voice button, minimal taps required

## File Structure & Components

### Core Files (10 total)
1. **main.dart** - App entry point and routing
2. **theme.dart** - ADHD-friendly color scheme (existing)
3. **home_page.dart** - Main dashboard with voice button
4. **voice_service.dart** - Speech recognition and command processing
5. **task_model.dart** - Data models for tasks, notes, reminders
6. **database_service.dart** - Local SQLite storage management
7. **api_service.dart** - Google Calendar & Gmail API integration
8. **settings_page.dart** - API key configuration and app preferences
9. **task_list_widget.dart** - Reusable task display component
10. **completion_animation.dart** - Gamified celebration widget

### Data Models
```dart
class Task {
  String id, title, description;
  DateTime? dueDate;
  TaskPriority priority;
  TaskType type;
  bool isCompleted;
  DateTime createdAt;
}

enum TaskPriority { important, simple, later }
enum TaskType { task, reminder, note, event }
```

### Sample Hebrew Commands
- "צור משימה מחר בשלוש לכבס כביסה" → Create task tomorrow at 3pm to do laundry
- "תזכיר לי להתקשר לאמא הערב" → Remind me to call mom tonight
- "כתוב פתק: להביא מטען" → Write note: bring charger
- "קבע פגישה עם דן ביום ראשון בצהריים" → Schedule meeting with Dan on Sunday at noon

## Implementation Steps

### Phase 1: Core Structure
1. Update main.dart with Hebrew app title and routing
2. Create home page with large voice capture button
3. Implement basic task model and local storage
4. Add sample Hebrew tasks for testing

### Phase 2: Voice Integration
1. Integrate Google Speech-to-Text for Hebrew
2. Implement command parsing with OpenAI
3. Create voice service with Hebrew wake word detection
4. Add voice feedback and confirmations

### Phase 3: Smart Features
1. Build Google Calendar synchronization
2. Add Gmail API for email summaries
3. Implement intelligent date/time parsing
4. Create API key management interface

### Phase 4: ADHD Optimizations
1. Add gamification elements (streaks, rewards)
2. Implement focus mode interface
3. Create completion celebration animations
4. Add daily/weekly assistant prompts

### Phase 5: Polish & Testing
1. Optimize for web-first responsive design
2. Add error handling and offline support
3. Implement secure API key storage
4. Test with sample Hebrew commands

## Technical Constraints
- Web-first responsive design
- Offline-capable with local storage
- Secure API key management
- Hebrew text rendering support
- ADHD-friendly interaction patterns
- Maximum 10-12 files for maintainability

## Success Metrics
- Voice command accuracy in Hebrew
- Task completion rate improvement
- User engagement with gamification
- API integration reliability
- ADHD-specific usability feedback