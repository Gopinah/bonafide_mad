class UserModel {
  final String userId;
  final String name;
  final String role; // student, tutor, hod, principal, office
  final String department;
  final String? className; // G1 or G2 (null for global staff)
  final String? rollNo;    // for students
  final String? username;  // for staff
  final String password;

  UserModel({
    required this.userId,
    required this.name,
    required this.role,
    required this.department,
    this.className,
    this.rollNo,
    this.username,
    required this.password,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      userId: id,
      name: data['name'] ?? 'No Name',
      role: data['role'] ?? '',
      department: data['department'] ?? '',
      className: data['class'],
      rollNo: data['roll_no'],
      username: data['username'],
      password: data['password'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'department': department,
      'class': className,
      'roll_no': rollNo,
      'username': username,
      'password': password,
    };
  }
}
