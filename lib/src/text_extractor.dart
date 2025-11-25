import 'dart:typed_data';
import 'dart:io';
import 'package:doc_text_extractor/doc_text_extractor.dart';
import 'package:doc_text_extractor/src/text_parsers/parser_base.dart';
import 'package:http/http.dart' as http;
import 'package:doc_text_extractor/src/chapter_extractor.dart';
import 'utils/network_utils.dart';
import 'utils/file_utils.dart';
import 'text_parsers/doc_parser.dart';
import 'text_parsers/docx_parser.dart';
import 'text_parsers/pdf_parser.dart';
import 'text_parsers/markdown_parser.dart';

/// Provides document text extraction for PDF, DOC, DOCX, Markdown & Google Docs.
class TextExtractor {
  /// Extracts text from remote or local source.
  Future<({String filename, String text, Uint8List byte})> extractText(
    String source, {
    bool isUrl = true,
  }) async {
    final bytesResponse =
        isUrl ? await fetchBytes(source) : await _readLocal(source);

    final filename = resolveFilename(source, bytesResponse.response);
    final bytes = bytesResponse.bytes;

    final type = detectFileType(
      bytesResponse.response?.headers['content-type'],
      filename,
    );

    final parser = _getParser(type);

    final text = await parser.parse(bytes);

    return (filename: filename, text: text, byte: bytes);
  }

  /// Extract structured chapters.
  Future<List<Chapter>> extractChapters(
    String source, {
    bool isUrl = false,
  }) async {
    final bytesResponse =
        isUrl ? await fetchBytes(source) : await _readLocal(source);
    return ChapterExtractor.extract(bytesResponse.bytes);
  }

  // --------------------------- PRIVATE HELPERS ------------------------------

  Future<({Uint8List bytes, http.Response? response})> _readLocal(
    String filePath,
  ) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception("File not found: $filePath");
    }

    final bytes = await file.readAsBytes();

    return (bytes: bytes, response: null);
  }

  ParserBase _getParser(String type) {
    switch (type) {
      case 'doc':
        return DocParser();
      case 'docx':
        return DocxParser();
      case 'pdf':
        return PdfParser();
      case 'md':
        return MarkdownParser();
      default:
        throw Exception("Unsupported file type: $type");
    }
  }
}
