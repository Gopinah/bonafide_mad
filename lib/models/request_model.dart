import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel {
  final String requestId;
  final int approvalLevel;
  final String body;
  final String className;
  final String department;
  final String status;
  final String studentId;
  final String studentName;
  final String subject;
  final DateTime timestamp;
  
  // Fields
  final String? year;
  final String? reason;
  final String? annexureUrl;
  final String? annexureFileType;
  final String? bonafideImageUrl; // REPLACED bonafide_pdf_url
  final DateTime? uploadedAt;
  final DateTime? issuedAt;
  final String? rejectionReason;

  RequestModel({
    required this.requestId,
    required this.approvalLevel,
    required this.body,
    required this.className,
    required this.department,
    required this.status,
    required this.studentId,
    required this.studentName,
    required this.subject,
    required this.timestamp,
    this.year,
    this.reason,
    this.annexureUrl,
    this.annexureFileType,
    this.bonafideImageUrl,
    this.uploadedAt,
    this.issuedAt,
    this.rejectionReason,
  });

  factory RequestModel.fromMap(Map<String, dynamic> data, String id) {
    return RequestModel(
      requestId: id,
      approvalLevel: data['approval_level'] ?? 1,
      body: data['body'] ?? '',
      className: data['class'] ?? '',
      department: data['department'] ?? '',
      status: data['status'] ?? 'Pending',
      studentId: data['student_id'] ?? '',
      studentName: data['student_name'] ?? '',
      subject: data['subject'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      year: data['year'],
      reason: data['reason'],
      annexureUrl: data['annexure_url'],
      annexureFileType: data['annexure_file_type'],
      // Support both field names during transition
      bonafideImageUrl: data['bonafide_image_url'] ?? data['bonafide_pdf_url'],
      uploadedAt: (data['uploaded_at'] as Timestamp?)?.toDate(),
      issuedAt: (data['issued_at'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'approval_level': approvalLevel,
      'body': body,
      'class': className,
      'department': department,
      'status': status,
      'student_id': studentId,
      'student_name': studentName,
      'subject': subject,
      'timestamp': FieldValue.serverTimestamp(),
      'year': year,
      'reason': reason,
      'annexure_url': annexureUrl,
      'annexure_file_type': annexureFileType,
      'bonafide_image_url': bonafideImageUrl,
      'uploaded_at': uploadedAt != null ? Timestamp.fromDate(uploadedAt!) : null,
      'issued_at': issuedAt != null ? Timestamp.fromDate(issuedAt!) : null,
      'rejectionReason': rejectionReason,
    };
  }
}
