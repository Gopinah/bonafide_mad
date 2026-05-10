import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

class RequestFormScreen extends StatefulWidget {
  const RequestFormScreen({super.key});

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _bodyController = TextEditingController();
  
  String? _selectedYear;
  String? _selectedReason;
  File? _annexureFile;
  bool _isUploading = false;
  String? _fileType;

  final Color primaryColor = const Color(0xFF002366);
  
  final List<String> _years = ['I Year', 'II Year', 'III Year', 'IV Year', 'V Year'];
  final List<String> _reasons = [
    'Bus Pass',
    'Scholarship',
    'Bank Loan',
    'Hostel',
    'Passport',
    'Internship',
    'Visa',
    'Education Loan',
    'Railway Concession',
    'Other'
  ];

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        int sizeInBytes = await file.length();
        
        if (sizeInBytes > 1024 * 1024) {
          _showSnackBar("File size must be below 1 MB", isError: true);
          return;
        }

        setState(() {
          _annexureFile = file;
          _fileType = result.files.single.extension?.toLowerCase() == 'pdf' ? 'pdf' : 'image';
        });
      }
    } catch (e) {
      _showSnackBar("Error picking file: $e", isError: true);
    }
  }

  Future<void> _previewLocalFile() async {
    if (_annexureFile == null) return;
    
    if (_fileType == 'pdf') {
      final Uri uri = Uri.file(_annexureFile!.path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showSnackBar("Cannot open PDF preview locally. It will be viewable after submission.");
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text("Annexure Preview", style: GoogleFonts.poppins(fontSize: 16)),
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                leading: const CloseButton(),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_annexureFile!, fit: BoxFit.contain),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_annexureFile == null) {
      _showSnackBar("Please upload an annexure", isError: true);
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      final db = DatabaseService();

      // Submit to Cloudinary
      String? url = await db.uploadToCloudinary(_annexureFile!);
      
      if (url == null) throw "Upload failed. Please check internet.";

      String body = _bodyController.text.trim();
      if (body.isEmpty) {
        body = "Formal request for $_selectedReason certificate for academic year 2024-25.";
      }

      await db.createBonafideRequest({
        'student_id': user?.userId ?? '', 
        'student_name': user?.name ?? 'Unknown',
        'roll_no': user?.rollNo ?? '', 
        'department': user?.department ?? 'General',
        'class': user?.className ?? '',
        'year': _selectedYear,
        'reason': _selectedReason,
        'subject': _selectedReason, 
        'body': body,
        'annexure_url': url,
        'annexure_file_type': _fileType,
        'uploaded_at': DateTime.now(),
      });

      if (mounted) {
        _showSnackBar("Request Submitted Successfully!");
        Navigator.of(context).pop(); 
      }
    } catch (e) {
      setState(() => _isUploading = false);
      _showSnackBar("Error: $e", isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("Apply for Bonafide", 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(user),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Academic Year"),
                    const SizedBox(height: 12),
                    _buildYearDropdown(),
                    const SizedBox(height: 24),
                    
                    _buildSectionTitle("Purpose of Bonafide"),
                    const SizedBox(height: 12),
                    _buildReasonDropdown(),
                    const SizedBox(height: 24),

                    _buildSectionTitle("Additional Details (Optional)"),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bodyController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Enter any specific details...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildSectionTitle("Supporting Documents (Annexure)"),
                    const SizedBox(height: 12),
                    _buildFilePicker(),
                    
                    const SizedBox(height: 48),
                    if (_isUploading)
                      const Center(child: CircularProgressIndicator(color: Color(0xFF002366)))
                    else
                      _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      decoration: const BoxDecoration(
        color: Color(0xFF002366),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(35), bottomRight: Radius.circular(35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user?.name ?? "", style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text("Roll No: ${user?.rollNo ?? ''}", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
          Text("Dept: ${user?.department} • Class: ${user?.className}", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, 
      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor));
  }

  Widget _buildYearDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedYear,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      hint: const Text("Select Year"),
      items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
      onChanged: (val) => setState(() => _selectedYear = val),
      validator: (val) => val == null ? "Please select year" : null,
    );
  }

  Widget _buildReasonDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedReason,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      hint: const Text("Select Purpose"),
      items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
      onChanged: (val) => setState(() => _selectedReason = val),
      validator: (val) => val == null ? "Please select purpose" : null,
    );
  }

  Widget _buildFilePicker() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Icon(Icons.attach_file, color: primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: _isUploading ? null : _pickFile,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_annexureFile == null ? "Select Annexure" : _annexureFile!.path.split('/').last,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 14),
                    overflow: TextOverflow.ellipsis),
                  Text("Required for verification", style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ),
          if (_annexureFile != null)
            TextButton(
              onPressed: _previewLocalFile,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: const Size(0, 0),
                backgroundColor: primaryColor.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text("VIEW", 
                style: GoogleFonts.poppins(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    bool canSubmit = _annexureFile != null && !_isUploading;

    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: canSubmit ? _submitRequest : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          disabledBackgroundColor: Colors.grey.shade300,
          elevation: canSubmit ? 2 : 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text("SUBMIT REQUEST", 
          style: GoogleFonts.poppins(
            color: canSubmit ? Colors.white : Colors.grey, 
            fontWeight: FontWeight.bold, 
            fontSize: 16)),
      ),
    );
  }
}
