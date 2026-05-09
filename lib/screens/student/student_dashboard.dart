import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/request_model.dart';
import 'request_form_screen.dart';
import 'package:intl/intl.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    final db = DatabaseService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('My Applications', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF002366),
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
              stream: db.getStudentRequests(user!.userId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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
        backgroundColor: const Color(0xFF002366),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF002366),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user?.name ?? "Student", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text("${user?.department} | ${user?.className}", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text("No applications found", style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, RequestModel req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(req.subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF002366))),
                ),
                _buildStatusBadge(req.status),
              ],
            ),
            const SizedBox(height: 8),
            Text("Applied: ${DateFormat('dd MMM yyyy').format(req.timestamp)}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            
            const Divider(height: 24),
            
            if (req.status == 'issued')
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Certificate Issued (Available at Office)", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ),
              )
            else
              _buildStatusTracker(req.approvalLevel, req.status),
            
            if (req.status == 'rejected')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: _buildRejectionPanel(context, req),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    if (status == 'issued') color = Colors.green;
    if (status == 'rejected') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  Widget _buildRejectionPanel(BuildContext context, RequestModel req) {
    String authority = "Authority";
    if (req.approvalLevel == 1) authority = "Tutor";
    else if (req.approvalLevel == 2) authority = "HOD";
    else if (req.approvalLevel == 3) authority = "Principal";

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              const Icon(Icons.cancel, color: Colors.red),
              const SizedBox(width: 12),
              const Expanded(child: Text("Application Rejected", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
              TextButton(
                onPressed: () => _showRejectionDialog(context, authority, req.rejectionReason ?? "N/A"),
                child: const Text("VIEW REASON", style: TextStyle(color: Colors.red, decoration: TextDecoration.underline, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showRejectionDialog(BuildContext context, String authority, String reason) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rejection Details", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Rejected By: $authority", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text("Reason:", style: TextStyle(color: Colors.grey)),
            Text(reason, style: const TextStyle(fontSize: 16)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE"))],
      ),
    );
  }

  Widget _buildStatusTracker(int currentLevel, String status) {
    final steps = ["Tutor", "HOD", "Principal", "Office"];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Application Status Tracker", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 12),
        Row(
          children: List.generate(steps.length, (index) {
            int stepLevel = index + 1;
            bool isApproved = stepLevel < currentLevel;
            bool isCurrent = stepLevel == currentLevel;
            
            Color stepColor = Colors.grey.shade300;
            if (status == 'rejected') {
              if (isApproved) stepColor = Colors.green;
              else if (isCurrent) stepColor = Colors.red;
            } else {
              if (isApproved) stepColor = Colors.green;
              else if (isCurrent) stepColor = Colors.orange;
            }

            return Expanded(
              child: Row(
                children: [
                  Tooltip(
                    message: isApproved ? "Approved" : (isCurrent ? (status == 'rejected' ? "Rejected here" : "Waiting for approval") : "Pending"),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: stepColor, borderRadius: BorderRadius.circular(4)),
                      child: Text(steps[index], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (index != steps.length - 1)
                    Expanded(child: Container(height: 2, color: isApproved ? Colors.green : Colors.grey.shade300)),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
