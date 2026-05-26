import 'package:flutter/material.dart';

class RoundedInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;

  const RoundedInput({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
fillColor: Colors.white.withValues(alpha: 0.08),
        labelStyle: const TextStyle(color: Colors.white),
        hintStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }
}

