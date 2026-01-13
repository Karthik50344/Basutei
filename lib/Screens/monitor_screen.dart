import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class MonitorScreen extends StatelessWidget {
  final String institute;
  final String bus;
  const MonitorScreen({super.key, required this.institute, required this.bus});

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
          title: const Text("Monitor"),
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
        body: const Center(
          child: Text("Monitor Screen"),
        ),
      ),
    );
  }
}
