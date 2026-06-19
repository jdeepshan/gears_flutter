class AttachmentsResponse {
  const AttachmentsResponse({
    this.data,
    this.message,
    this.success,
  });

  final List<AttachmentDatum>? data;
  final String? message;
  final bool? success;

  factory AttachmentsResponse.fromJson(Map<String, dynamic> json) {
    return AttachmentsResponse(
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => AttachmentDatum.fromJson(e as Map<String, dynamic>))
          .toList(),
      message: json['message'] as String?,
      success: json['success'] as bool?,
    );
  }
}

class AttachmentDatum {
  const AttachmentDatum({
    this.attachmentDescription,
    this.attachmentID,
    this.documentUrl,
    this.fileType,
    this.myFileName,
  });

  final String? attachmentDescription;
  final int? attachmentID;
  final String? documentUrl;
  final String? fileType;
  final String? myFileName;

  factory AttachmentDatum.fromJson(Map<String, dynamic> json) {
    return AttachmentDatum(
      attachmentDescription: json['attachmentDescription'] as String?,
      attachmentID: json['attachmentID'] as int?,
      documentUrl: json['document_url'] as String?,
      fileType: json['fileType'] as String?,
      myFileName: json['myFileName'] as String?,
    );
  }
}
