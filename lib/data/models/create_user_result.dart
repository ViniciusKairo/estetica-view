class CreateUserResult {
  final bool success;
  final String userId;
  final String role;
  final bool invite;
  final String? code;
  final String? message;
  final dynamic details;

  const CreateUserResult({
    required this.success,
    required this.userId,
    required this.role,
    required this.invite,
    this.code,
    this.message,
    this.details,
  });

  factory CreateUserResult.fromMap(Map<String, dynamic> data) {
    return CreateUserResult(
      success: data['success'] as bool? ?? true,
      userId: (data['user_id'] ?? '') as String,
      role: (data['role'] ?? '') as String,
      invite: data['invite'] as bool? ?? false,
      code: data['code'] as String?,
      message: data['message'] as String?,
      details: data['details'],
    );
  }
}