import 'package:flutter/material.dart';
import 'package:mobile/core/theme/colors.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title, style: const TextStyle(
        color: SepsisColors.navy, fontSize: 17, fontWeight: FontWeight.w800))),
      if (action != null)
        TextButton(onPressed: onAction, child: Text(action!,
          style: const TextStyle(color: SepsisColors.teal, fontWeight: FontWeight.w700))),
    ],
  );
}
