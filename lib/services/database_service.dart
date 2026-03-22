import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../models/request_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 1. Get all requests for a specific student
  Stream<List<RequestModel>> getStudentRequests(String studentId) {
    return _db
        .collection('requests')
        .where('student_id', isEqualTo: studentId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // 2. Get requests for Staff based on Role/Dept/Class
  Stream<List<RequestModel>> getStaffRequests(UserModel user) {
    // Only fetch requests with 'pending' status
    Query query = _db.collection('requests').where('status', isEqualTo: 'pending');

    if (user.role == 'tutor') {
      query = query
          .where('department', isEqualTo: user.department)
          .where('class', isEqualTo: user.className)
          .where('approval_level', isEqualTo: 1);
    } else if (user.role == 'hod') {
      query = query
          .where('department', isEqualTo: user.department)
          .where('approval_level', isEqualTo: 2);
    } else if (user.role == 'principal') {
      query = query.where('approval_level', isEqualTo: 3);
    } else if (user.role == 'office') {
      query = query.where('approval_level', isEqualTo: 4);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => RequestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // 3. Update Request Status (Approve/Reject with Reason)
  Future<void> updateRequestStatus(String requestId, int currentLevel, bool isApproved, {String? reason}) async {
    if (isApproved) {
      await _db.collection('requests').doc(requestId).update({
        'approval_level': currentLevel + 1,
      });
    } else {
      await _db.collection('requests').doc(requestId).update({
        'status': 'rejected',
        'rejection_reason': reason ?? 'No reason provided',
      });
    }
  }

  // 4. Upload Certificate (Office Staff)
  Future<void> issueCertificate(String requestId, PlatformFile file) async {
    try {
      String fileName = 'cert_${DateTime.now().millisecondsSinceEpoch}.pdf';
      Reference ref = _storage.ref().child('certificates/$fileName');
      UploadTask uploadTask = file.bytes != null ? ref.putData(file.bytes!) : ref.putFile(File(file.path!));
      TaskSnapshot snapshot = await uploadTask;
      String url = await snapshot.ref.getDownloadURL();
      await _db.collection('requests').doc(requestId).update({
        'certificate_url': url,
        'status': 'issued',
      });
    } catch (e) {
      print("Issue Cert Error: $e");
    }
  }

  // 5. Upload Annexure (Student)
  Future<String?> uploadAnnexure(PlatformFile file, String studentId) async {
    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      Reference ref = _storage.ref().child('annexures/$studentId/$fileName');
      UploadTask uploadTask = file.bytes != null ? ref.putData(file.bytes!) : ref.putFile(File(file.path!));
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // 6. Create New Request
  Future<bool> createRequest({
    required UserModel student,
    required String subject,
    required String body,
    String? annexureUrl,
  }) async {
    try {
      await _db.collection('requests').add({
        'student_id': student.userId,
        'student_name': student.name,
        'department': student.department,
        'class': student.className,
        'subject': subject,
        'body': body,
        'annexure_url': annexureUrl,
        'status': 'pending',
        'approval_level': 1,
        'timestamp': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
