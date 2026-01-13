import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RegisterScreen extends StatefulWidget {
  final String institute;
  const RegisterScreen({super.key, required this.institute});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'Admin';
  String? _selectedBus;
  final List<String> _roles = ['Admin', 'Driver', 'Monitor', 'Public'];
  final Map<String, int> _roleID = {"Admin": 1, "Driver": 2, "Monitor": 3, "Public": 4};
  List<String> _buses = [];

  bool _loading = false;

  bool get _showBusDropdown => _selectedRole == 'Driver' || _selectedRole == 'Monitor';

  @override
  void initState() {
    _loadBuses();
    super.initState();
  }

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
      _buses = buses;
    });
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      // Create user in Firebase Auth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final uid = userCredential.user!.uid;

      // Save user info in Realtime Database
      final userRef = FirebaseDatabase.instance.ref().child("Users/$uid");
      await userRef.set({
        "Name": _nameController.text.trim(),
        "Email": _emailController.text.trim(),
        "Mobile": _mobileController.text.trim(),
        "Role": _roleID[_selectedRole],
        "institute": widget.institute,
        "Bus": _showBusDropdown ? _selectedBus : "",
        "fcmToken": ""
      });

      if(_showBusDropdown){
        final busRef = FirebaseDatabase.instance.ref().child("buses/$_selectedBus");
        if(_selectedRole == "Driver") {
          await busRef.update({
            "driverName": _nameController.text.trim(),
            "driverMobile": _mobileController.text.trim()
          });
        } else if(_selectedRole == "Monitor") {
          await busRef.update({
            "monitorName": _nameController.text.trim(),
            "monitorMobile": _mobileController.text.trim()
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User registered successfully")),
      );
      Navigator.pop(context); // Back to AdminScreen
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.message}")),
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
        title: const Text("Add User"),
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
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(labelText: "Mobile Number"),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10)],
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: "Role"),
                items: _roles.map((role) {
                  return DropdownMenuItem(value: role, child: Text(role));
                }).toList(),
                onChanged: (val) => setState(() {
                  _selectedRole = val!;
                  _selectedBus = null;
                }),
              ),
              const SizedBox(height: 12),
              if (_showBusDropdown)
                DropdownButtonFormField<String>(
                  value: _selectedBus,
                  decoration: const InputDecoration(labelText: "Bus"),
                  items: _buses.map((bus) {
                    return DropdownMenuItem(value: bus, child: Text(bus));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedBus = val),
                  validator: (val) => val == null ? "Select a bus" : null,
                ),
              if (_showBusDropdown) const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(labelText: "Confirm Password"),
                obscureText: true,
                validator: (val) =>
                val != _passwordController.text ? "Passwords do not match" : null,
              ),
              const SizedBox(height: 20),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _registerUser,
                child: const Text("Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
