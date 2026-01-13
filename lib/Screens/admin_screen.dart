import 'package:basutei/Screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'add_bus_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_user_screen.dart';
import 'live_bus_route.dart';
import 'login_screen.dart';

class AdminScreen extends StatefulWidget {
  final String institute;
  final String name;
  const AdminScreen({super.key, required this.institute, required this.name});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String _roleToString(dynamic role) {
    switch (role) {
      case 1:
        return "Admin";
      case 2:
        return "Driver";
      case 3:
        return "Monitor";
      case 4:
        return "Public";
      default:
        return "Unknown";
    }
  }
  // Firebase refs
  final DatabaseReference busesRef = FirebaseDatabase.instance.ref().child('buses');
  final DatabaseReference usersRef = FirebaseDatabase.instance.ref().child('Users');

  // Data storage
  Map<dynamic, dynamic> buses = {};
  Map<dynamic, dynamic> filteredBuses = {};
  Map<dynamic, dynamic> users = {};
  Map<dynamic, dynamic> filteredUsers = {};

  // Search controllers
  final TextEditingController busSearchController = TextEditingController();
  final TextEditingController userSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBuses();
    _loadUsers();

    busSearchController.addListener(() => _filterList(busSearchController.text, isBus: true));
    userSearchController.addListener(() => _filterList(userSearchController.text, isBus: false));
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

  void _loadUsers() {
    usersRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final filtered = <dynamic, dynamic>{};
      data.forEach((key, value) {
        final user = value as Map<dynamic, dynamic>;
        if (user['institute'] == widget.institute) {
          filtered[key] = user;
        }
      });
      setState(() {
        users = filtered;
        filteredUsers = filtered;
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
    } else {
      setState(() {
        filteredUsers = users
            .map((key, value) => MapEntry(key, value))
          ..removeWhere((key, value) {
            final name = value['Name']?.toString().toLowerCase() ?? '';
            final email = value['Email']?.toString().toLowerCase() ?? '';
            return !name.contains(query) && !email.contains(query);
          });
      });
    }
  }

  Future<void> _deleteBus(String key) async {
    final confirmed = await _showConfirmDialog("Delete Bus", "Are you sure you want to delete $key?");
    if (confirmed) {
      await busesRef.child(key).remove();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Deleted bus $key")));
    }
  }

  Future<void> _deleteUser(String uid) async {
    final confirmed = await _showConfirmDialog("Delete User", "Are you sure you want to delete this user?");
    if (confirmed) {
      await usersRef.child(uid).remove();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Deleted user")));
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return (await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    )) ??
        false;
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
          title: const Text("Admin"),
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
              Expanded(
                child: GroupBox(
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
                  onDelete: _deleteBus,
                  onEdit: (key, value) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddBusScreen(editKey: key, busData: value, institute: widget.institute,),
                      ),
                    );
                  },
                  onAdd: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AddBusScreen(institute: widget.institute,)));
                  },
                ),
              ),

              // const SizedBox(height: 30),

              // Users GroupBox
              Expanded(
                child: GroupBox(
                  name: widget.name,
                  institute: widget.institute,
                  title: "Users",
                  searchController: userSearchController,
                  items: filteredUsers,
                  itemBuilder: (key, value) {
                    final user = value as Map;
                    return ListTile(
                      title: Text(user['Name'] ?? 'No Name'),
                      subtitle: Text(user['Email'] ?? ''),
                      trailing: Text(_roleToString(user['Role'])),
                    );
                  },
                  onDelete: _deleteUser,
                  onEdit: (key, value) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditUserScreen(editUid: key, userData: value, institute: widget.institute,),
                      ),
                    );
                  },
                  onAdd: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen(institute: widget.institute,)));
                  },
                ),
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
  final void Function(String key) onDelete;
  final void Function(String key, Map value) onEdit;
  final VoidCallback onAdd;
  final String institute;
  final String name;

  const GroupBox({
    super.key,
    required this.title,
    required this.searchController,
    required this.items,
    required this.itemBuilder,
    required this.onDelete,
    required this.onEdit,
    required this.onAdd,
    required this.institute,
    required this.name
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.grey[200],
      margin: const EdgeInsets.all(8),
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
            Expanded(
              child: ListView(
                children: items.entries.map((entry) {
                  final key = entry.key;
                  final value = entry.value as Map;

                  return GestureDetector(
                    onDoubleTap: () {
                      if (title == "Buses") {
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
                      child: Slidable(
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) => onEdit(key, value),
                              backgroundColor: Colors.blue,
                              icon: Icons.edit,
                              label: 'Edit',
                            ),
                            SlidableAction(
                              onPressed: (_) => onDelete(key),
                              backgroundColor: Colors.red,
                              icon: Icons.delete,
                              label: 'Delete',
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black, width: 4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: itemBuilder(key, value),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FloatingActionButton(
                heroTag: "Add_$title",
                mini: true,
                onPressed: onAdd,
                backgroundColor: Colors.green,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
