
import 'package:flutter/material.dart';

class SepsisColors {
  // Brand colors
  static const navy = Color(0xFF173B63);
  static const navySoft = Color(0xFF245B8F);

  // Primary blue
  static const teal = Color(0xFF2878B9);
  static const tealDark = Color(0xFF195A91);

  // Backgrounds
  static const canvas = Color(0xFFF3F7FB);
  static const surface = Color(0xFFFFFFFF);
  static const blueLight = Color(0xFFEAF3FA);

  // Neutral colors
  static const muted = Color(0xFF71869B);
  static const border = Color(0xFFDFE8F0);

  // Risk levels
  static const high = Color(0xFFD64B59);
  static const highSoft = Color(0xFFFFEFF1);

  static const mid = Color(0xFFD69A36);
  static const midSoft = Color(0xFFFFF6E8);

  static const low = Color(0xFF29977C);
  static const lowSoft = Color(0xFFE9F6F1);

  static Color forLevel(String level) {
    switch (level) {
      case 'Élevé':
        return high;
      case 'Modéré':
        return mid;
      default:
        return low;
    }
  }

  static Color softForLevel(String level) {
    switch (level) {
      case 'Élevé':
        return highSoft;
      case 'Modéré':
        return midSoft;
      default:
        return lowSoft;
    }
  }
}
