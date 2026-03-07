import 'package:flutter/material.dart';

class RoutePreferencesGradient extends StatelessWidget {
  const RoutePreferencesGradient({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x800F2123),
              Color(0x330F2123),
              Color(0x330F2123),
              Color(0xCC0F2123),
            ],
            stops: [0.0, 0.25, 0.6, 1.0],
          ),
        ),
      ),
    );
  }
}
