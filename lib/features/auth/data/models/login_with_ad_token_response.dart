class LoginWithAdTokenResponse {
  const LoginWithAdTokenResponse({this.accessToken});

  final String? accessToken;

  factory LoginWithAdTokenResponse.fromJson(Map<String, dynamic> json) {
    return LoginWithAdTokenResponse(
      accessToken: json['accessToken'] as String?,
    );
  }
}
