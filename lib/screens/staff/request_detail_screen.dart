import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
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
    String? reason;
    if (!isApproved) {
      // Show dialog to get rejection reason
      reason = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Rejection Reason"),
          content: TextField(
            controller: _reasonController,
            decoration: const InputDecoration(hintText: "Enter reason for rejection"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            TextButton(
              onPressed: () => Navigator.pop(context, _reasonController.text.trim()),
              child: const Text("Submit"),
            ),
          ],
        ),
      );
      if (reason == null || reason.isEmpty) return;
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
            content: Text(isApproved ? "Request Approved" : "Request Rejected"),
            backgroundColor: isApproved ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error updating request"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleOfficeIssue() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() => _isProcessing = true);
      final db = DatabaseService();
      try {
        await db.issueCertificate(widget.request.requestId, result.files.first);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Certificate Issued Successfully"), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error issuing certificate"), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
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

    return Scaffold(
      appBar: AppBar(title: const Text("Request Details")),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard("Student Info", [
                    "Name: ${widget.request.studentName}",
                    "Department: ${widget.request.department}",
                    "Class: ${widget.request.className}",
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoCard("Request Content", [
                    "Subject: ${widget.request.subject}",
                    "Body: ${widget.request.body}",
                  ]),
                  if (widget.request.annexureUrl != null) ...[
                    const SizedBox(height: 20),
                    const Text("Annexure:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        debugPrint("Opening Annexure: ${widget.request.annexureUrl}");
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.description, color: Colors.blue),
                            SizedBox(width: 8),
                            Text("View Annexure Document", style: TextStyle(color: Colors.blue)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      if (!isOffice)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleAction(false),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text("REJECT"),
                          ),
                        ),
                      if (!isOffice) const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isOffice ? _handleOfficeIssue : () => _handleAction(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isOffice ? Colors.green : Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(isOffice ? "UPLOAD & ISSUE" : "APPROVE"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(String title, List<String> details) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
            const Divider(),
            ...details.map((detail) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(detail, style: const TextStyle(fontSize: 15)),
                )),
          ],
        ),
      ),
    );
  }
}
