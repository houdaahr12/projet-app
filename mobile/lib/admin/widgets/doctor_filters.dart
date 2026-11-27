
import 'package:flutter/material.dart';

import 'package:mobile/main.dart';

enum FiltreStatut { tous, actifs, inactifs }

class StatusFilterBar extends StatelessWidget {
  final FiltreStatut filtre;
  final ValueChanged<FiltreStatut> onChanged;

  const StatusFilterBar({
    super.key,
    required this.filtre,
    required this.onChanged,
  });

  Widget _segment(
    String label,
    FiltreStatut value,
    IconData icon,
  ) {
    final selected = filtre == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.blue.withValues(alpha: 0.20),
                      blurRadius: 9,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : AppColors.navy,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE1EAF4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.025),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          _segment('Tous', FiltreStatut.tous, Icons.groups_rounded),
          _segment('Actifs', FiltreStatut.actifs,
              Icons.check_circle_outline_rounded),
          _segment('Inactifs', FiltreStatut.inactifs,
              Icons.pause_circle_outline_rounded),
        ],
      ),
    );
  }
}

class DoctorSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const DoctorSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Rechercher par nom, identifiant ou email...',
          hintStyle: const TextStyle(
            color: AppColors.grey,
            fontSize: 12,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.blue,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.grey,
                  ),
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(color: Color(0xFFE5ECF5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(
              color: AppColors.blue,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}