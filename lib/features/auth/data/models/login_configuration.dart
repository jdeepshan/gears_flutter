class LoginConfiguration {
  const LoginConfiguration({
    this.url,
    this.realm,
    this.clientId,
  });

  final String? url;
  final String? realm;
  final String? clientId;

  factory LoginConfiguration.fromJson(Map<String, dynamic> json) {
    return LoginConfiguration(
      url: json['url'] as String?,
      realm: json['realm'] as String?,
      clientId: json['clientId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'realm': realm,
        'clientId': clientId,
      };
}
