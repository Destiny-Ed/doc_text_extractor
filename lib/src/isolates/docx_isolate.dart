import 'dart:typed_data';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

Future<String> extractDocxInIsolate(Uint8List bytes) async {
  final archive = ZipDecoder().decodeBytes(bytes);
  final file = archive.findFile('word/document.xml');

  if (file == null) {
    throw Exception("Invalid DOCX file structure.");
  }

  final xmlDoc = XmlDocument.parse(utf8.decode(file.content));

  final text =
      xmlDoc
          .findAllElements("w:p")
          .map((p) => p.findAllElements("w:t").map((t) => t.innerText).join())
          .join("\n")
          .trim();

  return text;
}
