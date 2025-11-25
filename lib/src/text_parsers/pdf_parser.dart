import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'parser_base.dart';

class PdfParser extends ParserBase {
  @override
  Future<String> parse(Uint8List bytes) async {
    final doc = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(doc);

    final text = extractor.extractText();
    doc.dispose();

    return text.trim();
  }
}
