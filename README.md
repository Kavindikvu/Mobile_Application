# Skillora Family (Mobile)

> A companion mobile application for parents and students, designed to align with the Skillora design system and share backend contracts with the teacher app.

[![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.4+-0175C2?logo=dart)](https://dart.dev/)
[![License](https://img.shields.io/badge/license-Proprietary-red)](LICENSE)

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Screenshots](#screenshots)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Project Structure](#project-structure)
- [Architecture](#architecture)
- [Running the App](#running-the-app)
- [Testing](#testing)
- [Building for Production](#building-for-production)
- [API Integration](#api-integration)
- [Localization](#localization)
- [Contributing](#contributing)
- [Troubleshooting](#troubleshooting)
- [License](#license)
- [Support](#support)

## 🎯 Overview

**Skillora Family** is a Flutter-based mobile application that serves as the companion app for parents and students in the Skillora ecosystem. It provides a seamless experience for discovering classes, managing assignments, tracking progress, communicating with instructors, and handling payments.

### Key Highlights

- **Role-Based Access**: Supports both Parent and Student roles with appropriate feature sets
- **Multi-Child Support**: Parents can switch between multiple children's profiles seamlessly
- **Offline-First**: Currently runs with mock data from asset files for development
- **Modern UI**: Built with Material Design 3, supporting light and dark themes
- **Internationalization Ready**: Localization support with ARB files
- **Clean Architecture**: Well-structured codebase following separation of concerns

## ✨ Features

### Core Modules

- **🏠 Home Dashboard**: Role-aware overview with recent activity, quick actions, and statistics
- **🔍 Discover**: Browse and search classes, filter by subject, location, and instructor
- **📚 Assignments**: View assignments, submit work, and track grades
- **💬 Messages**: Communication hub with instructors and peers
- **👤 Profile**: User profile management with role/child switching
- **💰 Payments**: Payment history, invoices, and payment management (Parent-only)
- **📅 Calendar**: View schedules and upcoming events
- **📊 Activity**: Activity dashboard and progress tracking
- **🔔 Notifications**: Push notifications and in-app notification center
- **🎓 Onboarding**: Student and parent onboarding flows
- **🏪 Marketplace**: Browse marketplace listings (stub)
- **📈 Attendance**: Attendance tracking (stub)

### Authentication

- Email/Password authentication
- Google Sign-In integration
- Session management
- Role-based access control

### User Experience

- Material Design 3 components
- Light and Dark theme support
- Empty, loading, and error states
- Responsive design for various screen sizes
- Accessibility support (WCAG AA minimum)

## 📱 Screenshots

> _Screenshots will be added here_

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK**: Version 3.24 or higher
  ```bash
  flutter --version
  ```
- **Dart SDK**: Version 3.4.0 or higher (included with Flutter)
- **Android Studio** or **VS Code** with Flutter extensions
- **Xcode** (for iOS development on macOS)
- **Android SDK** (for Android development)
- **Git** for version control

### Platform-Specific Requirements

#### Android
- Android Studio with Android SDK
- Minimum SDK: As defined in `android/app/build.gradle.kts`
- Target SDK: As defined in `android/app/build.gradle.kts`

#### iOS
- macOS with Xcode installed
- iOS 13.0 or higher
- CocoaPods (usually installed automatically)

## 🚀 Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd skillora-family-mobile
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code (if needed)**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Verify installation**
   ```bash
   flutter doctor
   ```

## ⚙️ Configuration

### Google Sign-In Setup

#### Android
1. Create a project in [Google Cloud Console](https://console.cloud.google.com/)
2. Enable Google Sign-In API
3. Create OAuth 2.0 credentials (Android client)
4. Add your package name and SHA-1 certificate fingerprint
5. Download `google-services.json` and place it in `android/app/`

#### iOS
1. In the same Google Cloud project, create iOS OAuth 2.0 credentials
2. Add your bundle identifier
3. Download `GoogleService-Info.plist` and add it to `ios/Runner/`
4. Update `ios/Runner/Info.plist` with the REVERSED_CLIENT_ID

### Environment Configuration

Currently, the app uses mock data from `assets/data/` directory. To connect to the backend:

1. Create an environment configuration file (e.g., `.env` or config file)
2. Update repository implementations to use HTTP client instead of `AssetDataProvider`
3. Configure API endpoints (see [API Integration](#api-integration))

### App Configuration

- **Package Name**: `com.roollout.skillora` (Android)
- **Bundle Identifier**: `com.example.skilloraFamily` (iOS)
- **Version**: `0.1.0+1`

## 📁 Project Structure

```
skillora-family-mobile/
├── android/                  # Android-specific files
│   ├── app/
│   │   ├── build.gradle.kts
│   │   └── src/
│   ├── build.gradle.kts
│   └── settings.gradle.kts
├── ios/                      # iOS-specific files
│   ├── Runner/
│   │   ├── Info.plist
│   │   └── AppDelegate.swift
│   └── Runner.xcodeproj/
├── lib/                      # Main application code
│   ├── core/                 # Core functionality
│   │   ├── data/            # Data providers (currently AssetDataProvider)
│   │   ├── domain/          # Domain models and entities
│   │   ├── providers/       # Riverpod providers
│   │   ├── router/          # Navigation (GoRouter)
│   │   ├── theme/           # App themes and design tokens
│   │   ├── ui/              # Shared UI components
│   │   └── widgets/         # Reusable widgets
│   ├── features/            # Feature modules
│   │   ├── activity/        # Activity dashboard
│   │   ├── assignments/     # Assignment management
│   │   ├── attendance/      # Attendance tracking (stub)
│   │   ├── auth/            # Authentication
│   │   ├── calendar/        # Calendar and schedules
│   │   ├── discover/        # Class discovery
│   │   ├── enhanced_discover/ # Enhanced discovery features
│   │   ├── home/            # Home dashboard
│   │   ├── marketplace/     # Marketplace (stub)
│   │   ├── messages/        # Messaging
│   │   ├── notifications/   # Notifications
│   │   ├── onboarding/      # Onboarding flows
│   │   ├── payments/        # Payment management
│   │   └── profile/         # User profile
│   ├── l10n/                # Localization files
│   │   └── app_en.arb       # English strings
│   └── main.dart            # App entry point
├── assets/                  # Assets directory
│   ├── data/               # Mock JSON data files
│   └── images/             # Image assets
├── test/                   # Test files
│   ├── router_test.dart
│   └── widget_test.dart
├── doc/                    # Documentation
│   ├── *.postman_collection.json  # API documentation
│   └── UX_Design_Skillora_Family_Mobile_App.md
├── pubspec.yaml            # Dependencies and configuration
├── analysis_options.yaml   # Linting rules
├── l10n.yaml              # Localization configuration
└── README.md              # This file
```

### Feature Structure

Each feature module follows a consistent structure:
```
feature_name/
├── data/
│   └── feature_repository.dart    # Data layer
├── domain/
│   └── feature_model.dart         # Domain models (if feature-specific)
├── presentation/
│   └── feature_screen.dart        # UI layer
└── providers/
    └── feature_provider.dart      # State management
```

## 🏗️ Architecture

The application follows **Clean Architecture** principles with a clear separation of concerns:

### Layers

1. **Presentation Layer** (`features/*/presentation/`)
   - UI components and screens
   - Widgets and user interactions
   - Riverpod consumers

2. **Domain Layer** (`core/domain/`, `features/*/domain/`)
   - Business logic
   - Domain models
   - Use cases

3. **Data Layer** (`core/data/`, `features/*/data/`)
   - Repositories
   - Data sources (currently AssetDataProvider, will be replaced with HTTP client)
   - Data models and mapping

### State Management

- **Riverpod**: Used for state management throughout the app
- **StateNotifier**: For complex state logic (e.g., `AuthNotifier`)
- **Provider**: For dependency injection and simple state

### Navigation

- **GoRouter**: Declarative routing with deep linking support
- **StatefulShellRoute**: For bottom navigation with preserved state
- Route guards for authentication

### Dependency Injection

- Riverpod providers handle all dependency injection
- Repositories are provided via providers
- Easy to swap implementations (e.g., mock data → real API)

## 🏃 Running the App

### Development Mode

1. **Check connected devices**
   ```bash
   flutter devices
   ```

2. **Run the app**
   ```bash
   flutter run
   ```

3. **Run on specific device**
   ```bash
   flutter run -d <device-id>
   ```

4. **Enable hot reload**
   - Press `r` in the terminal, or
   - Use your IDE's hot reload button

### Running on Specific Platforms

#### Android
```bash
flutter run -d android
```

#### iOS
```bash
flutter run -d ios
```

### Build Modes

- **Debug**: Development mode with hot reload
  ```bash
  flutter run --debug
  ```

- **Profile**: Performance profiling mode
  ```bash
  flutter run --profile
  ```

- **Release**: Production mode
  ```bash
  flutter run --release
  ```

## 🧪 Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart
```

### Test Structure

- **Unit Tests**: Test individual functions and classes
- **Widget Tests**: Test UI components in isolation
- **Integration Tests**: Test complete user flows (to be added)

### Current Test Coverage

- ✅ App initialization test
- ✅ Router navigation test
- ⏳ Additional tests (in progress)

## 📦 Building for Production

### Android

1. **Generate a signed APK**
   ```bash
   flutter build apk --release
   ```

2. **Generate a signed App Bundle** (for Play Store)
   ```bash
   flutter build appbundle --release
   ```

3. **Configure signing**
   - Update `android/app/build.gradle.kts` with your signing configuration
   - See [Flutter's signing guide](https://docs.flutter.dev/deployment/android#signing-the-app)

### iOS

1. **Build for release**
   ```bash
   flutter build ios --release
   ```

2. **Open in Xcode for distribution**
   ```bash
   open ios/Runner.xcworkspace
   ```

3. **Archive and upload**
   - Use Xcode's Archive feature
   - Upload to App Store Connect

## 🔌 API Integration

### Backend Services

The app integrates with multiple backend services (Spring Boot applications deployed on AWS Lambda):

- **User Service**: User management and authentication
- **Class Service**: Class and schedule management
- **Student Service**: Student profile management
- **Enrollment Service**: Enrollment management
- **Subject Service**: Subject management
- **Notification Service**: Push notifications and in-app notifications

### API Documentation

Postman collections are available in the `doc/` directory:
- `user-service.postman_collection.json`
- `class-service.postman_collection.json`
- `student-service.postman_collection.json`
- `enrollment-service.postman_collection.json`
- `subject-service.postman_collection.json`
- `notification-service.postman_collection.json`

### Base URL Format

```
https://{{api-id}}.execute-api.{{region}}.amazonaws.com/{{env}}
```

### Switching from Mock Data to Backend

1. **Update Repository Implementations**
   - Replace `AssetDataProvider` calls with HTTP client calls
   - Implement proper error handling and retry logic
   - Add authentication headers

2. **Configure API Endpoints**
   - Create a configuration file for environment-specific endpoints
   - Use environment variables or config files

3. **Update Providers**
   - Modify Riverpod providers to handle API responses
   - Add loading and error states

Example migration:
```dart
// Before (mock data)
final data = await _assetDataProvider.loadMap('assets/data/user.json');

// After (backend API)
final response = await _httpClient.get('/user-service/users/$userId');
final data = jsonDecode(response.body);
```

## 🌐 Localization

### Supported Locales

- English (`en`) - Currently supported
- Additional locales can be added

### Adding Localizations

1. **Create ARB file**
   ```bash
   lib/l10n/app_<locale>.arb
   ```

2. **Add strings**
   ```json
   {
     "@appTitle": {},
     "appTitle": "Skillora Family"
   }
   ```

3. **Generate localizations**
   ```bash
   flutter gen-l10n
   ```

4. **Update `AppL10n.supportedLocales`** in `lib/l10n/l10n.dart`

### Using Localizations

```dart
import 'package:skillora_family/l10n/l10n.dart';

Text(AppL10n.of(context).appTitle)
```

## 🤝 Contributing

### Development Workflow

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Follow the existing code style
   - Write tests for new features
   - Update documentation as needed

3. **Run checks**
   ```bash
   flutter analyze
   flutter test
   ```

4. **Commit your changes**
   ```bash
   git commit -m "Add: description of changes"
   ```

5. **Push and create a pull request**

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter_lints` rules (configured in `analysis_options.yaml`)
- Format code with `dart format`

### Commit Messages

Follow conventional commits format:
- `Add:` New features
- `Fix:` Bug fixes
- `Update:` Updates to existing features
- `Refactor:` Code refactoring
- `Docs:` Documentation changes

## 🐛 Troubleshooting

### Common Issues

#### Flutter Doctor Issues
```bash
flutter doctor -v
```
Follow the suggestions to resolve missing dependencies.

#### Build Failures

**Android:**
- Clean build: `flutter clean && flutter pub get`
- Invalidate caches in Android Studio
- Check `local.properties` has correct SDK path

**iOS:**
- Clean build: `flutter clean && flutter pub get`
- Run `pod install` in `ios/` directory
- Clean derived data in Xcode

#### Google Sign-In Not Working
- Verify `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is in place
- Check OAuth credentials are correctly configured
- Verify SHA-1 fingerprint (Android) or bundle ID (iOS) matches Google Console

#### Hot Reload Not Working
- Restart the app: Press `R` in terminal or use restart button
- Sometimes a full rebuild is needed: `flutter run`

### Getting Help

- Check [Flutter Documentation](https://docs.flutter.dev/)
- Review existing issues in the repository
- Contact the development team (see [Support](#support))

## 📄 License

This project is proprietary software. All rights reserved.

## 📞 Support

For support, questions, or issues:

- **Email**: [Add support email]
- **Issues**: [Add issues URL or email]
- **Documentation**: See `doc/` directory for additional documentation

## 🔄 Version History

- **0.1.0+1** - Initial release
  - Core features implemented
  - Mock data support
  - Basic authentication
  - MVP features

## 📚 Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [Material Design 3](https://m3.material.io/)

## 🎯 Roadmap

- [ ] Complete backend API integration
- [ ] Expand test coverage
- [ ] Add more localization languages
- [ ] Implement push notifications
- [ ] Add analytics
- [ ] Performance optimizations
- [ ] Accessibility improvements
- [ ] Marketplace feature completion
- [ ] Attendance feature completion

---

**Note**: This application currently runs with mock data from asset files. To connect to the backend, follow the instructions in the [API Integration](#api-integration) section.
