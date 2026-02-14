class RouteStop {
  final String name;
  final double lat;
  final double lng;

  RouteStop({
    required this.name,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lat': lat,
      'lng': lng,
    };
  }

  factory RouteStop.fromJson(Map<dynamic, dynamic> json) {
    return RouteStop(
      name: json['name'] ?? '',
      lat: double.tryParse(json['lat'].toString()) ?? 0.0,
      lng: double.tryParse(json['lng'].toString()) ?? 0.0,
    );
  }
}

class RouteModel {
  final String routeId;
  final String name;
  final String instituteId;
  final Map<String, RouteStop> stops;

  RouteModel({
    required this.routeId,
    required this.name,
    required this.instituteId,
    required this.stops,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'instituteId': instituteId,
      'stops': stops.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  factory RouteModel.fromJson(String routeId, Map<dynamic, dynamic> json) {
    final stopsJson = json['stops'] as Map<dynamic, dynamic>? ?? {};
    final stops = <String, RouteStop>{};

    stopsJson.forEach((key, value) {
      stops[key.toString()] = RouteStop.fromJson(value as Map<dynamic, dynamic>);
    });

    return RouteModel(
      routeId: routeId,
      name: json['name'] ?? '',
      instituteId: json['instituteId'] ?? '',
      stops: stops,
    );
  }
}