import 'app_environment.dart';

/// API Configuration
/// 
/// Automatically uses the correct API endpoint based on the current environment.
/// 
/// Environments are configured in app_environment.dart and can be switched using:
///   - Development: Default or --dart-define=ENV=dev
///   - QA: --dart-define=ENV=qa
///   - Staging: --dart-define=ENV=staging
///   - Production: --dart-define=ENV=production
/// 
/// Example usage:
///   flutter run --dart-define=ENV=production
class ApiConfig {
  /// Gets the current environment configuration
  static EnvironmentConfig get _env => EnvironmentConfig.current;
  
  /// Base URL for the API (automatically set based on environment)
  static String get baseUrl => _env.apiBaseUrl;
  
  /// Current environment name (for debugging/logging)
  static String get environmentName => _env.name;
  
  /// Service paths
  static const String classServicePath = '/class-service';
  static const String subjectServicePath = '/subject-service';
  static const String userServicePath = '/user-service';
  static const String enrollmentServicePath = '/enrollment-service';
  static const String studentServicePath = '/student-service';
  
  /// Full service URLs
  static String get classServiceBaseUrl => '$baseUrl$classServicePath';
  static String get subjectServiceBaseUrl => '$baseUrl$subjectServicePath';
  static String get userServiceBaseUrl => '$baseUrl$userServicePath';
  static String get enrollmentServiceBaseUrl => '$baseUrl$enrollmentServicePath';
  static String get studentServiceBaseUrl => '$baseUrl$studentServicePath';
  
  /// Validates that the base URL has been configured (not using placeholder values)
  static bool get isConfigured {
    return !baseUrl.contains('{{') && 
           !baseUrl.contains('your-api-id') && 
           !baseUrl.contains('your-region') &&
           !baseUrl.contains('your-env') &&
           !baseUrl.contains('your-qa-api-id') &&
           !baseUrl.contains('your-staging-api-id') &&
           !baseUrl.contains('your-production-api-id');
  }
  
  /// Check if running in development mode
  static bool get isDevelopment => _env.isDevelopment;
  
  /// Check if running in production mode
  static bool get isProduction => _env.isProduction;
}

