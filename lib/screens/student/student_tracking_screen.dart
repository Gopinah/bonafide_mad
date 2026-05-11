import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/request_model.dart';

class StudentTrackingScreen extends StatelessWidget {
  const StudentTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    final db = DatabaseService();
    final Color primaryColor = const Color(0xFF002366);

    // Standardized identifier
    final String studentId = user?.userId ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("Track My Bonafide", 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<RequestModel>>(
        stream: db.getStudentRequests(studentId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_edu_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text("No requests found", 
                    style: GoogleFonts.poppins(color: Colors.grey, fontSize: 18)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final req = snapshot.data![index];
              return _buildTrackingCard(context, req, primaryColor);
            },
          );
        },
      ),
    );
  }

  Widget _buildTrackingCard(BuildContext context, RequestModel req, Color primaryColor) {
    final String status = req.status;
    final String? imageUrl = req.bonafideImageUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(req.subject, 
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: primaryColor)),
                ),
                _buildStatusChip(status),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.calendar_today, "Applied on", 
              DateFormat('dd MMM yyyy, hh:mm a').format(req.timestamp)),
            
            if (req.uploadedAt != null)
              _buildInfoRow(Icons.upload_file, "Annexure Uploaded", 
                DateFormat('dd MMM yyyy').format(req.uploadedAt!)),

            if (status == 'Issued' && req.issuedAt != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.verified, "Issued on", 
                DateFormat('dd MMM yyyy, hh:mm a').format(req.issuedAt!)),
            ],
            
            const Divider(height: 32),
            
            if (status == 'Issued' && imageUrl != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _viewCertificate(context, imageUrl),
                  icon: const Icon(Icons.remove_red_eye),
                  label: const Text("VIEW CERTIFICATE IMAGE", 
                    style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )
            else if (status == 'Rejected')
              Center(
                child: Text("Status: Rejected. Reason: ${req.rejectionReason ?? 'Contact Office'}",
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
              )
            else
              Center(
                child: Text(
                  status == 'Approved' 
                    ? "Approved! Office is preparing your certificate image." 
                    : "Authorities are currently verifying your request.",
                  style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadCertificate(BuildContext context, String url) async {
    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Downloading certificate...")),
        );
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;
        final result = await ImageGallerySaver.saveImage(
          bytes,
          quality: 100,
          name: "Bonafide_${DateTime.now().millisecondsSinceEpoch}",
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Certificate saved to gallery successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception("Failed to download image");
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  void _viewCertificate(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text("Bonafide Certificate", style: GoogleFonts.poppins(fontSize: 16)),
              backgroundColor: const Color(0xFF002366),
              foregroundColor: Colors.white,
              leading: const CloseButton(),
              actions: [
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _downloadCertificate(context, url),
                ),
              ],
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: InteractiveViewer(
                  child: Image.network(
                    url,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) => const Center(child: Text("Error loading image")),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Approved': color = Colors.green; break;
      case 'Rejected': color = Colors.red; break;
      case 'Issued': color = Colors.blue; break;
      default: color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: color)
      ),
      child: Text(status.toUpperCase(), 
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }
}
