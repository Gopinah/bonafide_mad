import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/request_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String cloudName = "dkb54bmsq";
  static const String uploadPreset = "bonafide_upload";

  /// Fixes Cloudinary URLs for forced download or viewing.
  static String fixCloudinaryUrl(String? url, {bool forceDownload = false}) {
    if (url == null || url.isEmpty) return "";
    if (!url.contains("cloudinary.com")) return url;
    if (forceDownload) {
      return url.replaceAll("/upload/", "/upload/fl_attachment/");
    }
    return url;
  }

  /// Uploads file to Cloudinary using image/upload endpoint.
  Future<String?> uploadToCloudinary(File file) async {
    try {
      final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
      final request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        return jsonResponse['secure_url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Stream<List<RequestModel>> getStudentRequests(String uid) {
    return _db.collection('requests')
        .where('student_id', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RequestModel.fromMap(doc.data(), doc.id))
            .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp)));
  }

  Stream<List<RequestModel>> getPendingStaffRequests(UserModel user) {
    return _db.collection('requests')
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RequestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .where((req) {
              if (user.role == 'tutor') return req.department == user.department && req.approvalLevel == 1;
              if (user.role == 'hod') return req.department == user.department && req.approvalLevel == 2;
              if (user.role == 'principal') return req.approvalLevel == 3;
              if (user.role == 'office') return req.approvalLevel == 4;
              return false;
            }).toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp)));
  }

  Future<void> createBonafideRequest(Map<String, dynamic> data) async {
    await _db.collection('requests').add({
      ...data,
      'timestamp': FieldValue.serverTimestamp(),
      'approval_level': 1,
      'status': 'Pending',
    });
  }

  /// RESTORED: Updates a request with an annexure link.
  Future<void> updateRequestWithAnnexure({
    required String requestId,
    required String annexureUrl,
    required String fileType,
  }) async {
    await _db.collection('requests').doc(requestId).update({
      'annexure_url': annexureUrl,
      'annexure_file_type': fileType,
      'uploaded_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateRequestStatus(String requestId, int currentLevel, bool isApproved, {String? reason}) async {
    if (isApproved) {
      await _db.collection('requests').doc(requestId).update({'approval_level': currentLevel + 1});
    } else {
      await _db.collection('requests').doc(requestId).update({
        'status': 'Rejected',
        'rejectionReason': reason,
      });
    }
  }

  Future<void> finalizeIssuance(String docId, String imageUrl) async {
    await _db.collection('requests').doc(docId).update({
      'bonafide_image_url': imageUrl,
      'issued_at': FieldValue.serverTimestamp(),
      'status': 'Issued',
      'approval_level': 5,
    });
  }

  Future<void> updateRequestBody(String docId, String newBody) async {
    await _db.collection('requests').doc(docId).update({'body': newBody});
  }
}
