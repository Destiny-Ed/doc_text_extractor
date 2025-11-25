import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'google_docs_utils.dart';

Future<({Uint8List bytes, http.Response? response})> fetchBytes(
  String url,
) async {
  final uri = Uri.tryParse(url);

  if (uri == null || !uri.isAbsolute) {
    throw Exception("Invalid URL: $url");
  }

  if (isGoogleDocs(url)) {
    return await fetchGoogleDocsPdf(uri);
  }

  final res = await http.get(uri);

  if (res.statusCode != 200) {
    throw Exception("Failed to fetch file: ${res.statusCode}");
  }

  return (bytes: res.bodyBytes, response: res);
}
