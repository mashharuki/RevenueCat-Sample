import 'package:flutter/material.dart';
import 'package:my_first_game/theme/app_theme.dart';

class NeonButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool primary;

  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary ? AppTheme.cyan : Colors.transparent,
          foregroundColor: primary ? AppTheme.background : AppTheme.cyan,
          side: primary ? BorderSide.none : const BorderSide(color: AppTheme.cyan),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label, style: AppTheme.orbitron(fontSize: 14)),
      ),
    );
  }
}
