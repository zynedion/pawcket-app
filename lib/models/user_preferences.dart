class UserPreferencesModel {
  final int? preferenceId;
  final int userId;
  final String currencyCode;
  final bool enableVoiceInput;
  final bool enableCloudSync;
  final bool enableNotifications;
  final String themeMode;
  final bool showTutorial;
  final bool requirePinUnlock;
  final bool requireBiometric;
  final int createdAt;
  final int updatedAt;

  UserPreferencesModel({
    this.preferenceId,
    required this.userId,
    this.currencyCode = 'IDR',
    required this.enableVoiceInput,
    required this.enableCloudSync,
    required this.enableNotifications,
    this.themeMode = 'light',
    this.showTutorial = true,
    this.requirePinUnlock = false,
    this.requireBiometric = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'preference_id': preferenceId,
      'user_id': userId,
      'currency_code': currencyCode,
      'enable_voice_input': enableVoiceInput ? 1 : 0,
      'enable_cloud_sync': enableCloudSync ? 1 : 0,
      'enable_notifications': enableNotifications ? 1 : 0,
      'theme_mode': themeMode,
      'show_tutorial': showTutorial ? 1 : 0,
      'require_pin_unlock': requirePinUnlock ? 1 : 0,
      'require_biometric': requireBiometric ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory UserPreferencesModel.fromMap(Map<String, dynamic> map) {
    return UserPreferencesModel(
      preferenceId: map['preference_id'] as int?,
      userId: map['user_id'] as int,
      currencyCode: map['currency_code'] as String? ?? 'IDR',
      enableVoiceInput: (map['enable_voice_input'] as int? ?? 1) == 1,
      enableCloudSync: (map['enable_cloud_sync'] as int? ?? 0) == 1,
      enableNotifications: (map['enable_notifications'] as int? ?? 1) == 1,
      themeMode: map['theme_mode'] as String? ?? 'light',
      showTutorial: (map['show_tutorial'] as int? ?? 1) == 1,
      requirePinUnlock: (map['require_pin_unlock'] as int? ?? 0) == 1,
      requireBiometric: (map['require_biometric'] as int? ?? 0) == 1,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  UserPreferencesModel copyWith({
    int? preferenceId,
    int? userId,
    String? currencyCode,
    bool? enableVoiceInput,
    bool? enableCloudSync,
    bool? enableNotifications,
    String? themeMode,
    bool? showTutorial,
    bool? requirePinUnlock,
    bool? requireBiometric,
    int? createdAt,
    int? updatedAt,
  }) {
    return UserPreferencesModel(
      preferenceId: preferenceId ?? this.preferenceId,
      userId: userId ?? this.userId,
      currencyCode: currencyCode ?? this.currencyCode,
      enableVoiceInput: enableVoiceInput ?? this.enableVoiceInput,
      enableCloudSync: enableCloudSync ?? this.enableCloudSync,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      themeMode: themeMode ?? this.themeMode,
      showTutorial: showTutorial ?? this.showTutorial,
      requirePinUnlock: requirePinUnlock ?? this.requirePinUnlock,
      requireBiometric: requireBiometric ?? this.requireBiometric,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
