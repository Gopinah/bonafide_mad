import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel {
  final String requestId;
  final String studentId;
  final String studentName;
  final String department;
  final String className;
  final String subject;
  final String body;
  final String? annexureUrl; 
  final String? certificateUrl;
  final String status; // pending, rejected, issued
  final int approvalLevel; // 1: Tutor, 2: HOD, 3: Principal, 4: Office
  final DateTime timestamp;
  final String? rejectionReason; // New field

  RequestModel({
    required this.requestId,
    required this.studentId,
    required this.studentName,
    required this.department,
    required this.className,
    required this.subject,
    required this.body,
    this.annexureUrl,
    this.certificateUrl,
    required this.status,
    required this.approvalLevel,
    required this.timestamp,
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
      annexureUrl: data['annexure_url'],
      certificateUrl: data['certificate_url'],
      status: data['status'] ?? 'pending',
      approvalLevel: data['approval_level'] ?? 1,
      rejectionReason: data['rejection_reason'],
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
      'annexure_url': annexureUrl,
      'certificate_url': certificateUrl,
      'status': status,
      'approval_level': approvalLevel,
      'rejection_reason': rejectionReason,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
