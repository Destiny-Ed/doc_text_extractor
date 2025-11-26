import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Runs PDF text extraction inside a background isolate.
/// This method MUST remain top-level because isolates cannot run closures.
Future<String> extractPdfInIsolate(Uint8List bytes) async {
  final document = PdfDocument(inputBytes: bytes);
  final extractor = PdfTextExtractor(document);
  final text = extractor.extractText();
  document.dispose();
  return text.trim();
}
