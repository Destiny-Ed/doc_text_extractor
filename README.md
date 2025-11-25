# DocTextExtractor

A Flutter package for extracting text from Word (.doc, .docx), PDF, Markdown(.md) and Google Docs URLs

DocTextExtractor is a lightweight Flutter package that extracts text from Word (.doc, .docx), PDF, Markdown(.md) and Google Docs URLs, with offline .doc support, real filename extraction, and automatic chapter splitting. Perfect for AI-driven apps like [NotteChat](https://nottechat.com), it enables document-based chat and analysis by processing legacy and modern formats efficiently.

## Features

- **Word (.doc, .docx) Extraction**: Parse legacy .doc files offline and .docx files via XML.
- **PDF Extraction**: Extract text from PDFs using Syncfusion.
- **Google Docs Support**: Download PDF exports from Google Docs URLs with real filename extraction.
- **Offline Support**: Process local .doc, .docx, .md, and PDF files without internet.
- **Real Filename Extraction**: Retrieve accurate document names from Content-Disposition headers or URLs.
- **Chapter Extractions**: Automatically split documents into logical chapters
- **Cross-Platform**: Works on iOS, Android, and web via Flutter.

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  doc_text_extractor: ^1.0.0
```

Run:

```bash
flutter pub get
```

## Usage

### Extract Text from a URL

```dart
import 'package:doc_text_extractor/doc_text_extractor.dart';

void main() async {
  final extractor = TextExtractor();
  try {
    // Extract text from a Google Docs URL
    final result = await extractor.extractText('https://docs.google.com/document/d/EXAMPLE_ID/edit');
    print('Filename: ${result['filename']}');
    print('Text: ${result['text']}');

    // Extract text from a .doc URL
    final docResult = await extractor.extractText('https://example.com/sample.doc');
    print('Filename: ${docResult['filename']}');
    print('Text: ${docResult['text']}');

    // Extract text from a .md URL
    final mdResult = await extractor.extractText('https://example.com/sample.md');
    print('Filename: ${mdResult['filename']}');
    print('Text: ${mdResult['text']}');
  } catch (e) {
    print('Error: $e');
  }
}
```

### Extract Text from a Local File

```dart
import 'package:doc_text_extractor/doc_text_extractor.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() async {
  final extractor = TextExtractor();
  try {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/sample.pdf';
    // Assume sample.pdf exists in temporary directory
    final result = await extractor.extractText(filePath, isUrl: false);
    print('Filename: ${result['filename']}');
    print('Text: ${result['text']}');
  } catch (e) {
    print('Error: $e');
  }
}
```

## Dependencies

- `http`: Fetches document URLs.
- `syncfusion_flutter_pdf`: Extracts PDF text.
- `archive` and `xml`: Parse .docx files.

## Limitations

- Google Docs URLs must be publicly accessible or shared with export permissions.
- Large files (>10MB) may require loading dialogs for optimal UX.

## Contributing

Contributions are welcome! Fork the repository, create a branch, and submit a pull request. Report issues at GitHub Issues.

## License

MIT License. See LICENSE for details.

## Contact

- **Developer**: Destiny Ed
- **Email**: [talk2destinyed@gmail.com]
- **Repository**: https://github.com/Destiny-Ed/doc_text_extractor
