import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/request_model.dart';
import '../../services/certificate_service.dart';
import '../../services/database_service.dart';

class CertificateEditorScreen extends StatefulWidget {
  final RequestModel request;

  const CertificateEditorScreen({super.key, required this.request});

  @override
  State<CertificateEditorScreen> createState() => _CertificateEditorScreenState();
}

class _CertificateEditorScreenState extends State<CertificateEditorScreen> {
  late TextEditingController _bodyController;
  bool _isProcessing = false;
  File? _previewFile;

  @override
  void initState() {
    super.initState();
    // Pre-populate the template with retrieved student details
    _bodyController = TextEditingController(
      text: "This is to certify that Mr./Ms. ${widget.request.studentName} (Roll No: ${widget.request.studentId}) "
            "is a bonafide student of ${widget.request.department}, Class ${widget.request.className} "
            "at PSG COLLEGE OF TECHNOLOGY, Coimbatore, during the Academic year 2024-2025. "
            "This certificate is issued for the purpose of ${widget.request.subject}."
    );
  }

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _generatePreview() async {
    setState(() => _isProcessing = true);
    try {
      final file = await CertificateService.generateCertificateImage(
        widget.request,
        customBody: _bodyController.text,
      );
      setState(() {
        _previewFile = file;
        _isProcessing = false;
      });
      _showPreviewDialog();
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError("Preview failed: $e");
    }
  }

  void _showPreviewDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text("Certificate Preview (Image)"),
              backgroundColor: const Color(0xFF002366),
              foregroundColor: Colors.white,
              leading: const CloseButton(),
            ),
            if (_previewFile != null)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InteractiveViewer(
                    child: Image.file(_previewFile!),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("CLOSE"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _issueBonafide();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: const Text("CONFIRM & ISSUE"),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _issueBonafide() async {
    setState(() => _isProcessing = true);
    final db = DatabaseService();
    try {
      // 1. Generate the final image with the edited text
      final imageFile = await CertificateService.generateCertificateImage(
        widget.request,
        customBody: _bodyController.text,
      );

      // 2. Upload to Cloudinary (image/upload)
      final imageUrl = await db.uploadToCloudinary(imageFile);

      if (imageUrl != null) {
        // 3. Update Firestore with the new image URL and status
        await db.finalizeIssuance(widget.request.requestId, imageUrl);
        
        if (mounted) {
          Navigator.pop(context); // Close Editor
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Certificate Image Issued Successfully!"), backgroundColor: Colors.green),
          );
        }
      } else {
        throw "Cloudinary upload failed";
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showError("Issuance failed: $e");
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF002366);
    return Scaffold(
      appBar: AppBar(
        title: Text("Issue Bonafide", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Edit Certificate Content", 
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                  const SizedBox(height: 15),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                      ),
                      child: TextField(
                        controller: _bodyController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: GoogleFonts.poppins(fontSize: 15, height: 1.6),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.all(20),
                          border: InputBorder.none,
                          hintText: "Enter certificate body text...",
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _generatePreview,
                          icon: const Icon(Icons.remove_red_eye_outlined),
                          label: const Text("PREVIEW IMAGE"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            side: const BorderSide(color: primaryColor),
                            foregroundColor: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _issueBonafide,
                          icon: const Icon(Icons.verified_outlined),
                          label: const Text("ISSUE NOW"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade800,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
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
}
