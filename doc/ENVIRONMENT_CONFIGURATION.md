# Environment Configuration Guide

This document explains how to configure and switch between different environments (dev, QA, staging, production) in the Skillora Family mobile app.

## Overview

The app supports multiple environments through compile-time configuration. Each environment has its own API endpoint configured in `lib/core/config/app_environment.dart`.

## Available Environments

- **Development (dev)** - Default environment for local development
- **QA** - Quality Assurance testing environment
- **Staging** - Pre-production staging environment
- **Production (prod)** - Production environment

## Configuration

### Environment Endpoints

All environment endpoints are configured in `lib/core/config/app_environment.dart`. Currently configured:

- **Dev**: `https://8f4ayhaoee.execute-api.eu-north-1.amazonaws.com/dev`

To add other environments, update the corresponding constants in `app_environment.dart`:

```dart
static const EnvironmentConfig qa = EnvironmentConfig(
  environment: AppEnvironment.qa,
  apiBaseUrl: 'https://your-qa-api-id.execute-api.your-region.amazonaws.com/qa',
  name: 'QA',
);
```

## Running the App with Different Environments

### Development (Default)

```bash
# Default behavior - uses dev environment
flutter run

# Or explicitly
flutter run --dart-define=ENV=dev
```

### QA Environment

```bash
flutter run --dart-define=ENV=qa
```

### Staging Environment

```bash
flutter run --dart-define=ENV=staging
```

### Production Environment

```bash
flutter run --dart-define=ENV=production
```

## Building for Different Environments

### Android APK

```bash
# Development
flutter build apk --dart-define=ENV=dev

# QA
flutter build apk --dart-define=ENV=qa

# Staging
flutter build apk --dart-define=ENV=staging

# Production
flutter build apk --dart-define=ENV=production
```

### Android App Bundle

```bash
# Production build
flutter build appbundle --dart-define=ENV=production
```

### iOS

```bash
# Development
flutter build ios --dart-define=ENV=dev

# Production
flutter build ios --dart-define=ENV=production
```

## IDE Configuration

### VS Code

Add to `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter (Dev)",
      "request": "launch",
      "type": "dart",
      "args": ["--dart-define=ENV=dev"]
    },
    {
      "name": "Flutter (QA)",
      "request": "launch",
      "type": "dart",
      "args": ["--dart-define=ENV=qa"]
    },
    {
      "name": "Flutter (Staging)",
      "request": "launch",
      "type": "dart",
      "args": ["--dart-define=ENV=staging"]
    },
    {
      "name": "Flutter (Production)",
      "request": "launch",
      "type": "dart",
      "args": ["--dart-define=ENV=production"]
    }
  ]
}
```

### Android Studio

1. Go to **Run** > **Edit Configurations**
2. Add a new Flutter configuration
3. In **Additional run args**, add: `--dart-define=ENV=production`
4. Repeat for other environments

## Verifying Current Environment

When running in debug mode, the app logs the current environment on startup:

```
🚀 Starting Skillora Family App
📍 Environment: Development
🔗 API Base URL: https://8f4ayhaoee.execute-api.eu-north-1.amazonaws.com/dev
```

## Code Usage

In your code, you can access the current environment:

```dart
import 'package:skillora_family/core/config/api_config.dart';

// Get current base URL
final baseUrl = ApiConfig.baseUrl;

// Check environment
if (ApiConfig.isDevelopment) {
  // Development-specific code
}

if (ApiConfig.isProduction) {
  // Production-specific code
}

// Get environment name
final envName = ApiConfig.environmentName;
```

## CI/CD Integration

### GitHub Actions Example

```yaml
- name: Build APK for Production
  run: flutter build apk --release --dart-define=ENV=production
```

### GitLab CI Example

```yaml
build_production:
  script:
    - flutter build apk --release --dart-define=ENV=production
```

## Troubleshooting

### Environment Not Changing

- Ensure you're using `--dart-define=ENV=<environment>` (not `--dart-define-from-file`)
- Check that the environment name matches exactly (case-insensitive): `dev`, `qa`, `staging`, `production`
- After changing environment, do a full rebuild: `flutter clean && flutter pub get`

### API Endpoint Not Working

- Verify the endpoint is correctly configured in `app_environment.dart`
- Check that the environment constant is updated (not using placeholder values)
- Ensure the API endpoint is accessible from your network

## Security Notes

- ⚠️ **Never commit production API keys or sensitive data** to version control
- Use environment variables or secure configuration management for production
- Consider using a secrets management service for production deployments
- The current configuration uses compile-time constants, which are visible in the app binary

## Future Improvements

- [ ] Support for runtime environment switching (for testing)
- [ ] Environment-specific feature flags
- [ ] Environment-specific API keys/authentication
- [ ] Support for `.env` files via `flutter_dotenv`
- [ ] Build flavors for Android/iOS with environment-specific configurations

