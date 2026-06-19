class HrmsApprovalsStdResponse {
  const HrmsApprovalsStdResponse({
    this.data,
    this.message,
    this.success,
  });

  final List<HrmsApprovalDatum>? data;
  final String? message;
  final bool? success;

  factory HrmsApprovalsStdResponse.fromJson(Map<String, dynamic> json) {
    return HrmsApprovalsStdResponse(
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => HrmsApprovalDatum.fromJson(e as Map<String, dynamic>))
          .toList(),
      message: json['message'] as String?,
      success: json['success'] as bool?,
    );
  }
}

class HrmsApprovalDatum {
  const HrmsApprovalDatum({
    this.amount,
    this.approvalLevel,
    this.companyCode,
    this.companyName,
    this.confirmedDate,
    this.currencyCode,
    this.docAutoID,
    this.docCode,
    this.documentID,
    this.narration,
  });

  final String? amount;
  final int? approvalLevel;
  final String? companyCode;
  final String? companyName;
  final String? confirmedDate;
  final String? currencyCode;
  final int? docAutoID;
  final String? docCode;
  final String? documentID;
  final String? narration;

  factory HrmsApprovalDatum.fromJson(Map<String, dynamic> json) {
    return HrmsApprovalDatum(
      amount: json['amount']?.toString(),
      approvalLevel: json['approvalLevel'] as int?,
      companyCode: json['company_code'] as String?,
      companyName: json['company_name'] as String?,
      confirmedDate: json['confirmedDate'] as String?,
      currencyCode: json['currencyCode'] as String?,
      docAutoID: json['docAutoID'] as int?,
      docCode: json['docCode'] as String?,
      documentID: json['documentID'] as String?,
      narration: json['narration'] as String?,
    );
  }

  String get documentDescription {
    switch (documentID) {
      case 'EC':
        return 'Expense Claim';
      case 'LA':
        return 'Leave Application';
      default:
        return 'Other';
    }
  }

  String? get displayAmount {
    if (documentID == 'LA') return null;
    if (documentID == 'EC') {
      final code = currencyCode ?? '';
      final value = amount ?? '';
      if (code.isEmpty && value.isEmpty) return null;
      return '$code $value'.trim();
    }
    return null;
  }
}
