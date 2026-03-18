import 'package:flutter/widgets.dart';

class AppTransitions {
  AppTransitions._();

  static Widget fadeSlide(
    Widget child,
    Animation<double> animation, {
    Offset begin = const Offset(0, 0.06),
    Offset end = Offset.zero,
  }) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: begin, end: end).animate(curved),
        child: child,
      ),
    );
  }
}
