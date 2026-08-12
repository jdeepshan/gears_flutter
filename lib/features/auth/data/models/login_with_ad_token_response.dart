class LoginWithAdTokenResponse {
  const LoginWithAdTokenResponse({
    this.accessToken,
    this.success,
    this.message,
  });

  final String? accessToken;
  final bool? success;
  final String? message;

  factory LoginWithAdTokenResponse.fromJson(Map<String, dynamic> json) {
    return LoginWithAdTokenResponse(
      accessToken: (json['accessToken'] ?? json['access_token']) as String?,
      success: json['success'] as bool?,
      message: json['message'] as String?,
    );
  }
}
