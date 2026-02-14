// lib/database/database_paths.dart
class DatabasePaths {
  // Root nodes
  static const String institutes = 'institutes';
  static const String users = 'Users';
  static const String buses = 'buses';
  static const String routes = 'routes';
  static const String liveLocations = 'liveLocations';
  static const String userBusMapping = 'userBusMapping';

  // Helper methods for constructing paths
  static String userPath(String uid) => '$users/$uid';
  static String busPath(String busId) => '$buses/$busId';
  static String routePath(String routeId) => '$routes/$routeId';
  static String liveLocationPath(String busId) => '$liveLocations/$busId';
  static String institutePath(String instituteId) => '$institutes/$instituteId';
  static String userBusMappingPath(String uid) => '$userBusMapping/$uid';
}