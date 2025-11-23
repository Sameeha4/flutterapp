// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final nameController = TextEditingController();
  bool loading = false;

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> registerUser() async {
    final email = emailController.text.trim();
    final password = passController.text.trim();
    final name = nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email and password are required")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // 1️⃣ Register user with AuthService
      final user = await _authService.register(email, password);
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Registration failed")));
        return;
      }

      // 2️⃣ Save user info in Firestore
      await _firestoreService.saveUser(
        user.uid,
        name.isEmpty ? "No Name" : name,
        email,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Registration successful!")));

      // Navigate to main screen
      Navigator.pushReplacementNamed(context, '/chats');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name (optional)"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: passController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 25),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: registerUser,
                    child: const Text("Register"),
                  ),
          ],
        ),
      ),
    );
  }
}
