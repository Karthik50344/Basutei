import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import '../database/database_paths.dart';
import '../models/user_model.dart';
import '../models/bus_model.dart';
import '../models/live_location_model.dart';
import '../models/route_model.dart';
import '../models/institute_model.dart';

class DatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
    'https://basutei-1aba3-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();

  // ==================== USER OPERATIONS ====================

  Future<void> createUser(UserModel user) async {
    await _db.child(DatabasePaths.userPath(user.uid)).set(user.toJson());

    // If user has a bus assigned, create user-bus mapping
    if (user.busId != null) {
      await _db.child(DatabasePaths.userBusMappingPath(user.uid)).set(user.busId);
    }
  }

  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    await _db.child(DatabasePaths.userPath(uid)).update(updates);

    // Update user-bus mapping if busId changed
    if (updates.containsKey('busId')) {
      if (updates['busId'] != null) {
        await _db.child(DatabasePaths.userBusMappingPath(uid)).set(updates['busId']);
      } else {
        await _db.child(DatabasePaths.userBusMappingPath(uid)).remove();
      }
    }
  }

  Future<void> deleteUser(String uid) async {
    await _db.child(DatabasePaths.userPath(uid)).remove();
    await _db.child(DatabasePaths.userBusMappingPath(uid)).remove();
  }

  Future<UserModel?> getUser(String uid) async {
    final snapshot = await _db.child(DatabasePaths.userPath(uid)).get();
    if (snapshot.exists) {
      return UserModel.fromJson(uid, snapshot.value as Map<dynamic, dynamic>);
    }
    return null;
  }

  Stream<List<UserModel>> getUsersByInstitute(String instituteId) {
    return _db.child(DatabasePaths.users)
        .orderByChild('instituteId')
        .equalTo(instituteId)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return data.entries
          .map((e) => UserModel.fromJson(e.key.toString(), e.value as Map<dynamic, dynamic>))
          .toList();
    });
  }

  // ==================== BUS OPERATIONS ====================

  Future<void> createBus(BusModel bus) async {
    await _db.child(DatabasePaths.busPath(bus.busId)).set(bus.toJson());
  }

  Future<void> updateBus(String busId, Map<String, dynamic> updates) async {
    await _db.child(DatabasePaths.busPath(busId)).update(updates);
  }

  Future<void> deleteBus(String busId) async {
    await _db.child(DatabasePaths.busPath(busId)).remove();
    await _db.child(DatabasePaths.liveLocationPath(busId)).remove();
  }

  Future<BusModel?> getBus(String busId) async {
    final snapshot = await _db.child(DatabasePaths.busPath(busId)).get();
    if (snapshot.exists) {
      return BusModel.fromJson(busId, snapshot.value as Map<dynamic, dynamic>);
    }
    return null;
  }

  Stream<List<BusModel>> getBusesByInstitute(String instituteId) {
    return _db.child(DatabasePaths.buses)
        .orderByChild('instituteId')
        .equalTo(instituteId)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return data.entries
          .map((e) => BusModel.fromJson(e.key.toString(), e.value as Map<dynamic, dynamic>))
          .toList();
    });
  }

  // ==================== LIVE LOCATION OPERATIONS ====================

  Future<void> updateLiveLocation(LiveLocationModel location) async {
    await _db.child(DatabasePaths.liveLocationPath(location.busId)).set(location.toJson());
  }

  Stream<LiveLocationModel?> getLiveLocation(String busId) {
    return _db.child(DatabasePaths.liveLocationPath(busId))
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        return LiveLocationModel.fromJson(busId, event.snapshot.value as Map<dynamic, dynamic>);
      }
      return null;
    });
  }

  Future<void> removeLiveLocation(String busId) async {
    await _db.child(DatabasePaths.liveLocationPath(busId)).remove();
  }

  // ==================== ROUTE OPERATIONS ====================

  Future<void> createRoute(RouteModel route) async {
    await _db.child(DatabasePaths.routePath(route.routeId)).set(route.toJson());
  }

  Future<void> updateRoute(String routeId, Map<String, dynamic> updates) async {
    await _db.child(DatabasePaths.routePath(routeId)).update(updates);
  }

  Future<void> deleteRoute(String routeId) async {
    await _db.child(DatabasePaths.routePath(routeId)).remove();
  }

  Future<RouteModel?> getRoute(String routeId) async {
    final snapshot = await _db.child(DatabasePaths.routePath(routeId)).get();
    if (snapshot.exists) {
      return RouteModel.fromJson(routeId, snapshot.value as Map<dynamic, dynamic>);
    }
    return null;
  }

  Stream<List<RouteModel>> getRoutesByInstitute(String instituteId) {
    return _db.child(DatabasePaths.routes)
        .orderByChild('instituteId')
        .equalTo(instituteId)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return data.entries
          .map((e) => RouteModel.fromJson(e.key.toString(), e.value as Map<dynamic, dynamic>))
          .toList();
    });
  }

  // ==================== INSTITUTE OPERATIONS ====================

  Future<void> createInstitute(InstituteModel institute) async {
    await _db.child(DatabasePaths.institutePath(institute.instituteId)).set(institute.toJson());
  }

  Future<InstituteModel?> getInstitute(String instituteId) async {
    final snapshot = await _db.child(DatabasePaths.institutePath(instituteId)).get();
    if (snapshot.exists) {
      return InstituteModel.fromJson(instituteId, snapshot.value as Map<dynamic, dynamic>);
    }
    return null;
  }

  // ==================== USER-BUS MAPPING ====================

  Future<String?> getUserBus(String uid) async {
    final snapshot = await _db.child(DatabasePaths.userBusMappingPath(uid)).get();
    if (snapshot.exists) {
      return snapshot.value.toString();
    }
    return null;
  }

  Stream<String?> watchUserBus(String uid) {
    return _db.child(DatabasePaths.userBusMappingPath(uid))
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        return event.snapshot.value.toString();
      }
      return null;
    });
  }

  // ==================== COMBINED OPERATIONS ====================

  /// Get bus details along with live location
  Stream<Map<String, dynamic>> getBusWithLiveLocation(String busId) {
    return _db.child(DatabasePaths.busPath(busId))
        .onValue
        .asyncMap((busEvent) async {
      if (!busEvent.snapshot.exists) {
        return {'bus': null, 'location': null};
      }

      final bus = BusModel.fromJson(busId, busEvent.snapshot.value as Map<dynamic, dynamic>);

      final locationSnapshot = await _db.child(DatabasePaths.liveLocationPath(busId)).get();
      LiveLocationModel? location;

      if (locationSnapshot.exists) {
        location = LiveLocationModel.fromJson(
            busId,
            locationSnapshot.value as Map<dynamic, dynamic>
        );
      }

      return {'bus': bus, 'location': location};
    });
  }

  /// Assign driver/monitor to bus
  Future<void> assignUserToBus(String uid, String busId, String role) async {
    final updates = <String, dynamic>{
      'assignedBusId': busId,
    };

    await updateUser(uid, updates);

    // Update bus with driver/monitor info
    final user = await getUser(uid);
    if (user != null) {
      final busUpdates = <String, dynamic>{};

      if (role == 'driver') {
        busUpdates['driverId'] = uid;
        busUpdates['driverName'] = user.name;
        busUpdates['driverMobile'] = user.mobile;
      } else if (role == 'monitor') {
        busUpdates['monitorId'] = uid;
        busUpdates['monitorName'] = user.name;
        busUpdates['monitorMobile'] = user.mobile;
      }

      await updateBus(busId, busUpdates);
    }
  }

  /// Remove user from bus
  Future<void> removeUserFromBus(String uid, String busId, String role) async {
    await updateUser(uid, {'assignedBusId': null});

    final busUpdates = <String, dynamic>{};

    if (role == 'driver') {
      busUpdates['driverId'] = null;
      busUpdates['driverName'] = '';
      busUpdates['driverMobile'] = '';
    } else if (role == 'monitor') {
      busUpdates['monitorId'] = null;
      busUpdates['monitorName'] = '';
      busUpdates['monitorMobile'] = '';
    }

    await updateBus(busId, busUpdates);
  }
}