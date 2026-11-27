import 'package:flutter/material.dart';

class SepsisColors {
  static const navy = Color(0xFF173B63);
  static const navySoft = Color(0xFF245B8F);
  static const teal = Color(0xFF2878B9);
  static const tealDark = Color(0xFF195A91);
  static const canvas = Color(0xFFF3F7FB);
  static const surface = Color(0xFFFFFFFF);
  static const blueLight = Color(0xFFEAF3FA);
  static const muted = Color(0xFF71869B);
  static const border = Color(0xFFDFE8F0);

  // Backend classification: alerte (red), surveillance (amber), normal (green).
  static const high = Color(0xFFD64B59);
  static const highSoft = Color(0xFFFFEFF1);
  static const mid = Color(0xFFD69A36);
  static const midSoft = Color(0xFFFFF6E8);
  static const low = Color(0xFF29977C);
  static const lowSoft = Color(0xFFE9F6F1);

  static Color forLevel(String level) {
    switch (level.toLowerCase()) {
      case 'alerte':
      case 'élevé':
      case 'eleve':
      case 'high':
        return high;
      case 'surveillance':
      case 'modéré':
      case 'modere':
      case 'medium':
        return mid;
      case 'normal':
      case 'stable':
      case 'low':
        return low;
      default:
        return muted;
    }
  }

  static Color softForLevel(String level) {
    switch (level.toLowerCase()) {
      case 'alerte':
      case 'élevé':
      case 'eleve':
      case 'high':
        return highSoft;
      case 'surveillance':
      case 'modéré':
      case 'modere':
      case 'medium':
        return midSoft;
      case 'normal':
      case 'stable':
      case 'low':
        return lowSoft;
      default:
        return blueLight;
    }
  }
}
