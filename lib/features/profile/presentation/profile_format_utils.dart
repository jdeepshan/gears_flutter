String formatProfileJoinedDate(String? date) {
  if (date == null || date.trim().isEmpty) return '-';

  try {
    final normalized = date.trim().replaceFirst(' ', 'T');
    final parsed = DateTime.parse(normalized);
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();
    return '$day/$month/$year';
  } catch (_) {
    return '-';
  }
}

String profileDetailValue(String? value) {
  if (value == null || value.trim().isEmpty) return '-';
  return value.trim();
}
