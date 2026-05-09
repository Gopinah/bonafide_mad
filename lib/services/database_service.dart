import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  Stream<List<RequestModel>> getStaffRequests(UserModel user) {
    Query query = _db.collection('requests').where('status', isEqualTo: 'pending');

    if (user.role == 'tutor') {
      query = query
          .where('department', isEqualTo: user.department)
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

    query = query.orderBy('timestamp', descending: false);

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => RequestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  Future<void> updateRequestStatus(String requestId, int currentLevel, bool isApproved) async {
    if (isApproved) {
      await _db.collection('requests').doc(requestId).update({
        'approval_level': currentLevel + 1,
        if (currentLevel == 4) 'status': 'issued'
      });
    } else {
      await _db.collection('requests').doc(requestId).update({
        'status': 'rejected',
      });
    }
  }

  Future<bool> createRequest({
    required UserModel student,
    required String subject,
    required String body,
  }) async {
    try {
      await _db.collection('requests').add({
        'student_id': student.userId,
        'student_name': student.name,
        'department': student.department,
        'class': student.className,
        'subject': subject,
        'body': body,
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
