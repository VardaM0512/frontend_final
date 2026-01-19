// lib/app/background.dart
import 'package:flutter/material.dart';
import 'branding.dart';

class BackgroundImage extends StatelessWidget {
  const BackgroundImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(kBgUrl),
              fit: BoxFit.cover,
              opacity: 0.2, // ~20% visibility
            ),
          ),
        ),
      ),
    );
  }
}
