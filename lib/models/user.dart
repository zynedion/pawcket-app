class UserModel {
  final int? userId;
  final String deviceId;
  final bool hasCompletedOnboarding;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;

  UserModel({
    this.userId,
    required this.deviceId,
    required this.hasCompletedOnboarding,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'device_id': deviceId,
      'has_completed_onboarding': hasCompletedOnboarding ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['user_id'] as int?,
      deviceId: map['device_id'] as String,
      hasCompletedOnboarding: (map['has_completed_onboarding'] as int) == 1,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
      deletedAt: map['deleted_at'] as int?,
    );
  }
}
