import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/request_model.dart';
import 'request_detail_screen.dart';

class StaffDashboard extends StatelessWidget {
  const StaffDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    final db = DatabaseService();
    const primaryColor = Color(0xFF002366);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('${user?.role.toUpperCase()} Dashboard', 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
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
          
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 10),
                Text(
                  user?.role == 'office' ? "Approved Requests for Issuance" : "Pending Approvals",
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<RequestModel>>(
              stream: db.getPendingStaffRequests(user!),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (snapshot.connectionState == ConnectionState.waiting) 
                  return const Center(child: CircularProgressIndicator(color: primaryColor));
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
          Text(user?.name ?? "Staff", 
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("Dept: ${user?.department} | ${user?.role.toUpperCase()}", 
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checklist_rtl_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text("All caught up!", style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(req.studentName, 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF002366))),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("Subject: ${req.subject}", style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87)),
            Text("Applied: ${DateFormat('dd MMM yyyy').format(req.timestamp)}", 
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF002366), size: 16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RequestDetailScreen(request: req)),
        ),
      ),
    );
  }
}
