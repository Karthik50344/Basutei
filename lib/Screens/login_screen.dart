// lib/Screens/login_screen.dart
import 'package:basutei/resources.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/database_service.dart';
import 'admin_screen.dart';
import 'driver_screen.dart';
import 'monitor_screen.dart';
import 'public_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final _auth = FirebaseAuth.instance;
  final _dbService = DatabaseService();

  bool _loading = false;
  String _error = '';

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = userCredential.user?.uid;
      if (uid == null) {
        throw FirebaseAuthException(
            code: 'invalid-user',
            message: 'User ID not found'
        );
      }

      // Fetch user data from new structure
      final userData = await _dbService.getUser(uid);

      if (userData == null) {
        throw FirebaseAuthException(
            code: 'no-user',
            message: 'User data not found'
        );
      }

      // Get and save FCM token
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _dbService.updateUser(uid, {'fcmToken': token});
      }

      // Navigate based on role
      Widget targetScreen;
      switch (userData.role) {
        case 'admin':
          targetScreen = AdminScreen(
            institute: userData.instituteId,
            name: userData.name,
          );
          break;
        case 'driver':
          if (userData.assignedBusId == null) {
            throw FirebaseAuthException(
                code: 'no-bus',
                message: 'No bus assigned to driver'
            );
          }
          targetScreen = DriverScreen(
            institute: userData.instituteId,
            bus: userData.assignedBusId!,
          );
          break;
        case 'monitor':
          if (userData.assignedBusId == null) {
            throw FirebaseAuthException(
                code: 'no-bus',
                message: 'No bus assigned to monitor'
            );
          }
          targetScreen = MonitorScreen(
            institute: userData.instituteId,
            bus: userData.assignedBusId!,
          );
          break;
        case 'student':
        case 'parent':
          targetScreen = PublicScreen(
            institute: userData.instituteId,
            name: userData.name,
            uid: uid,
          );
          break;
        default:
          throw FirebaseAuthException(
              code: 'invalid-role',
              message: 'Unknown user role: ${userData.role}'
          );
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => targetScreen),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? 'Login failed';
      });
    } catch (e) {
      setState(() {
        _error = 'An error occurred: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = "Enter your email to reset password.");
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password reset email sent.")),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? "Error sending reset email.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 100,
                child: Image.asset(ImageResource.logoImage),
              ),
              const SizedBox(height: 32),

              const Text(
                "Welcome Back!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              if (_error.isNotEmpty)
                Text(
                  _error,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: const Text("Login"),
                ),
              ),

              TextButton(
                onPressed: _forgotPassword,
                child: const Text("Forgot Password?"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}