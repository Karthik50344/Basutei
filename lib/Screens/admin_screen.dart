// lib/Screens/admin_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/bus_model.dart';
import '../models/user_model.dart';
import 'add_bus_screen.dart';
import 'edit_user_screen.dart';
import 'live_bus_route.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AdminScreen extends StatefulWidget {
  final String institute;
  final String name;
  const AdminScreen({super.key, required this.institute, required this.name});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _dbService = DatabaseService();

  List<BusModel> buses = [];
  List<BusModel> filteredBuses = [];
  List<UserModel> users = [];
  List<UserModel> filteredUsers = [];

  final TextEditingController busSearchController = TextEditingController();
  final TextEditingController userSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBuses();
    _loadUsers();

    busSearchController.addListener(
            () => _filterList(busSearchController.text, isBus: true)
    );
    userSearchController.addListener(
            () => _filterList(userSearchController.text, isBus: false)
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

  void _loadUsers() {
    _dbService.getUsersByInstitute(widget.institute).listen((userData) {
      setState(() {
        users = userData;
        filteredUsers = userData;
      });
    });
  }

  void _filterList(String query, {required bool isBus}) {
    query = query.toLowerCase();
    if (isBus) {
      setState(() {
        filteredBuses = buses.where((bus) {
          return bus.busId.toLowerCase().contains(query) ||
              bus.busNumber.toLowerCase().contains(query);
        }).toList();
      });
    } else {
      setState(() {
        filteredUsers = users.where((user) {
          return user.name.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query);
        }).toList();
      });
    }
  }

  Future<void> _deleteBus(String busId) async {
    final confirmed = await _showConfirmDialog(
        "Delete Bus",
        "Are you sure you want to delete $busId?"
    );
    if (confirmed) {
      await _dbService.deleteBus(busId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Deleted bus $busId"))
        );
      }
    }
  }

  Future<void> _deleteUser(String uid) async {
    final confirmed = await _showConfirmDialog(
        "Delete User",
        "Are you sure you want to delete this user?"
    );
    if (confirmed) {
      await _dbService.deleteUser(uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Deleted user"))
        );
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return (await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")
          ),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete")
          ),
        ],
      ),
    )) ?? false;
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
          title: const Text("Admin"),
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
              Expanded(
                child: GroupBox(
                  name: widget.name,
                  institute: widget.institute,
                  title: "Buses",
                  searchController: busSearchController,
                  items: filteredBuses,
                  itemBuilder: (bus) {
                    return ListTile(
                      title: Text(bus.busId),
                      subtitle: Text(
                          "Driver: ${bus.driverName ?? 'N/A'}, "
                              "Monitor: ${bus.monitorName ?? 'N/A'}"
                      ),
                      trailing: bus.status == "Active"
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.build_circle, color: Colors.red),
                    );
                  },
                  onDelete: (item) => _deleteBus((item as BusModel).busId),
                  onEdit: (item) {
                    final bus = item as BusModel;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddBusScreen(
                          editBusId: bus.busId,
                          busData: bus,
                          institute: widget.institute,
                        ),
                      ),
                    );
                  },
                  onAdd: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => AddBusScreen(institute: widget.institute)
                        )
                    );
                  },
                  onTap: (item) {
                    final bus = item as BusModel;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BusLocationScreen(
                          busId: bus.busId,
                          institute: widget.institute,
                          name: widget.name,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: GroupBox(
                  name: widget.name,
                  institute: widget.institute,
                  title: "Users",
                  searchController: userSearchController,
                  items: filteredUsers,
                  itemBuilder: (user) {
                    return ListTile(
                      title: Text(user.name),
                      subtitle: Text(user.email),
                      trailing: Text(user.role),
                    );
                  },
                  onDelete: (item) => _deleteUser((item as UserModel).uid),
                  onEdit: (item) {
                    final user = item as UserModel;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditUserScreen(
                          editUid: user.uid,
                          userData: user,
                          institute: widget.institute,
                        ),
                      ),
                    );
                  },
                  onAdd: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => RegisterScreen(institute: widget.institute)
                        )
                    );
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

class GroupBox<T> extends StatelessWidget {
  final String title;
  final TextEditingController searchController;
  final List<T> items;
  final Widget Function(T item) itemBuilder;
  final void Function(T item) onDelete;
  final void Function(T item) onEdit;
  final VoidCallback onAdd;
  final String institute;
  final String name;
  final void Function(T item)? onTap;

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
    required this.name,
    this.onTap,
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
            Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
            ),
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
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return GestureDetector(
                    onDoubleTap: onTap != null ? () => onTap!(item) : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Slidable(
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) => onEdit(item),
                              backgroundColor: Colors.blue,
                              icon: Icons.edit,
                              label: 'Edit',
                            ),
                            SlidableAction(
                              onPressed: (_) => onDelete(item),
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
                          child: itemBuilder(item),
                        ),
                      ),
                    ),
                  );
                },
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