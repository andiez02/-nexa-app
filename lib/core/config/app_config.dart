/// App configuration
class AppConfig {
  // Environment
  static const String environment = String.fromEnvironment('ENV', defaultValue: 'dev');
  
  // API Configuration
  static const String baseUrl = String.fromEnvironment('BASE_URL', defaultValue: 'https://api.nexa.io');
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // Feature Flags
  static const bool enableAnalytics = bool.fromEnvironment('ENABLE_ANALYTICS', defaultValue: false);
  static const bool enableCrashlytics = bool.fromEnvironment('ENABLE_CRASHLYTICS', defaultValue: false);
  
  // App Configuration
  static const String appName = 'Nexa';
  static const String packageName = 'com.nexa.app';
  
  // Web3 Configuration
  static const String defaultChainId = '1'; // Ethereum mainnet
  static const String infuraProjectId = String.fromEnvironment('INFURA_PROJECT_ID', defaultValue: '');
  
  // Storage Configuration
  static const String storagePrefix = 'nexa_';
  
  // Private constructor
  AppConfig._();
}
