import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class EditUserScreen extends StatefulWidget {
  final String editUid;
  final Map userData;
  final String institute;

  const EditUserScreen({super.key, required this.editUid, required this.userData, required this.institute});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final List<String> _roles = ['Admin', 'Driver', 'Monitor', 'Public'];
  final Map<String, int> _roleID = {"Admin": 1, "Driver": 2, "Monitor": 3, "Public": 4};

  String _selectedRole = 'Public';
  String? _selectedBus;
  List<String> _filteredBuses = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = widget.userData;
    _nameController.text = user['Name'] ?? '';
    _mobileController.text = user['Mobile'] ?? '';
    _selectedRole = _roles.firstWhere(
          (r) => _roleID[r] == user['Role'],
      orElse: () => 'Public',
    );
    _selectedBus = user['Bus'];
    _loadBuses();
  }

  bool get _showBusDropdown => _selectedRole == 'Driver' || _selectedRole == 'Monitor';

  Future<void> _loadBuses() async {
    final busRef = FirebaseDatabase.instance.ref('buses');
    final snapshot = await busRef.get();

    final buses = <String>[];

    if (snapshot.exists) {
      final data = snapshot.value as Map;
      data.forEach((key, value) {
        final bus = Map<String, dynamic>.from(value);
        if (bus['institute'] == widget.institute) {
          buses.add(key);
        }
      });
    }

    setState(() {
      _filteredBuses = buses;
    });
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      await FirebaseDatabase.instance
          .ref("Users/${widget.editUid}")
          .update({
        "Name": _nameController.text.trim(),
        "Role": _roleID[_selectedRole],
        "Mobile": _mobileController.text.trim(),
        "Bus": _showBusDropdown ? _selectedBus : null,
      });
      if(_selectedRole == "Driver") {
        await FirebaseDatabase.instance
            .ref("buses/$_selectedBus")
            .update({
          "driverName": _nameController.text.trim(),
          "driverMobile": _mobileController.text.trim()
        });
      } else if(_selectedRole == "Monitor") {
        await FirebaseDatabase.instance
            .ref("buses/$_selectedBus")
            .update({
          "monitorName": _nameController.text.trim(),
          "monitorMobile": _mobileController.text.trim()
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User updated successfully")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("Update User"),
        titleTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontSize: 20),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Name"),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(labelText: "Mobile Number"),
                keyboardType: TextInputType.phone,
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: "Role"),
                items: _roles.map((role) {
                  return DropdownMenuItem(value: role, child: Text(role));
                }).toList(),
                onChanged: (val) => setState(() => _selectedRole = val!),
              ),
              const SizedBox(height: 20),
              if (_showBusDropdown)
                DropdownButtonFormField<String>(
                  value: _selectedBus,
                  decoration: const InputDecoration(labelText: "Bus"),
                  items: _filteredBuses.map((bus) {
                    return DropdownMenuItem(value: bus, child: Text(bus));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedBus = val),
                  validator: (val) => val == null ? "Select a bus" : null,
                ),
              if(_showBusDropdown)
                const SizedBox(height: 20),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _updateUser,
                child: const Text("Update"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
