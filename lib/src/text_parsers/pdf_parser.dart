import 'dart:developer';
import 'dart:typed_data';

import 'package:doc_text_extractor/src/isolates/pdf_isolate.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'parser_base.dart';

class PdfParser extends ParserBase {
  @override
  Future<String> parse(
    Uint8List bytes,
    Function(double progress)? onProgress,
  ) async {
    // If file is large (>1.5 MB), isolate is MUCH safer
    final isLarge = bytes.lengthInBytes > 1.5 * 1024 * 1024;

    debugPrint("It's fucking large!!!!!!!! $isLarge");

    if (isLarge) {
      return compute(extractPdfInIsolate, bytes);
    }

    final document = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(document);

    final int pageCount = document.pages.count;
    final buffer = StringBuffer();

    for (int i = 0; i < pageCount; i++) {
      final pageText = extractor.extractText(
        startPageIndex: i,
        endPageIndex: i,
      );
      buffer.write('\n$pageText');

      // Emit progress (0.0 — 1.0)
      if (onProgress != null) {
        onProgress((i + 1) / pageCount);
      }

      // Small async yield for UI responsiveness
      await Future.delayed(const Duration(milliseconds: 5));
    }

    document.dispose();
    return buffer.toString().trim();
  }
}
