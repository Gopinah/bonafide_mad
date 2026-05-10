import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/database_service.dart';

class AnnexureUploadScreen extends StatefulWidget {
  final String requestId;
  const AnnexureUploadScreen({super.key, required this.requestId});

  @override
  State<AnnexureUploadScreen> createState() => _AnnexureUploadScreenState();
}

class _AnnexureUploadScreenState extends State<AnnexureUploadScreen> {
  final DatabaseService _db = DatabaseService();
  File? _selectedFile;
  bool _isUploading = false;
  String? _uploadedUrl;
  String? _fileType;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'pdf'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        int sizeInBytes = await file.length();
        
        // Strict 1MB Limit
        if (sizeInBytes > 1024 * 1024) {
          _showSnackBar("File size must be below 1 MB", isError: true);
          return;
        }

        setState(() {
          _selectedFile = file;
          _fileType = result.files.single.extension?.toLowerCase() == 'pdf' ? 'pdf' : 'image';
        });
      }
    } catch (e) {
      _showSnackBar("Error picking file: $e", isError: true);
    }
  }

  Future<void> _uploadAnnexure() async {
    if (_selectedFile == null) return;

    setState(() => _isUploading = true);

    try {
      String? url = await _db.uploadToCloudinary(_selectedFile!);
      
      if (url != null) {
        await _db.updateRequestWithAnnexure(
          requestId: widget.requestId,
          annexureUrl: url,
          fileType: _fileType!,
        );
        
        setState(() {
          _uploadedUrl = url;
          _isUploading = false;
        });
        
        _showSnackBar("Annexure uploaded successfully!");
      } else {
        throw "Upload failed";
      }
    } catch (e) {
      setState(() => _isUploading = false);
      _showSnackBar("Upload failed: $e", isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _viewAnnexure() async {
    if (_uploadedUrl == null) return;
    
    if (_fileType == 'pdf') {
      final Uri uri = Uri.parse(_uploadedUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(title: const Text("Annexure Preview"), leading: const CloseButton()),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.network(_uploadedUrl!),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Upload Annexure", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF002366),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Supported: JPG, JPEG, PDF (Max 1MB)",
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _isUploading ? null : _pickFile,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue.shade200, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.blue.shade50,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.blue.shade800),
                    const SizedBox(height: 8),
                    Text(
                      _selectedFile == null 
                          ? "Tap to select file" 
                          : _selectedFile!.path.split('/').last,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_isUploading)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Uploading to Cloudinary..."),
                ],
              )
            else if (_uploadedUrl == null)
              ElevatedButton(
                onPressed: _selectedFile != null ? _uploadAnnexure : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF002366),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("UPLOAD ANNEXURE", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            else
              Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _viewAnnexure,
                    icon: const Icon(Icons.visibility),
                    label: const Text("VIEW UPLOADED ANNEXURE"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
