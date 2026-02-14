class InstituteModel {
  final String instituteId;
  final String name;
  final String address;
  final String contact;
  final int createdAt;

  InstituteModel({
    required this.instituteId,
    required this.name,
    required this.address,
    required this.contact,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'contact': contact,
      'createdAt': createdAt,
    };
  }

  factory InstituteModel.fromJson(String instituteId, Map<dynamic, dynamic> json) {
    return InstituteModel(
      instituteId: instituteId,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      contact: json['contact'] ?? '',
      createdAt: json['createdAt'] ?? 0,
    );
  }
}