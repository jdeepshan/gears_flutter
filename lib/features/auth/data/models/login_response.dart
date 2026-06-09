class LoginResponse {
  const LoginResponse({
    this.tokenType,
    this.expiresIn,
    this.accessToken,
    this.refreshToken,
    this.success,
  });

  final String? tokenType;
  final int? expiresIn;
  final String? accessToken;
  final String? refreshToken;
  final bool? success;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      tokenType: json['token_type'] as String?,
      expiresIn: (json['expires_in'] as num?)?.toInt(),
      accessToken: json['access_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      success: json['success'] as bool?,
    );
  }
}
