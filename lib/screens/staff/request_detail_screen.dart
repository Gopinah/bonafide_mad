import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/request_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/pdf_service.dart';

class RequestDetailScreen extends StatefulWidget {
  final RequestModel request;

  const RequestDetailScreen({super.key, required this.request});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  bool _isProcessing = false;
  final _reasonController = TextEditingController();
  late TextEditingController _bodyEditController;

  @override
  void initState() {
    super.initState();
    _bodyEditController = TextEditingController(text: widget.request.body);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _bodyEditController.dispose();
    super.dispose();
  }

  Future<void> _handleAction(bool isApproved) async {
    String? reason;
    if (!isApproved) {
      reason = await _showRejectionDialog();
      if (reason == null) return;
    }

    setState(() => _isProcessing = true);
    final db = DatabaseService();
    
    try {
      await db.updateRequestStatus(
        widget.request.requestId,
        widget.request.approvalLevel,
        isApproved,
        reason: reason,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isApproved ? "Application Approved" : "Application Rejected"),
            backgroundColor: isApproved ? Colors.green.shade700 : Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Office Staff specific: Generate, Edit, and Issue
  Future<void> _processIssuance() async {
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
            Text("Edit & Issue Bonafide", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF002366))),
            const SizedBox(height: 15),
            TextFormField(
              controller: _bodyEditController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: "Certificate Body Content",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      RequestModel previewReq = _getUpdatedRequest();
                      File file = await PdfService.generateBonafidePdf(previewReq);
                      await launchUrl(Uri.file(file.path));
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("PREVIEW"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _finalizeIssue();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
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

  RequestModel _getUpdatedRequest() {
    return RequestModel(
      requestId: widget.request.requestId,
      approvalLevel: widget.request.approvalLevel,
      body: _bodyEditController.text,
      className: widget.request.className,
      department: widget.request.department,
      status: widget.request.status,
      studentId: widget.request.studentId,
      studentName: widget.request.studentName,
      subject: widget.request.subject,
      timestamp: widget.request.timestamp,
      year: widget.request.year,
      reason: widget.request.reason,
    );
  }

  Future<void> _finalizeIssue() async {
    setState(() => _isProcessing = true);
    final db = DatabaseService();
    try {
      // 1. Generate final PDF
      File pdfFile = await PdfService.generateBonafidePdf(_getUpdatedRequest());

      // 2. Upload to Cloudinary with 'raw' resource type
      String? url = await db.uploadToCloudinary(pdfFile);
      
      if (url != null) {
        // 3. Finalize in Firestore
        await db.finalizeIssuance(widget.request.requestId, url);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Certificate Issued Successfully!"), backgroundColor: Colors.green),
          );
        }
      } else {
        throw "Upload failed";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Issuance Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<String?> _showRejectionDialog() {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Rejection Reason", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _reasonController,
          decoration: const InputDecoration(hintText: "Enter reason for rejection..."),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _reasonController.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("REJECT", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _viewAnnexure() async {
    if (widget.request.annexureUrl == null || widget.request.annexureUrl!.isEmpty) return;
    final Uri uri = Uri.parse(widget.request.annexureUrl!);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    final bool isOffice = user?.role == 'office';
    const primaryColor = Color(0xFF002366);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text("Application Details", 
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildDetailCard("Student Information", [
                    "Name: ${widget.request.studentName}",
                    "Roll No: ${widget.request.studentId}",
                    "Department: ${widget.request.department}",
                    "Year: ${widget.request.year ?? 'N/A'}",
                    "Class: ${widget.request.className}",
                  ]),
                  const SizedBox(height: 16),
                  _buildDetailCard("Request Purpose", [
                    "Category: ${widget.request.subject}",
                    "Status: ${widget.request.status.toUpperCase()}",
                    "Details: ${widget.request.body}",
                  ]),
                  const SizedBox(height: 24),
                  
                  if (widget.request.annexureUrl != null && widget.request.annexureUrl!.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _viewAnnexure,
                        icon: const Icon(Icons.visibility),
                        label: Text("VIEW ATTACHED ANNEXURE", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: const BorderSide(color: primaryColor),
                          foregroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 40),
                  if (isOffice && widget.request.approvalLevel == 4)
                    _buildOfficeAction()
                  else if (!isOffice)
                    _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildOfficeAction() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: _processIssuance,
        icon: const Icon(Icons.auto_fix_high),
        label: Text("GENERATE & ISSUE BONAFIDE", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade800,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, List<String> details) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17, color: const Color(0xFF002366))),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
          ...details.map((detail) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Text(detail, style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87)),
              )),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _handleAction(false),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("REJECT", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _handleAction(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("APPROVE", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
