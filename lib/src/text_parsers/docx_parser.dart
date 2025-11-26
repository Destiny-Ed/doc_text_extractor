import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:doc_text_extractor/src/isolates/docx_isolate.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

import 'parser_base.dart';

class DocxParser extends ParserBase {
  @override
  Future<String> parse(
    Uint8List bytes,
    Function(double progress)? onProgress,
  ) async {
    // If file is large (>1.5 MB), isolate is MUCH safer
    final isLarge = bytes.lengthInBytes > 1.5 * 1024 * 1024;

    if (isLarge) {
      return compute(extractDocxInIsolate, bytes);
    }

    // Report small progress step
    onProgress?.call(0.05);

    // Decode DOCX ZIP
    final archive = ZipDecoder().decodeBytes(bytes);
    onProgress?.call(0.15);

    final file = archive.findFile('word/document.xml');
    if (file == null) {
      throw Exception("Invalid DOCX file structure — document.xml missing.");
    }

    // Parse XML
    final xmlDoc = XmlDocument.parse(utf8.decode(file.content));
    onProgress?.call(0.35);

    // Extract all <w:p> paragraphs
    final paragraphs = xmlDoc.findAllElements("w:p").toList();
    final total = paragraphs.length;

    final buffer = StringBuffer();

    for (var i = 0; i < total; i++) {
      final p = paragraphs[i];

      final text = p.findAllElements("w:t").map((t) => t.innerText).join();

      if (text.trim().isNotEmpty) {
        buffer.writeln(text);
      }

      // Progress from 40% → 100%
      if (i % 15 == 0 && onProgress != null) {
        onProgress(0.40 + (i / total) * 0.60);
      }
    }

    return buffer.toString().trim();
  }
}
