import 'package:flutter/material.dart';

Route slideForward(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500), 
      reverseTransitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ));

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut,
        ));

        return SlideTransition(
          position: offsetAnimation, 
          child: FadeTransition(opacity: fadeAnimation, child: child
        ));
      },
    );
  }