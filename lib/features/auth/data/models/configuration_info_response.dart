import 'package:gears_flutter/features/auth/data/models/login_configuration.dart';

class ConfigurationData {
  const ConfigurationData({
    this.environment,
    this.version,
    this.pathAD,
    this.isAzure,
    this.isLang,
    this.passwordReset,
    this.loginType,
    this.customRoute,
    this.loginConfiguration,
    this.serverTime,
    this.reqVrfyTkn,
    this.forgotPasswordEnable,
  });

  final String? environment;
  final String? version;
  final String? pathAD;
  final int? isAzure;
  final String? isLang;
  final bool? passwordReset;
  final List<int>? loginType;
  final bool? customRoute;
  final LoginConfiguration? loginConfiguration;
  final int? serverTime;
  final bool? reqVrfyTkn;
  final bool? forgotPasswordEnable;

  int? get primaryLoginType =>
      loginType != null && loginType!.isNotEmpty ? loginType!.first : null;

  bool get isKeycloakLogin => loginType?.contains(4) ?? false;

  factory ConfigurationData.fromJson(Map<String, dynamic> json) {
    return ConfigurationData(
      environment: json['environment'] as String?,
      version: json['version']?.toString(),
      pathAD: json['pathAD'] as String?,
      isAzure: json['isAzure'] as int?,
      isLang: json['isLang']?.toString(),
      passwordReset: json['passwordReset'] as bool?,
      loginType: _parseLoginType(json['loginType']),
      customRoute: json['customRoute'] as bool?,
      loginConfiguration: _parseLoginConfiguration(json['loginConfiguration']),
      serverTime: json['serverTime'] as int?,
      reqVrfyTkn: json['reqVrfyTkn'] as bool?,
      forgotPasswordEnable: json['forgotPasswordEnable'] as bool?,
    );
  }

  static List<int>? _parseLoginType(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => (e as num).toInt()).toList();
    }
    if (value is num) {
      return [value.toInt()];
    }
    return null;
  }

  static LoginConfiguration? _parseLoginConfiguration(dynamic value) {
    if (value == null || value is! Map<String, dynamic> || value.isEmpty) {
      return null;
    }

    final config = LoginConfiguration.fromJson(value);
    if (config.url == null && config.realm == null && config.clientId == null) {
      return null;
    }

    return config;
  }
}

class ConfigurationInfoResponse {
  const ConfigurationInfoResponse({
    this.success,
    this.data,
    this.message,
  });

  final bool? success;
  final ConfigurationData? data;
  final String? message;

  factory ConfigurationInfoResponse.fromJson(Map<String, dynamic> json) {
    return ConfigurationInfoResponse(
      success: json['success'] as bool?,
      data: json['data'] == null
          ? null
          : ConfigurationData.fromJson(json['data'] as Map<String, dynamic>),
      message: json['message'] as String?,
    );
  }
}
