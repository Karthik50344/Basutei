import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'live_bus_route.dart';
import 'login_screen.dart';

class PublicScreen extends StatefulWidget {
  final String institute;
  final String name;
  const PublicScreen({super.key, required this.institute, required this.name});

  @override
  State<PublicScreen> createState() => _PublicScreenState();
}

class _PublicScreenState extends State<PublicScreen> {
  // Firebase refs
  final DatabaseReference busesRef = FirebaseDatabase.instance.ref().child('buses');

  // Data storage
  Map<dynamic, dynamic> buses = {};
  Map<dynamic, dynamic> filteredBuses = {};

  // Search controllers
  final TextEditingController busSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBuses();

    busSearchController.addListener(() => _filterList(busSearchController.text, isBus: true));
  }

  void _loadBuses() {
    busesRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final filtered = <dynamic, dynamic>{};
      data.forEach((key, value) {
        final bus = value as Map<dynamic, dynamic>;
        if (bus['institute'] == widget.institute) {
          filtered[key] = bus;
        }
      });
      setState(() {
        buses = filtered;
        filteredBuses = filtered;
      });
    });
  }

  void _filterList(String query, {required bool isBus}) {
    query = query.toLowerCase();
    if (isBus) {
      setState(() {
        filteredBuses = buses
            .map((key, value) => MapEntry(key, value))
          ..removeWhere((key, _) => !key.toLowerCase().contains(query));
      });
    }
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
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
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _onWillPop(context).then((confirmed) {
        if (confirmed) {
          _logout(context);
          return false; // prevent default back behavior
        }
        return false;
      }),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green,
          title: const Text("Public"),
          titleTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontSize: 20),
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
              // Buses GroupBox
              GroupBox(
                name: widget.name,
                institute: widget.institute,
                title: "Buses",
                searchController: busSearchController,
                items: filteredBuses,
                itemBuilder: (key, value) {
                  final bus = value as Map;
                  return ListTile(
                    title: Text(key),
                    subtitle: Text("Driver: ${bus['driverName']}, Monitor: ${bus['monitorName']}"),
                    trailing: bus['Status'] == "Active" ? const Icon(Icons.check_circle, color: Colors.green,) : const Icon(Icons.build_circle, color: Colors.red,)
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable GroupBox widget
class GroupBox extends StatelessWidget {
  final String title;
  final TextEditingController searchController;
  final Map<dynamic, dynamic> items;
  final Widget Function(dynamic key, dynamic value) itemBuilder;
  final String institute;
  final String name;

  const GroupBox({
    super.key,
    required this.title,
    required this.searchController,
    required this.items,
    required this.itemBuilder,
    required this.institute,
    required this.name
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 4,
        color: Colors.grey[200],
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  labelText: "Search $title",
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ...items.entries.map((entry) {
                final key = entry.key;
                final value = entry.value as Map;
      
                return GestureDetector(
                  onDoubleTap: (){
                    if(title == "Buses") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BusLocationScreen(busId: key, institute: institute, name: name),
                        ),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.black,
                          width: 4,
                        ),
                        borderRadius: BorderRadius.circular(10)
                      ),
                      child: itemBuilder(key, value)),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
