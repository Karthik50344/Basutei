import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../models/bus_model.dart';

class EditUserScreen extends StatefulWidget {
  final String editUid;
  final UserModel userData;
  final String institute;

  const EditUserScreen({
    super.key,
    required this.editUid,
    required this.userData,
    required this.institute
  });

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();

  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final List<String> _roles = ['admin', 'driver', 'monitor', 'student', 'parent'];

  String _selectedRole = 'student';
  String? _selectedBus;
  List<BusModel> _buses = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userData.name;
    _mobileController.text = widget.userData.mobile;
    _selectedRole = widget.userData.role;
    _selectedBus = widget.userData.assignedBusId ?? widget.userData.busId;
    _loadBuses();
  }

  bool get _showBusDropdown => _selectedRole == 'driver' ||
      _selectedRole == 'monitor' ||
      _selectedRole == 'student';

  Future<void> _loadBuses() async {
    _dbService.getBusesByInstitute(widget.institute).listen((buses) {
      setState(() {
        _buses = buses;
      });
    });
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final updates = <String, dynamic>{
        'name': _nameController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'role': _selectedRole,
      };

      // Handle bus assignment based on role
      if (_selectedRole == 'driver' || _selectedRole == 'monitor') {
        updates['assignedBusId'] = _selectedBus;
        updates['busId'] = null;
      } else if (_selectedRole == 'student') {
        updates['busId'] = _selectedBus;
        updates['assignedBusId'] = null;
      } else {
        updates['assignedBusId'] = null;
        updates['busId'] = null;
      }

      await _dbService.updateUser(widget.editUid, updates);

      // Update bus with driver/monitor info if applicable
      if ((_selectedRole == 'driver' || _selectedRole == 'monitor') &&
          _selectedBus != null) {
        // Remove old assignment if bus changed
        if (widget.userData.assignedBusId != null &&
            widget.userData.assignedBusId != _selectedBus) {
          await _dbService.removeUserFromBus(
              widget.editUid,
              widget.userData.assignedBusId!,
              widget.userData.role
          );
        }

        // Add new assignment
        await _dbService.assignUserToBus(
            widget.editUid,
            _selectedBus!,
            _selectedRole
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User updated successfully")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("Update User"),
        titleTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
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
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10)
                ],
                validator: (val) {
                  if (val!.isEmpty) return "Required";
                  if (val.length != 10) return "Must be 10 digits";
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: "Role"),
                items: _roles.map((role) {
                  return DropdownMenuItem(
                      value: role,
                      child: Text(role[0].toUpperCase() + role.substring(1))
                  );
                }).toList(),
                onChanged: (val) => setState(() {
                  _selectedRole = val!;
                  _selectedBus = null;
                }),
              ),
              const SizedBox(height: 12),
              if (_showBusDropdown) ...[
                DropdownButtonFormField<String>(
                  value: _selectedBus,
                  decoration: InputDecoration(
                      labelText: _selectedRole == 'student'
                          ? "Assigned Bus"
                          : "Bus to Operate"
                  ),
                  items: _buses.map((bus) {
                    return DropdownMenuItem(
                        value: bus.busId,
                        child: Text('${bus.busId} (${bus.busNumber})')
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedBus = val),
                  validator: (_selectedRole == 'driver' || _selectedRole == 'monitor')
                      ? (val) => val == null ? "Select a bus" : null
                      : null,
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _updateUser,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text("Update"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}