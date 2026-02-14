// lib/Screens/live_bus_route.dart
import 'dart:async';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/database_service.dart';
import '../models/bus_model.dart';
import '../models/live_location_model.dart';
import 'package:http/http.dart' as http;

class BusLocationScreen extends StatefulWidget {
  final String busId;
  final String institute;
  final String name;
  const BusLocationScreen({
    super.key,
    required this.busId,
    required this.institute,
    required this.name
  });

  @override
  State<BusLocationScreen> createState() => _BusLocationScreenState();
}

class _BusLocationScreenState extends State<BusLocationScreen> {
  final _dbService = DatabaseService();
  final MapController _mapController = MapController();

  BusModel? busData;
  LiveLocationModel? liveLocation;
  LatLng? _lastLocation;
  bool _mapReady = false;
  bool _hasMovedOnce = false;

  StreamSubscription<Map<String, dynamic>>? _busSubscription;
  StreamSubscription<LiveLocationModel?>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _listenToBusData();
    _listenToLiveLocation();
  }

  @override
  void dispose() {
    _busSubscription?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  void _listenToBusData() {
    _busSubscription = _dbService.getBusWithLiveLocation(widget.busId)
        .listen((data) {
      if (!mounted) return;

      setState(() {
        busData = data['bus'] as BusModel?;
        // Initial location from combined stream
        if (data['location'] != null) {
          liveLocation = data['location'] as LiveLocationModel;
        }
      });
    });
  }

  void _listenToLiveLocation() {
    _locationSubscription = _dbService.getLiveLocation(widget.busId)
        .listen((location) {
      if (!mounted) return;

      if (location != null) {
        final currentLocation = LatLng(location.lat, location.lng);

        if (_mapReady &&
            (_lastLocation == null ||
                _lastLocation!.latitude != currentLocation.latitude ||
                _lastLocation!.longitude != currentLocation.longitude)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _mapController.move(
                  currentLocation,
                  _mapController.camera.zoom
              );
            }
          });
          _lastLocation = currentLocation;
        }

        setState(() {
          liveLocation = location;
        });
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: busData == null
          ? const Center(child: CircularProgressIndicator())
          : buildBusView(),
    );
  }

  Widget buildBusView() {
    final driver = busData!.driverName ?? 'N/A';
    final monitor = busData!.monitorName ?? 'N/A';
    final vehicleNumber = busData!.vehicleNumber;
    final model = busData!.vehicleModel;
    final driverMobile = busData!.driverMobile ?? '';
    final monitorMobile = busData!.monitorMobile ?? '';
    final isActive = busData!.isActive;
    final busNumber = busData!.busNumber;

    final lat = liveLocation?.lat ?? 0.0;
    final lng = liveLocation?.lng ?? 0.0;
    final location = LatLng(lat, lng);

    // Prefer monitor mobile, fallback to driver
    final contactMobile = monitorMobile.isNotEmpty ? monitorMobile : driverMobile;

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
                _infoItem("Bus Number", busNumber),
                _infoItem(
                    "Status",
                    isActive ? "Running" : "Not Running",
                    statusColor: isActive ? Colors.green : Colors.red
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (contactMobile.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () => _makePhoneCall("+91$contactMobile"),
                        icon: const Icon(Icons.call),
                        label: const Text("Call"),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          final url = Uri.parse(
                              "https://busutei.onrender.com/send-alert"
                          );
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
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Alert sent successfully")
                                  )
                              );
                            }
                          } else {
                            throw Exception(
                                "Failed to send alert: ${response.body}"
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: $e"))
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange
                      ),
                      child: const Text(
                        "Alert",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
            "Live Location",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
        ),
        Text("Latitude: $lat, Longitude: $lng"),
        if (liveLocation != null) ...[
          Text("Speed: ${liveLocation!.speed?.toStringAsFixed(2) ?? '0'} m/s"),
          Text(
              "Last Updated: ${DateTime.fromMillisecondsSinceEpoch(liveLocation!.updatedAt)}"
          ),
        ],
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
                    child: const Icon(
                        Icons.location_pin,
                        color: Colors.green,
                        size: 40
                    ),
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

  Widget _infoItem(
      String title,
      String value,
      {Color statusColor = Colors.black}
      ) {
    return SizedBox(
      width: 180,
      child: RichText(
        text: TextSpan(
          text: "$title: ",
          style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold
          ),
          children: [
            TextSpan(
              text: value,
              style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.normal
              ),
            ),
          ],
        ),
      ),
    );
  }
}