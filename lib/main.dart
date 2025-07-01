import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lunasi/src/app.dart';
import 'package:lunasi/src/services/db_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Get.putAsync(() => DatabaseService().init());
  runApp(MyApp());
}

