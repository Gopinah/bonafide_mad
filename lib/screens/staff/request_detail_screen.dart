import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/request_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

class RequestDetailScreen extends StatefulWidget {
  final RequestModel request;

  const RequestDetailScreen({super.key, required this.request});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  bool _isProcessing = false;
  final _reasonController = TextEditingController();

  Future<void> _handleAction(bool isApproved) async {
    setState(() => _isProcessing = true);
    final db = DatabaseService();
    
    try {
      await db.updateRequestStatus(
        widget.request.requestId,
        widget.request.approvalLevel,
        isApproved,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isApproved ? "Application Approved" : "Application Rejected"),
            backgroundColor: isApproved ? Colors.green.shade700 : Colors.red.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error updating status"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    final bool isOffice = user?.role == 'office';
    const primaryColor = Color(0xFF002366);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Application Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildDetailCard("Student Information", [
                    "Name: ${widget.request.studentName}",
                    "Roll No: ${widget.request.studentId}",
                    "Department: ${widget.request.department}",
                    "Class: ${widget.request.className}",
                  ]),
                  const SizedBox(height: 16),
                  _buildDetailCard("Request Purpose", [
                    "Category: ${widget.request.subject}",
                    "Status: ${widget.request.status.toUpperCase()}",
                  ]),
                  const SizedBox(height: 40),
                  _buildActionButtons(isOffice),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailCard(String title, List<String> details) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF002366))),
          const Divider(height: 20),
          ...details.map((detail) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(detail, style: const TextStyle(fontSize: 15)),
              )),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isOffice) {
    if (isOffice) {
       return const Center(child: Text("Waiting for final issuance processing (System Update Pending)", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)));
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _handleAction(false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              foregroundColor: Colors.white,
            ),
            child: const Text("REJECT"),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _handleAction(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text("APPROVE"),
          ),
        ),
      ],
    );
  }
}
