// lib/Screens/register_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../models/bus_model.dart';

class RegisterScreen extends StatefulWidget {
  final String institute;
  const RegisterScreen({super.key, required this.institute});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'student';
  String? _selectedBus;
  final List<String> _roles = ['admin', 'driver', 'monitor', 'student', 'parent'];
  List<BusModel> _buses = [];

  bool _loading = false;

  bool get _showBusDropdown => _selectedRole == 'driver' ||
      _selectedRole == 'monitor' ||
      _selectedRole == 'student';

  @override
  void initState() {
    super.initState();
    _loadBuses();
  }

  Future<void> _loadBuses() async {
    _dbService.getBusesByInstitute(widget.institute).listen((buses) {
      setState(() {
        _buses = buses;
      });
    });
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      // Create user in Firebase Auth
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final uid = userCredential.user!.uid;

      // Create user model
      final user = UserModel(
        uid: uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        mobile: _mobileController.text.trim(),
        role: _selectedRole,
        instituteId: widget.institute,
        assignedBusId: (_selectedRole == 'driver' || _selectedRole == 'monitor')
            ? _selectedBus
            : null,
        busId: _selectedRole == 'student' ? _selectedBus : null,
        fcmToken: '',
      );

      // Save user in database
      await _dbService.createUser(user);

      // If driver or monitor, update bus
      if ((_selectedRole == 'driver' || _selectedRole == 'monitor') &&
          _selectedBus != null) {
        await _dbService.assignUserToBus(uid, _selectedBus!, _selectedRole);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User registered successfully")),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.message}")),
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
        title: const Text("Add User"),
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
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val!.isEmpty) return "Required";
                  if (!val.contains('@')) return "Invalid email";
                  return null;
                },
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
                  validator: _selectedRole == 'student'
                      ? null
                      : (val) => val == null ? "Select a bus" : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (val) {
                  if (val!.isEmpty) return "Required";
                  if (val.length < 6) return "At least 6 characters";
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(labelText: "Confirm Password"),
                obscureText: true,
                validator: (val) =>
                val != _passwordController.text
                    ? "Passwords do not match"
                    : null,
              ),
              const SizedBox(height: 20),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _registerUser,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text("Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}