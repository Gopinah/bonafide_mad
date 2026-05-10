import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/request_model.dart';
import 'request_form_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    final db = DatabaseService();
    const primaryColor = Color(0xFF002366);

    // FIX: Using user.userId (unique document ID) to match the 'student_id' field in Firestore
    final String studentIdentifier = user?.userId ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('My Applications', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Provider.of<AuthService>(context, listen: false).logout();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          )
        ],
      ),
      body: Column(
        children: [
          _buildHeader(user),
          Expanded(
            child: StreamBuilder<List<RequestModel>>(
              stream: db.getStudentRequests(studentIdentifier),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: primaryColor));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final req = snapshot.data![index];
                    return _buildRequestCard(context, req);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RequestFormScreen()),
        ),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildHeader(user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: const BoxDecoration(
        color: Color(0xFF002366),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(35), bottomRight: Radius.circular(35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user?.name ?? "Student", style: GoogleFonts.poppins(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("${user?.department} | ${user?.className ?? user?.rollNo}", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, RequestModel req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
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
                  child: Text(req.subject, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20, color: const Color(0xFF002366))),
                ),
                _buildStatusBadge(req.status),
              ],
            ),
            const SizedBox(height: 6),
            Text("Applied: ${DateFormat('dd MMM yyyy').format(req.timestamp)}", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
            _buildStatusTracker(req.approvalLevel, req.status),
            if (req.status == 'Issued' && req.bonafidePdfUrl != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openUrl(req.bonafidePdfUrl!),
                  icon: const Icon(Icons.download, size: 20),
                  label: Text("Download Certificate", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            if (req.status == 'Rejected') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                child: Text("Reason: ${req.rejectionReason ?? 'N/A'}", style: TextStyle(color: Colors.red.shade800, fontSize: 13)),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    if (status == 'Approved' || status == 'Issued') color = const Color(0xFF4CAF50);
    if (status == 'Rejected') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildStatusTracker(int currentLevel, String status) {
    final steps = ["Tutor", "HOD", "Principal", "Office"];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Application Status Tracker", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
        const SizedBox(height: 12),
        Row(
          children: List.generate(steps.length, (index) {
            int stepLevel = index + 1;
            bool isCompleted = stepLevel < currentLevel || (status == 'Issued' && stepLevel == 4) || (status == 'Approved' && stepLevel == 4);
            bool isCurrent = stepLevel == currentLevel && status != 'Issued' && status != 'Approved';
            
            Color stepColor = Colors.grey.shade300;
            if (status == 'Rejected') {
              if (stepLevel < currentLevel) stepColor = Colors.green;
              else if (stepLevel == currentLevel) stepColor = Colors.red;
            } else {
              if (isCompleted) stepColor = Colors.green;
              else if (isCurrent) stepColor = Colors.orange;
            }

            return Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: stepColor, borderRadius: BorderRadius.circular(6)),
                    child: Text(steps[index], style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  if (index != steps.length - 1)
                    Expanded(child: Container(height: 2, color: isCompleted ? Colors.green : Colors.grey.shade300)),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text("No applications found", style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
