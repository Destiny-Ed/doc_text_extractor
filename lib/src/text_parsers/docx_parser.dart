import 'dart:typed_data';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import 'parser_base.dart';

class DocxParser extends ParserBase {
  @override
  Future<String> parse(
    Uint8List bytes,
    Function(double progress)? onProgress,
  ) async {
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
}
