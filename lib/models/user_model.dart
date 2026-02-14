class UserModel {
  final String uid;
  final String name;
  final String email;
  final String mobile;
  final String role; // 'admin', 'driver', 'monitor', 'student', 'parent'
  final String instituteId;
  final String? assignedBusId; // for drivers/monitors
  final String? busId; // for students
  final String? childId; // for parents
  final String? fcmToken;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.mobile,
    required this.role,
    required this.instituteId,
    this.assignedBusId,
    this.busId,
    this.childId,
    this.fcmToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'mobile': mobile,
      'role': role,
      'instituteId': instituteId,
      'assignedBusId': assignedBusId,
      'busId': busId,
      'childId': childId,
      'fcmToken': fcmToken ?? '',
    };
  }

  factory UserModel.fromJson(String uid, Map<dynamic, dynamic> json) {
    return UserModel(
      uid: uid,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      role: json['role'] ?? 'student',
      instituteId: json['instituteId'] ?? '',
      assignedBusId: json['assignedBusId'],
      busId: json['busId'],
      childId: json['childId'],
      fcmToken: json['fcmToken'],
    );
  }
}