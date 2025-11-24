String detectFileType(String? contentType, String filename) {
  final lower = contentType?.toLowerCase() ?? "";
  final ext = filename.toLowerCase();

  if (lower.contains("msword") || ext.endsWith(".doc")) return "doc";
  if (lower.contains("wordprocessingml") || ext.endsWith(".docx")) {
    return "docx";
  }
  if (lower.contains("pdf") || ext.endsWith(".pdf")) return "pdf";
  if (lower.contains("markdown") || ext.endsWith(".md")) return "md";

  return "unknown";
}

String sanitizeFilename(String filename) {
  final cleaned = filename.replaceAll(RegExp(r'[^\w\s.-]'), '');
  final ext = cleaned.split('.').last.toLowerCase();
  const valid = ["pdf", "doc", "docx", "md"];

  return valid.contains(ext) ? cleaned : "$cleaned.pdf";
}

String resolveFilename(String url, response) {
  final header = response?.headers["content-disposition"];

  if (header != null && header.contains("filename=")) {
    final match = RegExp(r'filename="([^"]+)"').firstMatch(header);
    if (match != null) {
      return sanitizeFilename(match.group(1)!);
    }
  }

  return Uri.parse(url).pathSegments.last;
}
