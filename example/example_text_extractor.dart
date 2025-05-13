import 'package:doc_text_extractor/doc_text_extractor.dart';

void main() async {
  final extractor = TextExtractor();
  try {
    // Example: Extract text from a public Google Docs URL
    final googleDocsResult = await extractor.extractText(
      'https://docs.google.com/document/d/EXAMPLE_ID/edit',
      isUrl: true,
    );
    print('Google Docs Filename: ${googleDocsResult['filename']}');
    print('Google Docs Text: ${googleDocsResult['text'].substring(0, 100)}...');

    // Example: Extract text from a .doc URL
    final docResult = await extractor.extractText(
      'https://example.com/sample.doc',
      isUrl: true,
    );
    print('DOC Filename: ${docResult['filename']}');
    print('DOC Text: ${docResult['text'].substring(0, 100)}...');

    // Example: Extract text from a .md URL
    final mdResult = await extractor.extractText(
      'https://example.com/sample.md',
      isUrl: true,
    );
    print('Markdown Filename: ${mdResult['filename']}');
    print('Markdown Text: ${mdResult['text'].substring(0, 100)}...');
  } catch (e) {
    print('Error: $e');
  }
}
