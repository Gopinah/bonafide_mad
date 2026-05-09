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

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
