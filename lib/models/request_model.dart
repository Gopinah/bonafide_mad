import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel {
  final String requestId;
  final String studentId;
  final String studentName;
  final String department;
  final String className;
  final String subject;
  final String body;
  final String status;
  final int approvalLevel;
  final DateTime timestamp;

  // ADD THIS
  final String? rejectionReason;

  RequestModel({
    required this.requestId,
    required this.studentId,
    required this.studentName,
    required this.department,
    required this.className,
    required this.subject,
    required this.body,
    required this.status,
    required this.approvalLevel,
    required this.timestamp,

    // ADD THIS
    this.rejectionReason,
  });

  factory RequestModel.fromMap(Map<String, dynamic> data, String id) {
    return RequestModel(
      requestId: id,
      studentId: data['student_id'] ?? '',
      studentName: data['student_name'] ?? '',
      department: data['department'] ?? '',
      className: data['class'] ?? '',
      subject: data['subject'] ?? '',
      body: data['body'] ?? '',
      status: data['status'] ?? 'pending',
      approvalLevel: data['approval_level'] ?? 1,

      // ADD THIS
      rejectionReason: data['rejectionReason'],

      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'student_id': studentId,
      'student_name': studentName,
      'department': department,
      'class': className,
      'subject': subject,
      'body': body,
      'status': status,
      'approval_level': approvalLevel,

      // ADD THIS
      'rejectionReason': rejectionReason,

      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}