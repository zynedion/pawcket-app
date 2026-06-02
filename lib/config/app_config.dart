// AppConfig holds environment variables and feature flags

class AppConfig {
  static const String databaseName = 'pawcket_local.db';
  
  // Feature flags
  static const bool enableCloudSync = false;
  static const bool enableVoiceInput = true;
  static const bool enableNotifications = true;
  static const bool requirePinUnlock = false;
  static const bool requireBiometric = false;
}
