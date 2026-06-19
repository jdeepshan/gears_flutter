class ClaimStdDetailsResponse {
  const ClaimStdDetailsResponse({
    this.data,
    this.message,
    this.success,
  });

  final ClaimStdDetailsData? data;
  final String? message;
  final bool? success;

  factory ClaimStdDetailsResponse.fromJson(Map<String, dynamic> json) {
    return ClaimStdDetailsResponse(
      data: json['data'] == null
          ? null
          : ClaimStdDetailsData.fromJson(json['data'] as Map<String, dynamic>),
      message: json['message'] as String?,
      success: json['success'] as bool?,
    );
  }
}

class ClaimStdDetailsData {
  const ClaimStdDetailsData({
    this.details,
    this.detTot,
    this.masterData,
  });

  final List<ClaimStdDetail>? details;
  final String? detTot;
  final ClaimStdMasterData? masterData;

  factory ClaimStdDetailsData.fromJson(Map<String, dynamic> json) {
    return ClaimStdDetailsData(
      details: (json['details'] as List<dynamic>?)
          ?.map((e) => ClaimStdDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
      detTot: json['det_tot']?.toString(),
      masterData: json['masterData'] == null
          ? null
          : ClaimStdMasterData.fromJson(
              json['masterData'] as Map<String, dynamic>,
            ),
    );
  }
}

class ClaimStdMasterData {
  const ClaimStdMasterData({
    this.claimBy,
    this.claimedByEmpCode,
    this.claimedByEmpName,
    this.comments,
    this.confirmedDate,
  });

  final ClaimBy? claimBy;
  final String? claimedByEmpCode;
  final String? claimedByEmpName;
  final String? comments;
  final String? confirmedDate;

  factory ClaimStdMasterData.fromJson(Map<String, dynamic> json) {
    return ClaimStdMasterData(
      claimBy: json['claim_by'] == null
          ? null
          : ClaimBy.fromJson(json['claim_by'] as Map<String, dynamic>),
      claimedByEmpCode: json['claimedByEmpCode'] as String?,
      claimedByEmpName: json['claimedByEmpName'] as String?,
      comments: json['comments'] as String?,
      confirmedDate: json['confirmedDate'] as String?,
    );
  }
}

class ClaimBy {
  const ClaimBy({this.payCurrency});

  final String? payCurrency;

  factory ClaimBy.fromJson(Map<String, dynamic> json) {
    return ClaimBy(payCurrency: json['payCurrency'] as String?);
  }
}

class ClaimStdDetail {
  const ClaimStdDetail({
    this.description,
    this.empCurrency,
    this.exCat,
    this.exRate,
    this.lcAmount,
    this.referenceNo,
    this.segStr,
    this.transactionCurrency,
    this.trAmount,
  });

  final String? description;
  final String? empCurrency;
  final String? exCat;
  final double? exRate;
  final String? lcAmount;
  final String? referenceNo;
  final String? segStr;
  final String? transactionCurrency;
  final String? trAmount;

  factory ClaimStdDetail.fromJson(Map<String, dynamic> json) {
    return ClaimStdDetail(
      description: json['description'] as String?,
      empCurrency: json['empCurrency'] as String?,
      exCat: json['ex_cat'] as String?,
      exRate: json['exRate'] is num
          ? (json['exRate'] as num).toDouble()
          : double.tryParse(json['exRate']?.toString() ?? ''),
      lcAmount: json['lc_amount']?.toString(),
      referenceNo: json['referenceNo'] as String?,
      segStr: json['seg_str'] as String?,
      transactionCurrency: json['transactionCurrency'] as String?,
      trAmount: json['tr_amount']?.toString(),
    );
  }
}
