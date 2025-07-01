import 'package:get/get.dart';

import '../controller/debt_create_controller.dart';

class DebtCreateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DebtCreateController>(() => DebtCreateController());
  }
}