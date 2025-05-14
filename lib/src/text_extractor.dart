import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart' as xml;
import 'package:markdown/markdown.dart';

/// Extracts text from various document formats, including Word (.doc, .docx),
/// PDF, Google Docs URLs, and Markdown (.md) files.
class TextExtractor {
  /// Extracts text from a document URL or local file path.
  ///
  /// Returns a record with `filename` and `text`. If `isUrl` is true, fetches
  /// the document from the provided URL. Otherwise, reads from a local file path.
  ///
  /// Throws an [Exception] for invalid URLs, unsupported formats, or extraction errors.
  Future<({String filename, String text})> extractText(
    String source, {
    bool isUrl = true,
  }) async {
    try {
      return isUrl
          ? await _extractFromUrl(source)
          : await _extractFromLocalFile(source);
    } catch (e) {
      throw Exception('Failed to extract text: $e');
    }
  }

  /// Extracts text from a document URL.
  Future<({String filename, String text})> _extractFromUrl(String url) async {
    final uri = Uri.parse(url);
    if (!uri.isAbsolute) {
      throw Exception('Invalid URL: $url');
    }

    if (uri.host.contains('docs.google.com') &&
        uri.path.contains('/document/')) {
      return await _extractGoogleDocsText(uri);
    }

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch document: ${response.statusCode}');
    }

    final contentType = response.headers['content-type']?.toLowerCase() ?? '';
    final filename = url.toLowerCase().split("/").last;
    final bytes = response.bodyBytes;

    return switch (_getFileType(contentType, url)) {
      'doc' => (filename: filename, text: await _extractDocText(bytes)),
      'docx' => (filename: filename, text: await _extractDocxText(bytes)),
      'pdf' => (filename: filename, text: await _extractPdfText(bytes)),
      'md' => (
        filename: filename,
        text: _extractMarkdownText(utf8.decode(bytes)),
      ),
      _ => throw Exception('Unsupported document type: $contentType'),
    };
  }

  /// Extracts text from a local file.
  Future<({String filename, String text})> _extractFromLocalFile(
    String filePath,
  ) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    final bytes = await file.readAsBytes();
    final filename = file.uri.pathSegments.last;
    final extension = filename.split('.').last.toLowerCase();

    return switch (extension) {
      'doc' => (filename: filename, text: await _extractDocText(bytes)),
      'docx' => (filename: filename, text: await _extractDocxText(bytes)),
      'pdf' => (filename: filename, text: await _extractPdfText(bytes)),
      'md' => (
        filename: filename,
        text: _extractMarkdownText(await file.readAsString()),
      ),
      _ => throw Exception('Unsupported local file type: $extension'),
    };
  }

  /// Determines the file type based on content type or URL extension.
  String _getFileType(String contentType, String url) {
    if (contentType.contains('application/msword') ||
        url.toLowerCase().endsWith('.doc')) {
      return 'doc';
    }
    if (contentType.contains(
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        ) ||
        url.toLowerCase().endsWith('.docx')) {
      return 'docx';
    }
    if (contentType.contains('application/pdf') ||
        url.toLowerCase().endsWith('.pdf')) {
      return 'pdf';
    }
    if (contentType.contains('text/markdown') ||
        url.toLowerCase().endsWith('.md')) {
      return 'md';
    }
    return 'unknown';
  }

  /// Extracts filename from Content-Disposition header or URL.
  String? _extractFilename(String? contentDisposition, String url) {
    if (contentDisposition != null &&
        contentDisposition.contains('filename=')) {
      final match = RegExp(
        r'filename="([^"]+)"',
      ).firstMatch(contentDisposition);
      if (match != null && match.group(1) != null) {
        return _sanitizeFilename(match.group(1)!);
      }
    }
    final uri = Uri.parse(url);
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
  }

  /// Sanitizes a filename by removing invalid characters and ensuring an extension.
  String _sanitizeFilename(String filename) {
    final sanitized = filename.replaceAll(RegExp(r'[^\w\s.-]'), '');
    if (!sanitized.toLowerCase().endsWith('.pdf') &&
        !sanitized.toLowerCase().endsWith('.docx') &&
        !sanitized.toLowerCase().endsWith('.doc') &&
        !sanitized.toLowerCase().endsWith('.md')) {
      return '$sanitized.pdf'; // Default for Google Docs or unspecified formats
    }
    return sanitized;
  }

  /// Extracts text from a .doc file using a basic ASCII parser.
  Future<String> _extractDocText(Uint8List bytes) async {
    try {
      final buffer = StringBuffer();
      bool inTextSegment = false;
      var textLength = 0;

      for (var i = 0; i < bytes.length && textLength < 100000; i++) {
        final byte = bytes[i];
        if (byte >= 32 && byte <= 126) {
          buffer.writeCharCode(byte);
          inTextSegment = true;
          textLength++;
        } else if (byte == 10 || byte == 13) {
          if (inTextSegment) {
            buffer.write('\n');
            textLength++;
          }
        } else if (inTextSegment && buffer.isNotEmpty) {
          inTextSegment = false;
        }
      }

      if (buffer.isNotEmpty) {
        buffer.write('\n');
      }

      final text =
          buffer.toString().replaceAll(RegExp(r'\n\s*\n+'), '\n').trim();
      if (text.isEmpty) {
        throw Exception('No readable text found in .doc file');
      }
      return text;
    } catch (e) {
      throw Exception(
        'Failed to extract .doc text: File may be corrupted or unsupported. Try converting to .docx or PDF.',
      );
    }
  }

  /// Extracts text from a .docx file by parsing word/document.xml.
  Future<String> _extractDocxText(Uint8List bytes) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final file = archive.findFile('word/document.xml');
      if (file == null) {
        throw Exception('Invalid .docx structure: document.xml not found');
      }

      final document = xml.XmlDocument.parse(utf8.decode(file.content));
      final paragraphs =
          document
              .findAllElements('w:p')
              .map(
                (p) => p.findAllElements('w:t').map((t) => t.innerText).join(),
              )
              .toList();

      return paragraphs.join('\n').trim();
    } catch (e) {
      throw Exception('Failed to extract .docx text: $e');
    }
  }

  /// Extracts text from a PDF file using Syncfusion.
  Future<String> _extractPdfText(Uint8List bytes) async {
    try {
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      final text = extractor.extractText();
      document.dispose();
      return text.trim();
    } catch (e) {
      throw Exception('Failed to extract PDF text: $e');
    }
  }

  /// Extracts text from a Google Docs URL by downloading its PDF export.
  Future<({String filename, String text})> _extractGoogleDocsText(
    Uri uri,
  ) async {
    final docId = uri.pathSegments.firstWhere(
      (segment) =>
          segment.length > 20 && RegExp(r'^[0-9A-Za-z_-]+$').hasMatch(segment),
      orElse: () => '',
    );
    if (docId.isEmpty) {
      throw Exception('Invalid Google Docs URL');
    }

    final exportUrl = Uri.parse(
      'https://docs.google.com/document/d/$docId/export?format=pdf',
    );
    String fileName = "$docId.pdf";
    final response = await http.get(exportUrl);
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch Google Docs PDF: ${response.statusCode}',
      );
    }

    ///Extract google docs file name
    final contentDisposition = response.headers['content-disposition'];
    fileName =
        _extractFilename(contentDisposition, exportUrl.path) ?? 'googleDoc';
    // final bytes = response.bodyBytes;

    final text = await _extractPdfText(response.bodyBytes);
    return (filename: fileName, text: text);
  }

  /// Converts Markdown content to plain text.
  String _extractMarkdownText(String markdownContent) {
    final document = Document();
    final lines = markdownContent.split('\n');
    final plainText = document
        .parseLines(lines)
        .map((node) => node.textContent)
        .join('\n');
    return plainText.trim();
  }
}
