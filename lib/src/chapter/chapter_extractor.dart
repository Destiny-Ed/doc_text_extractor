import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:doc_text_extractor/src/models/chapter_model.dart';

class ChapterExtractor {
  /// Extract chapters with isolate support.
  static Future<List<Chapter>> extract(
    Uint8List pdfBytes, {
    void Function(double progress)? onProgress,
  }) async {
    final isLarge = pdfBytes.lengthInBytes > 1.5 * 1024 * 1024;

    if (isLarge) {
      // Offload heavy PDF parsing to isolate
      return compute(_extractInIsolate, {'bytes': pdfBytes});
    }

    return _extractSync(pdfBytes, onProgress);
  }

  ///Isolate extraction
  static List<Chapter> _extractInIsolate(Map args) {
    final bytes = args['bytes'] as Uint8List;

    // No progress callback allowed in isolates
    return _extractSync(bytes, null);
  }

  ///Synchronous extraction with progress tracker
  static List<Chapter> _extractSync(
    Uint8List pdfBytes,
    void Function(double progress)? onProgress,
  ) {
    try {
      final document = PdfDocument(inputBytes: pdfBytes);
      final extractor = PdfTextExtractor(document);

      final int pageCount = document.pages.count;
      final chapters = <Chapter>[];

      final StringBuffer currentContent = StringBuffer();
      int? chapterStartPage;
      String? currentTitle;

      final detectionPatterns = [
        RegExp(
          r'^(chapter|unit|lesson)\s+[\dIVXLCDM]+[\s:.-]+(.+)',
          caseSensitive: false,
        ),
        RegExp(
          r'^(chapter)\s+(one|two|three|four|five)\s+(.+)',
          caseSensitive: false,
        ),
        RegExp(r'^(topic)\s+\d+[\s:.-]+(.+)', caseSensitive: false),
        RegExp(r'^\d+\.\s+(.+)', caseSensitive: false),
        RegExp(r'^(chapter)\s+\d+\s+(.+)', caseSensitive: false),
      ];

      for (int i = 0; i < pageCount; i++) {
        final pageText = extractor.extractText(
          startPageIndex: i,
          endPageIndex: i,
        );

        // Progress callback
        if (onProgress != null) {
          onProgress((i + 1) / pageCount);
        }

        final lines = pageText.split('\n');
        String? foundTitle;

        // Detect chapter title on this page
        for (final rawLine in lines) {
          final line = rawLine.trim();
          if (line.length < 6 || RegExp(r'^\d+$').hasMatch(line)) continue;

          for (final pattern in detectionPatterns) {
            final match = pattern.firstMatch(line);
            if (match != null) {
              final extracted =
                  match
                      .group(match.groupCount)!
                      .replaceAll(RegExp(r'\s+'), ' ')
                      .replaceAll(RegExp(r'^[\d.:-]+'), '')
                      .trim();

              if (extracted.isNotEmpty && extracted.length > 3) {
                foundTitle = extracted;
                break;
              }
            }
          }

          if (foundTitle != null) break;
        }

        // New chapter detected
        if (foundTitle != null) {
          if (currentTitle != null && chapterStartPage != null) {
            chapters.add(
              Chapter(
                id: chapters.length + 1,
                title: currentTitle,
                content: currentContent.toString().trim(),
                startPage: chapterStartPage,
                endPage: i + 1,
              ),
            );
          }

          currentTitle = foundTitle;
          currentContent.clear();
          chapterStartPage = i + 1;
        }

        // Append page text
        if (currentTitle != null) currentContent.writeln(pageText);
      }

      // Save final chapter
      if (currentTitle != null && chapterStartPage != null) {
        chapters.add(
          Chapter(
            id: chapters.length + 1,
            title: currentTitle,
            content: currentContent.toString().trim(),
            startPage: chapterStartPage,
            endPage: pageCount,
          ),
        );
      }

      document.dispose();

      // Fallback: no chapters detected
      if (chapters.isEmpty) {
        final full = extractor.extractText();
        return [
          Chapter(
            id: 1,
            title: "Full Document",
            content: full,
            startPage: 1,
            endPage: pageCount,
          ),
        ];
      }

      return chapters;
    } catch (e) {
      return _fallback(pdfBytes);
    }
  }

  static List<Chapter> _fallback(Uint8List bytes) {
    try {
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      final text = extractor.extractText();
      final pageCount = document.pages.count;
      document.dispose();

      return [
        Chapter(
          id: 1,
          title: "Full Document",
          content: text,
          startPage: 1,
          endPage: pageCount,
        ),
      ];
    } catch (_) {
      return [];
    }
  }
}
