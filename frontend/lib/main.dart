import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import semua halaman
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Polibatam Ride',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B132B),
        useMaterial3: true,
      ),
      // === GANTI HOME JADI AuthGate ===
      home: const AuthGate(), 
    );
  }
}

// === WIDGET PEMERIKSA LOGIN (AUTH GATE) ===
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userDataStr = prefs.getString('user_data');

    // 1. Kalau Token ada, lempar ke halaman yang sesuai
    if (token != null && token.isNotEmpty && userDataStr != null) {
      try {
        final userData = jsonDecode(userDataStr);
        final isAdmin = userData['is_admin'] == true || userData['is_admin'] == 1;

        if (!mounted) return;
        if (isAdmin) {
          // Lempar ke Admin Dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminScreen()),
          );
        } else {
          // Lempar ke Home Mahasiswa
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
        return; // Hentikan proses di sini
      } catch (e) {
        // Kalau data corrupt, hapus aja
        await prefs.clear();
      }
    }

    // 2. Kalau Token GAK ADA, lempar ke Login
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tampilan loading pas lagi ngecek token
    return const Scaffold(
      backgroundColor: Color(0xFF0B132B), // Warna background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 60, color: Colors.white),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}