import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

class AiService {
  static Future<String> readText(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final rec = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final out = await rec.processImage(input);
      return out.text.trim();
    } finally {
      await rec.close();
    }
  }

  static Future<String> readBarcode(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final scanner = BarcodeScanner(
      formats: const [
        BarcodeFormat.qrCode,
        BarcodeFormat.aztec,
        BarcodeFormat.dataMatrix,
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.code93,
        BarcodeFormat.itf,
        BarcodeFormat.pdf417,
      ],
    );
    try {
      final codes = await scanner.processImage(input);
      if (codes.isEmpty) return '';
      final b = codes.first;
      return b.rawValue ?? b.displayValue ?? '';
    } finally {
      await scanner.close();
    }
  }
}
