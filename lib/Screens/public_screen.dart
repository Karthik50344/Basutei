// lib/Screens/public_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/bus_model.dart';
import 'live_bus_route.dart';
import 'login_screen.dart';

class PublicScreen extends StatefulWidget {
  final String institute;
  final String name;
  final String uid;
  const PublicScreen({
    super.key,
    required this.institute,
    required this.name,
    required this.uid
  });

  @override
  State<PublicScreen> createState() => _PublicScreenState();
}

class _PublicScreenState extends State<PublicScreen> {
  final _dbService = DatabaseService();

  List<BusModel> buses = [];
  List<BusModel> filteredBuses = [];
  String? userAssignedBus;

  final TextEditingController busSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBuses();
    _loadUserBus();

    busSearchController.addListener(
            () => _filterList(busSearchController.text)
    );
  }

  void _loadBuses() {
    _dbService.getBusesByInstitute(widget.institute).listen((busData) {
      setState(() {
        buses = busData;
        filteredBuses = busData;
      });
    });
  }

  void _loadUserBus() {
    _dbService.watchUserBus(widget.uid).listen((busId) {
      setState(() {
        userAssignedBus = busId;
      });
    });
  }

  void _filterList(String query) {
    query = query.toLowerCase();
    setState(() {
      filteredBuses = buses.where((bus) {
        return bus.busId.toLowerCase().contains(query) ||
            bus.busNumber.toLowerCase().contains(query) ||
            (bus.driverName?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  void _logout(BuildContext context) async {
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
        appBar: AppBar(
          backgroundColor: Colors.green,
          title: const Text("Bus Tracking"),
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
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // User info card
              if (userAssignedBus != null)
                Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.green),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                  "Your Assigned Bus",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16
                                  )
                              ),
                              Text(
                                  userAssignedBus!,
                                  style: const TextStyle(fontSize: 14)
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BusLocationScreen(
                                  busId: userAssignedBus!,
                                  institute: widget.institute,
                                  name: widget.name,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text(
                              "Track",
                              style: TextStyle(color: Colors.white)
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              // Buses GroupBox
              Expanded(
                child: GroupBox(
                  name: widget.name,
                  institute: widget.institute,
                  title: "All Buses",
                  searchController: busSearchController,
                  items: filteredBuses,
                  userAssignedBus: userAssignedBus,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GroupBox extends StatelessWidget {
  final String title;
  final TextEditingController searchController;
  final List<BusModel> items;
  final String institute;
  final String name;
  final String? userAssignedBus;

  const GroupBox({
    super.key,
    required this.title,
    required this.searchController,
    required this.items,
    required this.institute,
    required this.name,
    this.userAssignedBus,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.grey[200],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 10),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                fillColor: Colors.white,
                filled: true,
                labelText: "Search $title",
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final bus = items[index];
                  final isUserBus = bus.busId == userAssignedBus;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BusLocationScreen(
                            busId: bus.busId,
                            institute: institute,
                            name: name,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isUserBus ? Colors.green[100] : Colors.white,
                          border: Border.all(
                            color: isUserBus ? Colors.green : Colors.black,
                            width: isUserBus ? 3 : 2,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.directions_bus,
                            color: isUserBus ? Colors.green : Colors.grey,
                          ),
                          title: Row(
                            children: [
                              Text(
                                  bus.busId,
                                  style: TextStyle(
                                      fontWeight: isUserBus
                                          ? FontWeight.bold
                                          : FontWeight.normal
                                  )
                              ),
                              if (isUserBus) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                      "My Bus",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10
                                      )
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                              "Driver: ${bus.driverName ?? 'N/A'}, "
                                  "Number: ${bus.busNumber}"
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                bus.status == "Active"
                                    ? Icons.check_circle
                                    : Icons.build_circle,
                                color: bus.status == "Active"
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              if (bus.isActive)
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}