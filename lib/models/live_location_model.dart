class LiveLocationModel {
  final String busId;
  final double lat;
  final double lng;
  final double? speed;
  final double? bearing;
  final int updatedAt;
  final String? driverId;

  LiveLocationModel({
    required this.busId,
    required this.lat,
    required this.lng,
    this.speed,
    this.bearing,
    required this.updatedAt,
    this.driverId,
  });

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'speed': speed ?? 0,
      'bearing': bearing ?? 0,
      'updatedAt': updatedAt,
      'driverId': driverId,
    };
  }

  factory LiveLocationModel.fromJson(String busId, Map<dynamic, dynamic> json) {
    return LiveLocationModel(
      busId: busId,
      lat: double.tryParse(json['lat'].toString()) ?? 0.0,
      lng: double.tryParse(json['lng'].toString()) ?? 0.0,
      speed: double.tryParse(json['speed']?.toString() ?? '0') ?? 0,
      bearing: double.tryParse(json['bearing']?.toString() ?? '0') ?? 0,
      updatedAt: json['updatedAt'] ?? 0,
      driverId: json['driverId'],
    );
  }
}