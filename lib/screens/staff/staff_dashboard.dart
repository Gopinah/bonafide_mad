import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/request_model.dart';
import 'package:intl/intl.dart';
import 'request_detail_screen.dart';

class StaffDashboard extends StatelessWidget {
  const StaffDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    final db = DatabaseService();

    final bool isGlobal = user?.role == 'principal' || user?.role == 'office';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('${user?.role.toUpperCase()} Dashboard', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
          _buildHeader(user, isGlobal),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                user?.role == 'office' ? 'Requests Ready for Issuance' : 'Pending Approvals',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF002366)),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<RequestModel>>(
              stream: db.getStaffRequests(user!),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // This will now show the Index Error in the UI
                  return _buildErrorState(snapshot.error.toString());
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
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

  Widget _buildHeader(user, bool isGlobal) {
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
          Text(
            user?.name ?? "Staff",
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          if (!isGlobal) ...[
            const SizedBox(height: 5),
            Text(
              "Dept: ${user?.department} ${user?.className != null ? "| Class: ${user?.className}" : ""}",
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.done_all_rounded, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text("No pending requests", style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    bool isIndexError = error.contains("requires an index");
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 60, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              isIndexError ? "Database Index Required" : "Something went wrong",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              isIndexError 
                ? "Please check your terminal logs and click the link to create a Firestore Index. This is necessary for sorting to work."
                : error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, RequestModel req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          req.studentName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF002366)),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text("Subject: ${req.subject}"),
            Text("Applied: ${DateFormat('dd MMM yyyy').format(req.timestamp)}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF002366), size: 18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RequestDetailScreen(request: req)),
        ),
      ),
    );
  }
}
