import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfUtils {
  static String? fileName; // To store the uploaded file's name

  static Future<String?> extractTextFromPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.isEmpty) {
        print("No file selected.");
        return null;
      }

      fileName = result.files.single.name; // Store the file name
      final filePath = result.files.single.path!;
      final bytes = await File(filePath).readAsBytes();

      final PdfDocument document = PdfDocument(inputBytes: bytes);

      String extractedText = '';
      for (int i = 0; i < document.pages.count; i++) {
        extractedText += PdfTextExtractor(document).extractText(
          startPageIndex: i,
          endPageIndex: i,
        );
      }

      return extractedText;
    } catch (e) {
      print("Error extracting text from PDF: $e");
      return null;
    }
  }
}