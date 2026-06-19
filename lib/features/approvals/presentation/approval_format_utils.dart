const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String formatApprovalDate(String? date) {
  if (date == null || date.isEmpty) return 'N/A';

  try {
    final parsed = DateTime.parse(date);
    final day = parsed.day.toString().padLeft(2, '0');
    final month = _months[parsed.month - 1];
    return '$day $month ${parsed.year}';
  } catch (_) {
    return 'N/A';
  }
}

String formatApprovalDateTime(String? date) {
  if (date == null || date.trim().isEmpty) return 'N/A';

  final normalized = date.trim();
  final patterns = [
    'yyyy-MM-dd HH:mm:ss',
    'yyyy-MM-dd',
  ];

  for (final pattern in patterns) {
    final formatted = _formatWithPattern(normalized, pattern);
    if (formatted != null) return formatted;
  }

  return formatApprovalDate(normalized);
}

String? _formatWithPattern(String value, String pattern) {
  try {
    DateTime parsed;
    if (pattern == 'yyyy-MM-dd HH:mm:ss') {
      parsed = DateTime.parse(value.replaceFirst(' ', 'T'));
    } else {
      parsed = DateTime.parse(value);
    }

    final day = parsed.day.toString().padLeft(2, '0');
    final month = _months[parsed.month - 1];
    return '$day $month ${parsed.year}';
  } catch (_) {
    return null;
  }
}

String formatApprovalNumber(num? value) {
  if (value == null) return '-';
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toString();
}

String displayComment(String? comment) {
  if (comment == null || comment.trim().isEmpty) {
    return 'No comments';
  }
  return comment.trim();
}
