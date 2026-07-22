import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:file_picker/file_picker.dart';

class PdfSearchUtil {

  Future<String> extractTextFromPdf(PlatformFile file) async {
    if (file.path == null && file.bytes == null) throw Exception('Invalid file');
    
    PdfDocument document;
    if (file.bytes != null) {
      document = PdfDocument(inputBytes: file.bytes!);
    } else {
      final bytes = await File(file.path!).readAsBytes();
      document = PdfDocument(inputBytes: bytes);
    }

    String text = PdfTextExtractor(document).extractText();
    document.dispose();
    return text;
  }

  String getSnippet(String fullText, String query, {int window = 200}) {
    final lowerFull = fullText.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final idx = lowerFull.indexOf(lowerQuery);
    if (idx == -1) {
      return fullText.length > window ? '${fullText.substring(0, window)}...' : fullText;
    }
    final start = (idx - window).clamp(0, fullText.length);
    final end = (idx + query.length + window).clamp(0, fullText.length);
    return '...${fullText.substring(start, end)}...';
  }

  List<Map<String, String>> searchInText(String text, String query) {
    final results = <Map<String, String>>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    int start = 0;
    while (true) {
      final idx = lowerText.indexOf(lowerQuery, start);
      if (idx == -1) break;
      results.add({
        'index': idx.toString(),
        'snippet': getSnippet(text, query),
      });
      start = idx + lowerQuery.length;
      if (results.length >= 10) break;
    }
    return results;
  }
}
