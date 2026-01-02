/// Application environment configuration
/// 
/// Supports multiple environments: dev, qa, staging, production
/// 
/// Usage:
///   - Development: Default or --dart-define=ENV=dev
///   - QA: --dart-define=ENV=qa
///   - Staging: --dart-define=ENV=staging  
///   - Production: --dart-define=ENV=production
enum AppEnvironment {
  dev,
  qa,
  staging,
  production,
}

/// Environment configuration with API endpoints
class EnvironmentConfig {
  final AppEnvironment environment;
  final String apiBaseUrl;
  final String name;

  const EnvironmentConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.name,
  });

  static EnvironmentConfig get current {
    // Get environment from compile-time constant or default to dev
    const envString = String.fromEnvironment('ENV', defaultValue: 'dev');
    
    switch (envString.toLowerCase()) {
      case 'qa':
        return EnvironmentConfig.qa;
      case 'staging':
      case 'stage':
        return EnvironmentConfig.staging;
      case 'production':
      case 'prod':
        return EnvironmentConfig.production;
      case 'dev':
      case 'development':
      default:
        return EnvironmentConfig.dev;
    }
  }

  // Development environment
  static const EnvironmentConfig dev = EnvironmentConfig(
    environment: AppEnvironment.dev,
    apiBaseUrl: 'https://8f4ayhaoee.execute-api.eu-north-1.amazonaws.com/dev',
    name: 'Development',
  );

  // QA environment
  // TODO: Update with actual QA API endpoint when available
  static const EnvironmentConfig qa = EnvironmentConfig(
    environment: AppEnvironment.qa,
    apiBaseUrl: 'https://your-qa-api-id.execute-api.your-region.amazonaws.com/qa',
    name: 'QA',
  );

  // Staging environment
  // TODO: Update with actual Staging API endpoint when available
  static const EnvironmentConfig staging = EnvironmentConfig(
    environment: AppEnvironment.staging,
    apiBaseUrl: 'https://your-staging-api-id.execute-api.your-region.amazonaws.com/staging',
    name: 'Staging',
  );

  // Production environment
  // TODO: Update with actual Production API endpoint when available
  static const EnvironmentConfig production = EnvironmentConfig(
    environment: AppEnvironment.production,
    apiBaseUrl: 'https://your-production-api-id.execute-api.your-region.amazonaws.com/prod',
    name: 'Production',
  );

  bool get isDevelopment => environment == AppEnvironment.dev;
  bool get isProduction => environment == AppEnvironment.production;
}

