import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/request_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Cloudinary Config
  final String cloudName = "dkb54bmsq";
  final String uploadPreset = "bonafide_upload";

  // --- Cloudinary Upload Helper ---
  
  /// Fixes Cloudinary URLs for PDFs to avoid ERR_INVALID_RESPONSE.
  /// PDFs must be served from the /raw/ path, not /image/.
  static String fixCloudinaryUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    String fixed = url;
    if (url.toLowerCase().contains('.pdf') && url.contains('/image/upload/')) {
      fixed = url.replaceFirst('/image/upload/', '/raw/upload/');
    }
    // Ensure URL has .pdf extension for browser recognition if it's a Cloudinary raw resource
    if (fixed.contains('/raw/upload/') && !fixed.toLowerCase().endsWith('.pdf') && !fixed.contains('?')) {
       fixed = "$fixed.pdf";
    }
    return fixed;
  }

  /// Uploads file to Cloudinary and returns a VALID secure URL.
  /// CRITICAL: To prevent ERR_INVALID_RESPONSE on PDFs, we MUST:
  /// 1. Use the /raw/upload endpoint for PDFs.
  /// 2. Set resource_type = raw.
  /// 3. Force the /raw/ path in the final URL.
  Future<String?> uploadToCloudinary(File file) async {
    try {
      final bool isPdf = file.path.toLowerCase().endsWith('.pdf');
      final String resourceType = isPdf ? 'raw' : 'image';
      
      final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload");
      
      final request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = uploadPreset
        ..fields['resource_type'] = resourceType
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        String secureUrl = jsonResponse['secure_url'];
        
        // Final forced correction before returning
        return fixCloudinaryUrl(secureUrl);
      } else {
        print("Cloudinary Upload Failed: $responseBody");
        return null;
      }
    } catch (e) {
      print("Error uploading to Cloudinary: $e");
      return null;
    }
  }

  // --- Firestore Methods ---

  /// Fetch ALL requests for a specific student (Real-time)
  /// Using student_id (Auth UID) as the primary filter.
  Stream<List<RequestModel>> getStudentRequests(String uid) {
    return _db
        .collection('requests')
        .where('student_id', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => RequestModel.fromMap(doc.data(), doc.id))
              .toList();
          // Sort in memory to avoid Index requirements
          items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return items;
        });
  }

  /// Fetch Pending requests for authorities (Tutor, HOD, Principal, Office)
  Stream<List<RequestModel>> getPendingStaffRequests(UserModel user) {
    return _db.collection('requests')
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => RequestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .where((req) {
                // Levels: 1:Tutor, 2:HOD, 3:Principal, 4:Office
                if (user.role == 'tutor') return req.department == user.department && req.approvalLevel == 1;
                if (user.role == 'hod') return req.department == user.department && req.approvalLevel == 2;
                if (user.role == 'principal') return req.approvalLevel == 3;
                if (user.role == 'office') return req.approvalLevel == 4;
                return false;
              })
              .toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        });
  }

  /// Student creates a new request
  Future<void> createBonafideRequest(Map<String, dynamic> data) async {
    await _db.collection('requests').add({
      ...data,
      'timestamp': FieldValue.serverTimestamp(),
      'approval_level': 1,
      'status': 'Pending',
    });
  }

  /// Update approval level or reject
  Future<void> updateRequestStatus(String requestId, int currentLevel, bool isApproved, {String? reason}) async {
    if (isApproved) {
      // Moves to next level.
      await _db.collection('requests').doc(requestId).update({
        'approval_level': currentLevel + 1,
      });
    } else {
      await _db.collection('requests').doc(requestId).update({
        'status': 'Rejected',
        'rejectionReason': reason,
      });
    }
  }

  /// Final Issuance logic (Office completion)
  Future<void> finalizeIssuance(String docId, String pdfUrl) async {
    await _db.collection('requests').doc(docId).update({
      'bonafide_pdf_url': pdfUrl,
      'issued_at': FieldValue.serverTimestamp(),
      'status': 'Issued',
      'approval_level': 5, // Fully Issued
    });
  }

  /// Update content of the request (used for office edits)
  Future<void> updateRequestBody(String docId, String newBody) async {
    await _db.collection('requests').doc(docId).update({
      'body': newBody,
    });
  }
}
