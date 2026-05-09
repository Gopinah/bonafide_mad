import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../student/student_dashboard.dart';
import '../staff/staff_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isStudentLogin = true;
  bool _isLoading = false;

  void _toggleLoginType() {
    setState(() {
      _isStudentLogin = !_isStudentLogin;
      _idController.clear();
      _passwordController.clear();
    });
  }

  void _login() async {
    if (_idController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError("Please fill all fields");
      return;
    }
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    try {
      dynamic user = _isStudentLogin 
          ? await authService.loginStudent(_idController.text.trim(), _passwordController.text.trim())
          : await authService.loginStaff(_idController.text.trim(), _passwordController.text.trim());
      
      setState(() => _isLoading = false);
      
      if (user != null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => _isStudentLogin ? const StudentDashboard() : const StaffDashboard()),
          );
        }
      } else {
        if (mounted) {
          _showError("Invalid Credentials");
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showError("Connection error. Please try again.");
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF002366);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                child: const Icon(Icons.assignment_turned_in_rounded, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text("BONAPRO", style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor)),
              const SizedBox(height: 48),
              Text(_isStudentLogin ? "Student Login" : "Staff Login", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 32),
              TextField(
                controller: _idController,
                decoration: InputDecoration(
                  labelText: _isStudentLogin ? 'Roll Number' : 'Username',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("LOGIN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _toggleLoginType,
                child: Text(_isStudentLogin ? "Switch to Staff Login" : "Switch to Student Login", style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
