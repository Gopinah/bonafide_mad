// This file is currently disabled as PDF functionality has been removed to fix build errors.
import 'package:flutter/material.dart';

class CertificateEditorScreen extends StatelessWidget {
  const CertificateEditorScreen({super.key, required this.request});
  final dynamic request;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("System Update")),
      body: const Center(
        child: Text("PDF Generation is currently disabled for maintenance."),
      ),
    );
  }
}
