// lib/Screens/driver_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:basutei/resources.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/live_location_model.dart';
import 'login_screen.dart';
import 'package:http/http.dart' as http;

class DriverScreen extends StatefulWidget {
  final String institute;
  final String bus;
  const DriverScreen({super.key, required this.institute, required this.bus});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  bool isSharing = false;
  Position? currentPosition;
  Timer? locationTimer;
  final _dbService = DatabaseService();

  @override
  void dispose() {
    locationTimer?.cancel();
    super.dispose();
  }

  Future<void> getLocationAndUpdate() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (!serviceEnabled || permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) return;
    }

    try {
      currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {});

      // Update live location in separate node
      final location = LiveLocationModel(
        busId: widget.bus,
        lat: currentPosition!.latitude,
        lng: currentPosition!.longitude,
        speed: currentPosition!.speed,
        bearing: currentPosition!.heading,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        driverId: FirebaseAuth.instance.currentUser?.uid,
      );

      await _dbService.updateLiveLocation(location);
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  void startSharing() async {
    setState(() {
      isSharing = true;
    });

    // Update bus status
    await _dbService.updateBus(widget.bus, {'isActive': true});

    getLocationAndUpdate();
    locationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      getLocationAndUpdate();
    });
  }

  void stopSharing() async {
    setState(() {
      isSharing = false;
    });

    locationTimer?.cancel();

    // Update bus status and remove live location
    await _dbService.updateBus(widget.bus, {'isActive': false});
    await _dbService.removeLiveLocation(widget.bus);
  }

  void _logout(BuildContext context) async {
    // Stop sharing before logout
    if (isSharing) {
      stopSharing();
    }

    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  Future<bool> _onWillPop(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout Confirmation"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Yes"),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _onWillPop(context).then((confirmed) {
        if (confirmed) {
          _logout(context);
          return false;
        }
        return false;
      }),
      child: Scaffold(
        backgroundColor: const Color(0xffE3F7F9),
        appBar: AppBar(
          backgroundColor: Colors.green,
          title: const Text("Driver"),
          titleTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20
          ),
          centerTitle: true,
          actions: [
            IconButton(
              color: Colors.white,
              icon: const Icon(Icons.logout),
              onPressed: () => _onWillPop(context).then((confirmed) {
                if (confirmed) _logout(context);
              }),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xff037c7c),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                        "Location Tracking Tool",
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white
                        )
                    ),
                    const SizedBox(height: 4),
                    const Text(
                        "Real-time Bus Location Sharing",
                        style: TextStyle(fontSize: 16, color: Colors.white70)
                    ),
                    const SizedBox(height: 8),
                    Text(
                        "Bus: ${widget.bus}",
                        style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w500
                        )
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)
                ),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.radio_button_checked, color: Color(0xff037c7c)),
                          SizedBox(width: 8),
                          Text(
                              "Live Location",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text("LATITUDE", style: TextStyle(color: Colors.teal)),
                              Text(
                                  currentPosition?.latitude.toStringAsFixed(6) ?? "--",
                                  style: const TextStyle(fontSize: 18)
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Text("LONGITUDE", style: TextStyle(color: Colors.teal)),
                              Text(
                                  currentPosition?.longitude.toStringAsFixed(6) ?? "--",
                                  style: const TextStyle(fontSize: 18)
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Status: ${isSharing ? "Actively Sharing" : "Not Sharing"}",
                        style: TextStyle(
                            color: isSharing ? Colors.green : Colors.red
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: isSharing ? stopSharing : startSharing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSharing ? Colors.red : const Color(0xff037c7c),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)
                  ),
                ),
                child: Text(
                  isSharing ? "Stop Sharing" : "Start Sharing Location",
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final url = Uri.parse("https://busutei.onrender.com/send_sos");
                    final response = await http.post(
                      url,
                      headers: {"Content-Type": "application/json"},
                      body: jsonEncode({
                        "institute": widget.institute,
                        "busId": widget.bus
                      }),
                    );

                    if (response.statusCode == 200) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("SOS sent successfully"))
                        );
                      }
                    } else {
                      throw Exception("Failed to send SOS: ${response.body}");
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error sending SOS: $e"))
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)
                  ),
                ),
                child: const Text(
                  "SOS",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const Spacer(),
              Image.asset(ImageResource.busImage, height: 200),
            ],
          ),
        ),
      ),
    );
  }
}