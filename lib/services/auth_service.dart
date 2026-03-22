import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  /// Validates Student Login (Roll No + Password)
  Future<UserModel?> loginStudent(String rollNo, String password) async {
    try {
      print("Attempting Student Login: $rollNo");
      final QuerySnapshot result = await _db
          .collection('users') // Updated to lowercase 'users'
          .where('roll_no', isEqualTo: rollNo)
          .where('password', isEqualTo: password)
          .where('role', isEqualTo: 'student')
          .limit(1)
          .get();

      if (result.docs.isNotEmpty) {
        print("Student found!");
        _currentUser = UserModel.fromMap(
          result.docs.first.data() as Map<String, dynamic>,
          result.docs.first.id,
        );
        notifyListeners();
        return _currentUser;
      } else {
        print("No student document found with matching credentials in 'users' collection.");
      }
      return null;
    } catch (e) {
      print("CRITICAL Student Login Error: $e");
      return null;
    }
  }

  /// Validates Staff Login (Username + Password)
  Future<UserModel?> loginStaff(String username, String password) async {
    try {
      print("Attempting Staff Login: $username");
      final QuerySnapshot result = await _db
          .collection('users') // Updated to lowercase 'users'
          .where('username', isEqualTo: username)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      if (result.docs.isNotEmpty) {
        print("Staff member found!");
        UserModel user = UserModel.fromMap(
          result.docs.first.data() as Map<String, dynamic>,
          result.docs.first.id,
        );
        
        if (user.role == 'student') {
          print("User is a student, not staff.");
          return null;
        }

        _currentUser = user;
        notifyListeners();
        return _currentUser;
      } else {
        print("No staff document found with matching credentials in 'users' collection.");
      }
      return null;
    } catch (e) {
      print("CRITICAL Staff Login Error: $e");
      return null;
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
