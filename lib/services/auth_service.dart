import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  Future<UserModel?> loginStudent(String rollNo, String password) async {
    try {
      final QuerySnapshot result = await _db
          .collection('users')
          .where('roll_no', isEqualTo: rollNo)
          .where('password', isEqualTo: password)
          .where('role', isEqualTo: 'student')
          .limit(1)
          .get();

      if (result.docs.isNotEmpty) {
        _currentUser = UserModel.fromMap(
          result.docs.first.data() as Map<String, dynamic>,
          result.docs.first.id,
        );
        notifyListeners();
        return _currentUser;
      }
      return null;
    } catch (e) {
      debugPrint("Login Error: $e");
      rethrow;
    }
  }

  Future<UserModel?> loginStaff(String username, String password) async {
    try {
      final QuerySnapshot result = await _db
          .collection('users')
          .where('username', isEqualTo: username)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      if (result.docs.isNotEmpty) {
        UserModel user = UserModel.fromMap(
          result.docs.first.data() as Map<String, dynamic>,
          result.docs.first.id,
        );
        if (user.role == 'student') return null;
        _currentUser = user;
        notifyListeners();
        return _currentUser;
      }
      return null;
    } catch (e) {
      debugPrint("Login Error: $e");
      rethrow;
    }
  }

  // --- RESTORED FORGOT PASSWORD METHODS ---

  /// Verifies if a user exists for password reset purposes.
  Future<String?> verifyUserForReset(String id) async {
    try {
      // Check students (roll_no)
      final studentCheck = await _db.collection('users').where('roll_no', isEqualTo: id).get();
      if (studentCheck.docs.isNotEmpty) return studentCheck.docs.first.id;

      // Check staff (username)
      final staffCheck = await _db.collection('users').where('username', isEqualTo: id).get();
      if (staffCheck.docs.isNotEmpty) return staffCheck.docs.first.id;

      return null;
    } catch (e) {
      debugPrint("Verify User Error: $e");
      return null;
    }
  }

  /// Resets the user's password in Firestore.
  Future<bool> resetPassword(String docId, String newPassword) async {
    try {
      await _db.collection('users').doc(docId).update({'password': newPassword});
      return true;
    } catch (e) {
      debugPrint("Reset Password Error: $e");
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
