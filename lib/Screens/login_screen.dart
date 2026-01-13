import 'package:basutei/resources.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
      if (uid == null) throw FirebaseAuthException(code: 'invalid-user', message: 'User ID not found');

      // Fetch role from database
      final snapshot = await FirebaseDatabase.instance.ref("Users/$uid/Role").get();
      final role = snapshot.value;
      final snapshot1 = await FirebaseDatabase.instance.ref("Users/$uid/institute").get();
      final institute = snapshot1.value.toString();

      if (role == null) {
        throw FirebaseAuthException(code: 'no-role', message: 'User role not assigned');
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return; // no logged-in user

      // Get the device FCM token
      String? token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        debugPrint("FCM Token: $token");

        // Save the token in Realtime Database under the user
        final userRef = FirebaseDatabase.instance.ref('Users/${user.uid}');
        await userRef.update({'fcmToken': token});
      }

      // Navigate based on role
      Widget targetScreen;
      switch (role) {
        case 1:
          final snapshot2 = await FirebaseDatabase.instance.ref("Users/$uid/Name").get();
          final name = snapshot2.value.toString();
          targetScreen = AdminScreen(institute: institute, name: name,);
          break;
        case 2:
          final snapshot3 = await FirebaseDatabase.instance.ref("Users/$uid/Bus").get();
          final bus = snapshot3.value.toString();
          targetScreen = DriverScreen(institute: institute, bus: bus);
          break;
        case 3:
          final snapshot4 = await FirebaseDatabase.instance.ref("Users/$uid/Bus").get();
          final bus = snapshot4.value.toString();
          targetScreen = MonitorScreen(institute: institute, bus: bus);
          break;
        case 4:
          final snapshot5 = await FirebaseDatabase.instance.ref("Users/$uid/Name").get();
          final name = snapshot5.value.toString();
          targetScreen = PublicScreen(institute: institute, name: name);
          break;
        default:
          throw FirebaseAuthException(code: 'invalid-role', message: 'Unknown user role');
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => targetScreen),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? 'Login failed';
      });
    } finally {
      setState(() => _loading = false);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset email sent.")),
      );
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
              // App Logo
              SizedBox(
                height: 100,
                child: Image.asset(ImageResource.logoImage), // Make sure this asset exists
              ),
              const SizedBox(height: 32),

              const Text(
                "Welcome Back!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Email Field
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

              // Password Field
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

              // Error message
              if (_error.isNotEmpty)
                Text(
                  _error,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 16),

              // Login Button
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

              // Forgot Password
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
