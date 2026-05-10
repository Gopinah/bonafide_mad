import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/request_model.dart';

class StudentTrackingScreen extends StatelessWidget {
  const StudentTrackingScreen({super.key});

  Future<void> _openPdf(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error opening bonafide PDF: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    final db = DatabaseService();
    final Color primaryColor = const Color(0xFF002366);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("Track My Bonafide", 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<RequestModel>>(
        stream: db.getStudentRequests(user?.userId ?? ""),
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
                  Text("No bonafide requests yet", 
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
                _buildStatusChip(req.status),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.calendar_today, "Applied on", 
              DateFormat('dd MMM yyyy, hh:mm a').format(req.timestamp)),
            
            if (req.uploadedAt != null)
              _buildInfoRow(Icons.upload_file, "Annexure Uploaded", 
                DateFormat('dd MMM yyyy').format(req.uploadedAt!)),

            if (req.status == 'Issued' && req.issuedAt != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.verified, "Issued on", 
                DateFormat('dd MMM yyyy, hh:mm a').format(req.issuedAt!)),
            ],
            
            const Divider(height: 32),
            
            if (req.status == 'Issued' && req.bonafidePdfUrl != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openPdf(req.bonafidePdfUrl!),
                  icon: const Icon(Icons.download_for_offline),
                  label: const Text("DOWNLOAD BONAFIDE PDF", 
                    style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )
            else if (req.status == 'Rejected')
              Center(
                child: Text("Status: Rejected. Reason: ${req.rejectionReason ?? 'Contact Office'}",
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
              )
            else
              Center(
                child: Text(
                  req.status == 'Approved' 
                    ? "Approved! Office is preparing your certificate." 
                    : "Office is currently verifying your request.",
                  style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
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
