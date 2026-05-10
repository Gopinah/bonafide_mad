import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/request_model.dart';

class PdfService {
  static Future<File> generateBonafidePdf(RequestModel request) async {
    final pdf = pw.Document();
    final date = DateFormat('dd.MM.yyyy').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(50),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text("ABC COLLEGE OF TECHNOLOGY",
                        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Text("Approved by AICTE, New Delhi & Affiliated to Anna University",
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.Text("Coimbatore - 641 004, Tamil Nadu, India", style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 10),
                    pw.Divider(thickness: 2, color: PdfColors.blue900),
                    pw.SizedBox(height: 2),
                    pw.Divider(thickness: 0.5, color: PdfColors.blue900),
                  ],
                ),
              ),
              pw.SizedBox(height: 40),

              // Title
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 1.5),
                  ),
                  child: pw.Text("BONAFIDE CERTIFICATE",
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ),
              ),
              pw.SizedBox(height: 50),

              // Date
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text("Date: $date", style: const pw.TextStyle(fontSize: 12)),
              ),
              pw.SizedBox(height: 30),

              // Content
              pw.RichText(
                textAlign: pw.TextAlign.justify,
                text: pw.TextSpan(
                  style: const pw.TextStyle(fontSize: 14, lineSpacing: 2.5),
                  children: [
                    const pw.TextSpan(text: "This is to certify that Mr./Ms. "),
                    pw.TextSpan(
                        text: request.studentName,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.TextSpan(text: " (Reg. No: ${request.studentId})"),
                    const pw.TextSpan(text: " is a bonafide student of "),
                    pw.TextSpan(
                        text: "ABC College of Technology",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.TextSpan(
                        text: ", Coimbatore, studying in ${request.year} ${request.department} during the Academic year 2024-2025."),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              pw.Text(
                "This certificate is issued for the purpose of ${request.reason ?? request.subject}.",
                style: const pw.TextStyle(fontSize: 14),
              ),

              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(
                        height: 60,
                        width: 60,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300, style: pw.BorderStyle.dashed),
                        ),
                        child: pw.Center(
                          child: pw.Text("College\nSeal", textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text("OFFICE SEAL", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.SizedBox(height: 40),
                      pw.Text("PRINCIPAL",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                      pw.Text("ABC College of Technology", style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/bonafide_${request.requestId}.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
