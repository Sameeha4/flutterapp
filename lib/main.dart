import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/main_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/register_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Flutter Chat App',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // Home screen based on auth state
          home: snapshot.connectionState == ConnectionState.waiting
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : snapshot.hasData
              ? const MainScreen()
              : const AuthScreen(),
          // Named routes
          routes: {
            '/auth': (context) => const AuthScreen(),
            '/register': (context) => const RegisterScreen(),
            '/chats': (context) => const MainScreen(),
          },
        );
      },
    );
  }
}
