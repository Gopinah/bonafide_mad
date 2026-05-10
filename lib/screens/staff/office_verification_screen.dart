import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../services/pdf_service.dart';
import '../../models/request_model.dart';

class OfficeVerificationScreen extends StatefulWidget {
  const OfficeVerificationScreen({super.key});

  @override
  State<OfficeVerificationScreen> createState() => _OfficeVerificationScreenState();
}

class _OfficeVerificationScreenState extends State<OfficeVerificationScreen> {
  final DatabaseService _db = DatabaseService();
  final Color primaryColor = const Color(0xFF002366);
  
  Map<String, bool> _isProcessing = {};

  Future<void> _viewUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Flow: 1. Generate & Preview -> 2. Edit (if needed) -> 3. Issue (Upload)
  Future<void> _processIssuance(RequestModel request) async {
    final TextEditingController _editController = TextEditingController(text: request.body);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Prepare Bonafide", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
            const SizedBox(height: 15),
            Text("Student: ${request.studentName}", style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _editController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: "Certificate Body Text",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      // Temporary update for preview
                      RequestModel previewReq = RequestModel(
                        requestId: request.requestId,
                        approvalLevel: request.approvalLevel,
                        body: _editController.text,
                        className: request.className,
                        department: request.department,
                        status: request.status,
                        studentId: request.studentId,
                        studentName: request.studentName,
                        subject: request.subject,
                        timestamp: request.timestamp,
                        year: request.year,
                        reason: request.reason,
                      );
                      File file = await PdfService.generateBonafidePdf(previewReq);
                      final Uri uri = Uri.file(file.path);
                      await launchUrl(uri);
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("PREVIEW"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      _issueFinal(request, _editController.text);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
                    child: const Text("ISSUE & UPLOAD"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _issueFinal(RequestModel request, String updatedBody) async {
    setState(() => _isProcessing[request.requestId] = true);
    try {
      // 1. Update body in Firestore first
      await _db.updateRequestBody(request.requestId, updatedBody);
      
      // 2. Generate PDF with updated body
      RequestModel finalReq = RequestModel(
        requestId: request.requestId,
        approvalLevel: request.approvalLevel,
        body: updatedBody,
        className: request.className,
        department: request.department,
        status: request.status,
        studentId: request.studentId,
        studentName: request.studentName,
        subject: request.subject,
        timestamp: request.timestamp,
        year: request.year,
        reason: request.reason,
      );
      File pdfFile = await PdfService.generateBonafidePdf(finalReq);

      // 3. Upload as RAW
      String? url = await _db.uploadToCloudinary(pdfFile, resourceType: 'raw');
      
      if (url != null) {
        await _db.finalizeIssuance(request.requestId, url);
        _showSnackBar("Bonafide Issued Successfully!");
      }
    } catch (e) {
      _showSnackBar("Error: $e", isError: true);
    } finally {
      setState(() => _isProcessing.remove(request.requestId));
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text("Office Issuance Panel", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<RequestModel>>(
        stream: _db.getPendingStaffRequests(UserModel(
          userId: '', name: '', role: 'office', department: '', password: ''
        )),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No requests ready for issuance."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final req = snapshot.data![index];
              return _buildRequestCard(req);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(RequestModel req) {
    final bool processing = _isProcessing[req.requestId] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(req.studentName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: primaryColor)),
                _buildStatusChip("PENDING OFFICE"),
              ],
            ),
            const SizedBox(height: 4),
            Text("Reg No: ${req.studentId} | Dept: ${req.department}", style: const TextStyle(fontSize: 13, color: Colors.grey)),
            Text("Purpose: ${req.reason ?? req.subject}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const Divider(height: 30),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _viewUrl(req.annexureUrl),
                    icon: const Icon(Icons.attachment, size: 18),
                    label: const Text("ANNEXURE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: Colors.blue.shade800),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: processing ? null : () => _processIssuance(req),
                    icon: processing 
                      ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.edit_document, size: 18),
                    label: Text(processing ? "ISSUING..." : "GENERATE & ISSUE", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
