import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleForgotPassword() async {
    final id = _idController.text.trim();
    if (id.isEmpty) {
      _showMessage("Please enter your Roll Number / Username");
      return;
    }

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);

    // 1. Verify User Exists
    final docId = await authService.verifyUserForReset(id);

    setState(() => _isLoading = false);

    if (docId != null) {
      // 2. Show OTP & New Password Dialog (Simulation for Review 1)
      if (mounted) {
        _showResetDialog(docId);
      }
    } else {
      _showMessage("User ID not found in records", isError: true);
    }
  }

  void _showResetDialog(String docId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Verify & Reset", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("An OTP has been sent to your registered contact. (Simulated)"),
            const SizedBox(height: 16),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(labelText: "Enter 6-digit OTP", border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              decoration: const InputDecoration(labelText: "New Password", border: OutlineInputBorder()),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              if (_otpController.text.length < 4) {
                _showMessage("Enter valid OTP");
                return;
              }
              final success = await Provider.of<AuthService>(context, listen: false)
                  .resetPassword(docId, _newPasswordController.text);
              
              if (mounted) {
                Navigator.pop(context); // Close dialog
                if (success) {
                  _showMessage("Password Reset Successfully!", isError: false);
                  Navigator.pop(context); // Go back to login
                } else {
                  _showMessage("Error resetting password", isError: true);
                }
              }
            },
            child: const Text("RESET PASSWORD"),
          ),
        ],
      ),
    );
  }

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF002366);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Reset Password", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_reset_rounded, size: 80, color: primaryColor),
              const SizedBox(height: 24),
              Text(
                "Forgot Your Password?",
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              const SizedBox(height: 16),
              const Text(
                "Enter your Roll Number or Username to receive a one-time password (OTP) for verification.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: 'Roll Number / Username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_search),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleForgotPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("SEND OTP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
