import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B132B),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'Polibatam Ride',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        textTheme: TextTheme(
          // Poppins buat heading
          displayLarge: GoogleFonts.poppins(
              fontSize: 57, fontWeight: FontWeight.bold),
          displayMedium: GoogleFonts.poppins(
              fontSize: 45, fontWeight: FontWeight.bold),
          displaySmall: GoogleFonts.poppins(
              fontSize: 36, fontWeight: FontWeight.bold),
          headlineLarge: GoogleFonts.poppins(
              fontSize: 32, fontWeight: FontWeight.bold),
          headlineMedium: GoogleFonts.poppins(
              fontSize: 28, fontWeight: FontWeight.w600),
          headlineSmall: GoogleFonts.poppins(
              fontSize: 24, fontWeight: FontWeight.w600),
          titleLarge: GoogleFonts.poppins(
              fontSize: 22, fontWeight: FontWeight.w600),
          titleMedium: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w600),
          titleSmall: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w500),

          // Inter buat body
          bodyLarge: GoogleFonts.inter(fontSize: 16),
          bodyMedium: GoogleFonts.inter(fontSize: 14),
          bodySmall: GoogleFonts.inter(fontSize: 12),

          // Inter buat label
          labelLarge: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600),
          labelMedium: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w500),
          labelSmall: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}