import 'package:flutter/material.dart';
import '../theme/colors.dart';

class SepsisCareLogo extends StatelessWidget {
  const SepsisCareLogo({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 36.0 : 42.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: SepsisColors.teal,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(Icons.monitor_heart_rounded, color: Colors.white, size: compact ? 21 : 25),
        ),
        const SizedBox(width: 10),
        const Text(
          'SEPSIS CARE',
          style: TextStyle(
            color: SepsisColors.navy,
            fontSize: 18,
            letterSpacing: 2.1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
