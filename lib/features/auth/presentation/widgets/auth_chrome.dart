import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/soilsafe_theme.dart';

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final vertical = compact ? 28.0 : 40.0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: vertical, horizontal: 24),
      decoration: const BoxDecoration(
        color: SoilSafeColors.primaryGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: SizedBox(
                width: 52,
                height: 52,
                child: const Icon(
                  Icons.spa, 
                  color: Color(0xFF1E4D2B), //ge change nko ang leaf into dark green
                  size: 45),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'SoilSAFE',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Smart Soil Assessment for Fusarium-Free Plantations',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade700,
      ),
    );
  }
}

InputDecoration authInputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: SoilSafeColors.primaryGreen, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
  );
}
