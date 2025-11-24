// lib/services/chapter_extractor.dart
import 'dart:typed_data';
import 'package:doc_text_extractor/src/models/chapter_model.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ChapterExtractor {
  static Future<List<Chapter>> extract(Uint8List pdfBytes) async {
    try {
      final document = PdfDocument(inputBytes: pdfBytes);
      final extractor = PdfTextExtractor(document);
      final List<Chapter> chapters = [];
      final StringBuffer currentContent = StringBuffer();

      // Advanced detection patterns
      final patterns = [
        RegExp(
          r'^(chapter|CHAPTER|unit|UNIT|lesson|LESSON)\s+[\dIVXLCDM]+[\s:.-]+(.+)',
          caseSensitive: false,
        ),
        RegExp(
          r'^(chapter|CHAPTER)\s+(one|two|three|four|five|six|seven|eight|nine|ten)[\s:.-]+(.+)',
          caseSensitive: false,
        ),
        RegExp(r'^(topic|TOPIC)\s+\d+[\s:.-]+(.+)', caseSensitive: false),
        RegExp(r'^\d+\.\s+(.+)', caseSensitive: false),
        RegExp(r'^(chapter|CHAPTER)\s+\d+\s+(.+)', caseSensitive: false),
      ];

      int? chapterStartPage;
      String? currentTitle;

      for (int i = 0; i < document.pages.count; i++) {
        final pageText = extractor.extractText(
          startPageIndex: i,
          endPageIndex: i,
        );
        final lines = pageText.split('\n');

        bool foundChapterTitle = false;
        String? detectedTitle;

        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.length < 10 || RegExp(r'^\d+$').hasMatch(trimmed)) {
            continue;
          }

          for (final pattern in patterns) {
            final match = pattern.firstMatch(trimmed);
            if (match != null) {
              detectedTitle =
                  match
                      .group(match.groupCount)!
                      .trim()
                      .replaceAll(RegExp(r'\s+'), ' ')
                      .replaceAll(RegExp(r'^[\d.:-]+'), '')
                      .trim();
              foundChapterTitle = true;
              break;
            }
          }
          if (foundChapterTitle) break;
        }

        if (foundChapterTitle &&
            detectedTitle != null &&
            detectedTitle.length > 3) {
          // Save previous chapter
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

          // Start new chapter
          currentTitle =
              detectedTitle.isEmpty
                  ? "Chapter ${chapters.length + 2}"
                  : detectedTitle;
          chapterStartPage = i + 1;
          currentContent.clear();
        }

        // Always add page text to current chapter (after title detection)
        if (currentTitle != null) {
          currentContent.writeln(pageText);
        }
      }

      // Save the last chapter
      if (currentTitle != null && chapterStartPage != null) {
        chapters.add(
          Chapter(
            id: chapters.length + 1,
            title: currentTitle,
            content: currentContent.toString().trim(),
            startPage: chapterStartPage,
            endPage: document.pages.count,
          ),
        );
      }

      document.dispose();

      // Fallback if nothing detected
      if (chapters.isEmpty) {
        final fullText = extractor.extractText();
        return [
          Chapter(
            id: 1,
            title: "Full Document",
            content: fullText,
            startPage: 1,
            endPage: document.pages.count,
          ),
        ];
      }

      return chapters;
    } catch (e) {
      return _fallbackWithContent(pdfBytes);
    }
  }

  static List<Chapter> _fallbackWithContent(Uint8List pdfBytes) {
    try {
      final document = PdfDocument(inputBytes: pdfBytes);
      final extractor = PdfTextExtractor(document);
      final fullText = extractor.extractText();
      document.dispose();

      return [
        Chapter(
          id: 1,
          title: "Complete Document",
          content: fullText,
          startPage: 1,
          endPage: document.pages.count,
        ),
      ];
    } catch (_) {
      return [
        Chapter(
          id: 1,
          title: "Document",
          content: "Content could not be extracted.",
          startPage: 1,
          endPage: 100,
        ),
      ];
    }
  }
}
