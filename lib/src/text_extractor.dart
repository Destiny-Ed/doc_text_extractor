import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:markdown/markdown.dart';

class TextExtractor {
  // Extracts text from a document URL or local file path
  Future<({String filename, String text})> extractText(
    String source, {
    bool isUrl = true,
  }) async {
    final lwSource = source.toLowerCase();
    try {
      if (isUrl) {
        // Validate URL
        final uri = Uri.parse(lwSource);
        if (!uri.isAbsolute) {
          throw Exception('Invalid URL');
        }

        //
        final response = await http.get(uri);
        if (response.statusCode != 200) {
          throw Exception('Failed to fetch document: ${response.statusCode}');
        }

        final contentType =
            response.headers['content-type']?.toLowerCase() ?? '';
        final contentDisposition = response.headers['content-disposition'];
        String filename =
            _extractFilename(contentDisposition, lwSource) ?? 'document';

        final bytes = response.bodyBytes;

        //Check if Url is a valid Google docs url
        bool isGoogleDoc =
            uri.host.contains('docs.google.com') &&
            uri.path.contains('/document/');
        if (isGoogleDoc) {
          return await _extractGoogleDocsText(lwSource, filename);
        } else if (contentType.contains('application/msword') ||
            lwSource.endsWith('.doc')) {
          return (
            text: await _extractDocText(bytes),
            filename: '$filename.doc',
          );
        } else if (contentType.contains(
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            ) ||
            lwSource.endsWith('.docx')) {
          return (
            text: await _extractDocxText(bytes),
            filename: '$filename.docx',
          );
        } else if (contentType.contains('application/pdf') ||
            lwSource.endsWith('.pdf')) {
          return (
            text: await _extractPdfText(bytes),
            filename: '$filename.pdf',
          );
        } else if (contentType.contains('text/markdown') ||
            lwSource.endsWith('.md')) {
          return (
            text: _extractMarkdownText(utf8.decode(bytes)),
            filename: '$filename.md',
          );
        } else {
          throw Exception('Unsupported document type: $contentType');
        }
      } else {
        // Local file handling

        final file = File(lwSource);
        final byte =
            kIsWeb
                ? await file.readAsBytes()
                : await File(file.path).readAsBytes();

        final extension = lwSource.split('.').last.toLowerCase();

        if (extension == 'doc') {
          return (
            text: await _extractDocText(byte),
            filename: file.uri.pathSegments.last,
          );
        } else if (extension == 'docx') {
          return (
            text: await _extractDocxText(byte),
            filename: file.uri.pathSegments.last,
          );
        } else if (extension == 'pdf') {
          return (
            text: await _extractPdfText(byte),
            filename: file.uri.pathSegments.last,
          );
        } else if (extension == 'md') {
          return (
            text: _extractMarkdownText(await file.readAsString()),
            filename: file.uri.pathSegments.last,
          );
        } else {
          throw Exception('Unsupported local file type: $extension');
        }
      }
    } catch (e) {
      throw Exception('Error extracting text: $e');
    }
  }

  // Extracts filename from Content-Disposition or URL
  String? _extractFilename(String? contentDisposition, String url) {
    if (contentDisposition != null &&
        contentDisposition.contains('filename=')) {
      final match = RegExp(
        r'filename="([^"]+)"',
      ).firstMatch(contentDisposition);
      return match?.group(1);
    }
    final uri = Uri.parse(url);
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
  }

  // .doc text extraction
  Future<String> _extractDocText(Uint8List bytes) async {
    try {
      final byteData = ByteData.sublistView(bytes);
      String text = '';
      // bool isLargeFile = bytes.length > 10 * 1024 * 1024; // >10MB

      // Basic binary parser for .doc text
      // Scan for printable ASCII/Unicode characters (32-126, basic Latin)
      final buffer = StringBuffer();
      bool inTextSegment = false;
      int textLength = 0;

      for (int i = 0; i < bytes.length && textLength < 100000; i++) {
        final byte = byteData.getUint8(i);
        if (byte >= 32 && byte <= 126) {
          // Printable ASCII character
          buffer.writeCharCode(byte);
          inTextSegment = true;
          textLength++;
        } else if (byte == 13 || byte == 10) {
          // Carriage return or newline
          if (inTextSegment) {
            buffer.write('\n');
            textLength++;
          }
        } else {
          // Non-text byte (e.g., formatting, metadata)
          if (inTextSegment && buffer.isNotEmpty) {
            text += '${buffer.toString()}\n';
            buffer.clear();
            inTextSegment = false;
          }
        }
      }

      // Append any remaining text
      if (buffer.isNotEmpty) {
        text += buffer.toString();
      }

      // Clean up extracted text
      text = text.replaceAll(RegExp(r'\n\s*\n+'), '\n').trim();
      if (text.isEmpty) {
        throw Exception('No readable text found in .doc file');
      }
      return text;
    } catch (e) {
      throw Exception(
        'Error extracting .doc text: File may be corrupted or unsupported. Try converting to .docx or PDF.',
      );
    }
  }
}

/// Converts a .docx file to text by extracting content from word/document.xml.
Future<String> _extractDocxText(Uint8List bytes) async {
  final archive = ZipDecoder().decodeBytes(bytes);

  final List<String> paragraphs = [];

  for (final file in archive) {
    if (file.isFile && file.name == 'word/document.xml') {
      final document = XmlDocument.parse(utf8.decode(file.content));

      final paragraphNodes = document.findAllElements('w:p');

      for (final paragraph in paragraphNodes) {
        final textNodes = paragraph.findAllElements('w:t');
        final text = textNodes.map((node) => node.innerText).join();
        paragraphs.add(text);
      }
    }
  }

  return paragraphs.join('\n').trim();
}

// PDF text extraction
Future<String> _extractPdfText(Uint8List bytes) async {
  final document = PdfDocument(inputBytes: bytes);
  final extractor = PdfTextExtractor(document);
  final text = extractor.extractText();
  document.dispose();
  return text.trim();
}

// Google Docs text extraction (downloads PDF export)
Future<({String filename, String text})> _extractGoogleDocsText(
  String url,
  String defaultFilename,
) async {
  final exportUrl = url.replaceFirst('/edit', '/export?format=pdf');
  final response = await http.get(Uri.parse(exportUrl));
  if (response.statusCode != 200) {
    throw Exception('Failed to fetch Google Docs PDF: ${response.statusCode}');
  }
  final text = await _extractPdfText(response.bodyBytes);
  return (text: text, filename: '$defaultFilename.pdf');
}

// Markdown text extraction (converts to plain text)
String _extractMarkdownText(String markdownContent) {
  final document = Document();
  final lines = markdownContent.split('\n');
  final plainText = document
      .parseLines(lines)
      .map((node) => node.textContent)
      .join('\n');
  return plainText.trim();
}
