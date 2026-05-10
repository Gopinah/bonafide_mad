import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/request_model.dart';

class CertificateService {
  /// Generates a professional Bonafide Certificate as a PNG Image.
  /// Branded for PSG COLLEGE OF TECHNOLOGY.
  static Future<File> generateCertificateImage(RequestModel request, {String? customBody}) async {
    const double width = 1200;
    const double height = 1600;
    
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));
    final paint = Paint()..color = Colors.white;
    
    // 1. Draw Background
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), paint);
    
    // 2. Draw Elegant Border
    final borderPaint = Paint()
      ..color = const Color(0xFF002366)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;
    canvas.drawRect(Rect.fromLTWH(20, 20, width - 40, height - 40), borderPaint);

    final date = DateFormat('dd.MM.yyyy').format(DateTime.now());
    
    // Text drawing helper
    void drawText(String text, double y, {double fontSize = 30, FontWeight weight = FontWeight.normal, TextAlign align = TextAlign.center, Color color = Colors.black, double? customWidth}) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight, fontFamily: 'serif'),
        ),
        textDirection: ui.TextDirection.ltr,
        textAlign: align,
        textScaler: TextScaler.noScaling,
      );
      final drawWidth = customWidth ?? width;
      textPainter.layout(minWidth: drawWidth, maxWidth: drawWidth);
      textPainter.paint(canvas, Offset((width - drawWidth) / 2, y));
    }

    // 3. Header: PSG COLLEGE OF TECHNOLOGY
    drawText("PSG COLLEGE OF TECHNOLOGY", 120, fontSize: 55, weight: FontWeight.bold, color: const Color(0xFF002366));
    drawText("An Autonomous Institution Affiliated to Anna University", 200, fontSize: 24, color: Colors.black87);
    drawText("Coimbatore - 641 004, Tamil Nadu, India", 240, fontSize: 24, color: Colors.black87);
    
    final linePaint = Paint()..color = const Color(0xFF002366)..strokeWidth = 3;
    canvas.drawLine(const Offset(100, 300), const Offset(1100, 300), linePaint);

    drawText("BONAFIDE CERTIFICATE", 400, fontSize: 50, weight: FontWeight.bold, color: const Color(0xFF002366));
    drawText("Date: $date", 500, fontSize: 30, align: TextAlign.right, customWidth: 1000);
    
    // 4. Content (Main Body)
    const double contentY = 680;
    
    final String bodyText = (customBody != null && customBody.isNotEmpty) 
        ? customBody 
        : "This is to certify that Mr./Ms. ${request.studentName} (Roll No: ${request.studentId}) is a bonafide student of the Department of ${request.department}, Class ${request.className} at PSG COLLEGE OF TECHNOLOGY, Coimbatore, during the Academic year 2024-2025. This certificate is issued for the purpose of ${request.subject}.";

    final contentPainter = TextPainter(
      text: TextSpan(
        text: bodyText,
        style: const TextStyle(color: Colors.black, fontSize: 36, height: 1.8, fontFamily: 'serif'),
      ),
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.justify,
      textScaler: TextScaler.noScaling,
    );
    contentPainter.layout(minWidth: 1000, maxWidth: 1000);
    contentPainter.paint(canvas, const Offset(100, contentY));

    // 5. Footer
    drawText("OFFICE SEAL", 1350, fontSize: 24, align: TextAlign.left, customWidth: 1000);
    drawText("PRINCIPAL", 1350, fontSize: 32, weight: FontWeight.bold, align: TextAlign.right, customWidth: 1000);
    drawText("PSG College of Technology", 1400, fontSize: 24, align: TextAlign.right, customWidth: 1000);

    final sealPaint = Paint()..color = Colors.grey.shade300..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawCircle(const Offset(220, 1340), 90, sealPaint);

    // 6. Save as PNG
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/bonafide_${request.requestId}.png");
    await file.writeAsBytes(buffer);
    return file;
  }
}
