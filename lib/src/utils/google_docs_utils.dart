import 'dart:typed_data';
import 'package:http/http.dart' as http;

bool isGoogleDocs(String url) {
  final u = Uri.parse(url);
  return u.host.contains("docs.google.com") && u.path.contains("/document/");
}

Future<({Uint8List bytes, http.Response response})> fetchGoogleDocsPdf(
  Uri uri,
) async {
  final docId = uri.pathSegments.firstWhere(
    (s) => RegExp(r"^[0-9A-Za-z_-]{20,}$").hasMatch(s),
    orElse: () => "",
  );

  if (docId.isEmpty) throw Exception("Invalid Google Docs URL");

  final pdfUrl = Uri.parse(
    "https://docs.google.com/document/d/$docId/export?format=pdf",
  );

  final res = await http.get(pdfUrl);

  if (res.statusCode != 200) {
    throw Exception("Failed to export Google Doc: ${res.statusCode}");
  }

  return (bytes: res.bodyBytes, response: res);
}
