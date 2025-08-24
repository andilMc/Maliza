import 'package:flutter/material.dart';

class DefaultPageWrapper extends StatelessWidget {
  final Widget child;
  
  const DefaultPageWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        color: Colors.black87,
        decoration: TextDecoration.none,
      ),
      child: child,
    );
  }
}