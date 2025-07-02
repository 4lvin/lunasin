import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/assets.dart';
import '../config/theme.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  AuthService authService = Get.put(AuthService());

  @override
  void initState() {
    Timer(const Duration(milliseconds: 700), () async {
      if (await authService.isLoggedIn()) {
        Get.offAllNamed(AppRoutes.DASHBOARD);
      } else {
        Get.offAllNamed(AppRoutes.LOGIN);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Image.asset(
            logoAtas,
            scale: 1.5,
          )),
    );
  }
}
