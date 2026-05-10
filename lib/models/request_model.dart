import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel {
  final String requestId;
  final int approvalLevel;
  final String body;
  final String className;
  final String department;
  final String status;
  final String studentId; // Consistent identifier (Roll No)
  final String studentName;
  final String subject;
  final DateTime timestamp;
  
  // New Fields
  final String? year;
  final String? reason;
  final String? annexureUrl;
  final String? annexureFileType;
  final String? bonafidePdfUrl;
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
    this.bonafidePdfUrl,
    this.uploadedAt,
    this.issuedAt,
    this.rejectionReason,
  });

  /// CRITICAL: Fixes Cloudinary URLs for PDFs to avoid ERR_INVALID_RESPONSE
  /// Forces /raw/ path and ensures browser compatibility for mobile browsers
  static String _fixUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    String fixed = url;
    if (url.toLowerCase().contains('.pdf')) {
       // PDFs must be served through the /raw/ endpoint, not /image/
       if (url.contains('/image/upload/')) {
         fixed = url.replaceFirst('/image/upload/', '/raw/upload/');
       }
       // Append .pdf extension if it's missing in a raw upload path
       if (fixed.contains('/raw/upload/') && !fixed.toLowerCase().endsWith('.pdf')) {
         fixed = "$fixed.pdf";
       }
    }
    return fixed;
  }

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
      annexureUrl: _fixUrl(data['annexure_url']),
      annexureFileType: data['annexure_file_type'],
      bonafidePdfUrl: _fixUrl(data['bonafide_pdf_url']),
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
      'bonafide_pdf_url': bonafidePdfUrl,
      'uploaded_at': uploadedAt != null ? Timestamp.fromDate(uploadedAt!) : null,
      'issued_at': issuedAt != null ? Timestamp.fromDate(issuedAt!) : null,
      'rejectionReason': rejectionReason,
    };
  }
}
