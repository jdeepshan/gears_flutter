class ProfileDetailsStdResponse {
  const ProfileDetailsStdResponse({
    this.data,
    this.message,
    this.success,
  });

  final ProfileDetailsStdData? data;
  final String? message;
  final bool? success;

  factory ProfileDetailsStdResponse.fromJson(Map<String, dynamic> json) {
    return ProfileDetailsStdResponse(
      data: json['data'] == null
          ? null
          : ProfileDetailsStdData.fromJson(json['data'] as Map<String, dynamic>),
      message: json['message'] as String?,
      success: json['success'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data?.toJson(),
      'message': message,
      'success': success,
    };
  }
}

class ProfileDetailsStdData {
  const ProfileDetailsStdData({this.employee});

  final ProfileEmployee? employee;

  factory ProfileDetailsStdData.fromJson(Map<String, dynamic> json) {
    return ProfileDetailsStdData(
      employee: json['employee'] == null
          ? null
          : ProfileEmployee.fromJson(json['employee'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {'employee': employee?.toJson()};
  }
}

class ProfileEmployee {
  const ProfileEmployee({
    this.company,
    this.eCode,
    this.eDOJ,
    this.eEmail,
    this.empImageUrl,
    this.ename1,
    this.ecMobile,
    this.epTelephone,
  });

  final ProfileCompany? company;
  final String? eCode;
  final String? eDOJ;
  final String? eEmail;
  final String? empImageUrl;
  final String? ename1;
  final String? ecMobile;
  final String? epTelephone;

  factory ProfileEmployee.fromJson(Map<String, dynamic> json) {
    return ProfileEmployee(
      company: json['company'] == null
          ? null
          : ProfileCompany.fromJson(json['company'] as Map<String, dynamic>),
      eCode: json['ECode'] as String?,
      eDOJ: json['EDOJ'] as String?,
      eEmail: json['EEmail'] as String?,
      empImageUrl: json['emp_image_url'] as String?,
      ename1: json['Ename1'] as String?,
      ecMobile: _stringValue(json['EcMobile']),
      epTelephone: json['EpTelephone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company': company?.toJson(),
      'ECode': eCode,
      'EDOJ': eDOJ,
      'EEmail': eEmail,
      'emp_image_url': empImageUrl,
      'Ename1': ename1,
      'EcMobile': ecMobile,
      'EpTelephone': epTelephone,
    };
  }
}

class ProfileCompany {
  const ProfileCompany({this.companyId, this.companyName});

  final int? companyId;
  final String? companyName;

  factory ProfileCompany.fromJson(Map<String, dynamic> json) {
    return ProfileCompany(
      companyId: json['company_id'] as int?,
      companyName: json['company_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company_id': companyId,
      'company_name': companyName,
    };
  }
}

String? _stringValue(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}
