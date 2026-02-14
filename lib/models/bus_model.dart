class BusModel {
  final String busId;
  final String busNumber;
  final String instituteId;
  final String? driverId;
  final String? driverName;
  final String? driverMobile;
  final String? monitorId;
  final String? monitorName;
  final String? monitorMobile;
  final String? routeId;
  final String vehicleModel;
  final String vehicleNumber;
  final String status; // 'Active' or 'Not Active'
  final bool isActive;

  BusModel({
    required this.busId,
    required this.busNumber,
    required this.instituteId,
    this.driverId,
    this.driverName,
    this.driverMobile,
    this.monitorId,
    this.monitorName,
    this.monitorMobile,
    this.routeId,
    required this.vehicleModel,
    required this.vehicleNumber,
    required this.status,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'busNumber': busNumber,
      'instituteId': instituteId,
      'driverId': driverId,
      'driverName': driverName ?? '',
      'driverMobile': driverMobile ?? '',
      'monitorId': monitorId,
      'monitorName': monitorName ?? '',
      'monitorMobile': monitorMobile ?? '',
      'routeId': routeId,
      'vehicleModel': vehicleModel,
      'vehicleNumber': vehicleNumber,
      'status': status,
      'isActive': isActive,
    };
  }

  factory BusModel.fromJson(String busId, Map<dynamic, dynamic> json) {
    return BusModel(
      busId: busId,
      busNumber: json['busNumber'] ?? '',
      instituteId: json['instituteId'] ?? '',
      driverId: json['driverId'],
      driverName: json['driverName'],
      driverMobile: json['driverMobile'],
      monitorId: json['monitorId'],
      monitorName: json['monitorName'],
      monitorMobile: json['monitorMobile'],
      routeId: json['routeId'],
      vehicleModel: json['vehicleModel'] ?? '',
      vehicleNumber: json['vehicleNumber'] ?? '',
      status: json['status'] ?? 'Not Active',
      isActive: json['isActive'] ?? false,
    );
  }
}