class ApproveDocResponse {
  const ApproveDocResponse({
    this.data,
    this.message,
    this.success,
  });

  final List<dynamic>? data;
  final String? message;
  final bool? success;

  factory ApproveDocResponse.fromJson(Map<String, dynamic> json) {
    return ApproveDocResponse(
      data: json['data'] as List<dynamic>?,
      message: json['message'] as String?,
      success: json['success'] as bool?,
    );
  }
}
