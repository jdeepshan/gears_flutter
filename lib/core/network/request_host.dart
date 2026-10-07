/// True for absolute URLs on a different host than this API client (for example S3).
bool isExternalAbsoluteUrl({required String baseUrl, required String path}) {
  if (!path.startsWith(RegExp(r'https?:', caseSensitive: false))) {
    return false;
  }

  final requestHost = Uri.tryParse(path)?.host.toLowerCase();
  final apiHost = Uri.tryParse(baseUrl)?.host.toLowerCase();
  if (requestHost == null || apiHost == null || apiHost.isEmpty) {
    return true;
  }
  return requestHost != apiHost;
}
