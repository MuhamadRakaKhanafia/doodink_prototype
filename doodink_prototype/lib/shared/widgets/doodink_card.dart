import 'package:flutter/material.dart';

class DoodinkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const DoodinkCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withValues(alpha: 0.08),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      shadowColor: Colors.black.withValues(alpha: 0.22),

      elevation: 8,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

