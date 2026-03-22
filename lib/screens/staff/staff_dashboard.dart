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

    // Principal and Office are global roles
    final bool isGlobal = user?.role == 'principal' || user?.role == 'office';

    return Scaffold(
      appBar: AppBar(
        title: Text('${user?.role.toUpperCase()} Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthService>(context, listen: false).logout();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome, ${user?.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (!isGlobal) 
                  Text('Dept: ${user?.department} ${user?.className != null ? "- ${user?.className}" : ""}'),
                if (isGlobal)
                  const Text('Institution Level Access', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              user?.role == 'office' ? 'Requests Ready for Issuance' : 'Requests Pending for Approval',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<RequestModel>>(
              stream: db.getStaffRequests(user!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No requests found."));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final req = snapshot.data![index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(req.studentName),
                        subtitle: Text("Subject: ${req.subject}\nDate: ${DateFormat('dd MMM yyyy').format(req.timestamp)}"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RequestDetailScreen(request: req),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
