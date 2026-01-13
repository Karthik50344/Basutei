import 'dart:async';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;

class BusLocationScreen extends StatefulWidget {
  final String busId;
  final String institute;
  final String name;
  const BusLocationScreen({super.key, required this.busId, required this.institute, required this.name});

  @override
  State<BusLocationScreen> createState() => _BusLocationScreenState();
}

class _BusLocationScreenState extends State<BusLocationScreen> {
  final databaseRef = FirebaseDatabase.instance.ref().child('buses');
  final MapController _mapController = MapController();
  Map<String, dynamic>? busData;
  LatLng? _lastLocation;
  bool _mapReady = false;
  bool _hasMovedOnce = false;
  StreamSubscription<DatabaseEvent>? _busDataSubscription;

  @override
  void initState() {
    super.initState();
    listenToBusData();
  }

  @override
  void dispose() {
    _busDataSubscription?.cancel();
    super.dispose();
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  void listenToBusData() {
    _busDataSubscription = databaseRef.child(widget.busId).onValue.listen((event) {
      if (!mounted) return; // Prevent setState if widget is gone

      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(
          (event.snapshot.value as Map<Object?, Object?>).map(
                (key, value) => MapEntry(key.toString(), value),
          ),
        );

        final latStr = data['location']?['lat'].toString() ?? '';
        final lngStr = data['location']?['lng'].toString() ?? '';
        final lat = double.tryParse(latStr) ?? 0.0;
        final lng = double.tryParse(lngStr) ?? 0.0;
        final currentLocation = LatLng(lat, lng);

        if (_mapReady &&
            (_lastLocation == null ||
                _lastLocation!.latitude != currentLocation.latitude ||
                _lastLocation!.longitude != currentLocation.longitude)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _mapController.move(currentLocation, _mapController.camera.zoom);
            }
          });
          _lastLocation = currentLocation;
        }

        if (mounted) {
          setState(() {
            busData = data;
          });
        }
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.busId} Tracking"),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: busData == null
          ? const Center(child: CircularProgressIndicator())
          : buildBusView(),
    );
  }

  Widget buildBusView() {
    final driver = busData!['driverName'] ?? 'N/A';
    final monitor = busData!['monitorName'] ?? 'N/A';
    final vehicleNumber = busData!['vehicleNumber'] ?? 'N/A';
    final model = busData!['vehicleModel'] ?? 'N/A';
    final lat = double.tryParse(busData!['location']?['lat'].toString() ?? '') ?? 0.0;
    final lng = double.tryParse(busData!['location']?['lng'].toString() ?? '') ?? 0.0;
    final mobile = busData!['monitorMobile'] ?? busData!['driverMobile'];
    final location = LatLng(lat, lng);
    final isRunning = busData!['isRunning'] ?? false;
    final route = busData!['routeIdentityNumber'].toString() ?? "";

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 8,
              children: [
                _infoItem("Driver", driver),
                _infoItem("Monitor", monitor),
                _infoItem("Vehicle Number", vehicleNumber),
                _infoItem("Model", model),
                _infoItem("Route", route),
                _infoItem("Status", isRunning ? "Running" : "Not Running", statusColor: isRunning ? Colors.green : Colors.red),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _makePhoneCall("+91$mobile"),
                      icon: const Icon(Icons.call),
                      label: const Text("Call"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: ()async {
                        final url = Uri.parse("https://busutei.onrender.com/send-alert");
                        final response = await http.post(
                          url,
                          headers: {"Content-Type": "application/json"},
                          body: jsonEncode({
                            "institute": widget.institute,
                            "bus": widget.busId,
                            "user": widget.name
                          }),
                        );

                        if (response.statusCode == 200) {
                          debugPrint("User updated successfully");
                        } else {
                          throw Exception("Failed to update user: ${response.body}");
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      child: const Text("Alert", style: TextStyle(color: Colors.white),),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text("Live Location", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text("Latitude: $lat, Longitude: $lng"),
        const SizedBox(height: 10),
        SizedBox(
          height: 300,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: location,
              initialZoom: 16,
              onMapReady: () {
                setState(() {
                  _mapReady = true;
                  if (!_hasMovedOnce) {
                    _mapController.move(location, 16);
                    _lastLocation = location;
                    _hasMovedOnce = true;
                  }
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 40,
                    height: 40,
                    point: location,
                    child: const Icon(Icons.location_pin, color: Colors.green, size: 40),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _infoItem(String title, String value, {Color statusColor = Colors.black}) {
    return SizedBox(
      width: 180,
      child: RichText(
        text: TextSpan(
          text: "$title: ",
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          children: [
            TextSpan(
              text: value,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }
}
