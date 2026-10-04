import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  final String? imagePath; // Contoh: 'assets/images/bg.jpg'

  const AppBackground({super.key, required this.child, this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Layer 1: Gradient dasar
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0A1128), Color(0xFF162040)],
            ),
          ),
        ),

        // Layer 2: Foto background (low opacity)
        if (imagePath != null)
          Positioned.fill(
            child: Opacity(
              opacity: 0.30, // Ubah ini kalau mau lebih terang/gelap
              child: Image.asset(
                imagePath!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ),

        // Layer 3: Dark overlay biar konten tetap kebaca
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),
        ),

        // Layer 4: Konten asli
        SafeArea(child: child),
      ],
    );
  }
}
