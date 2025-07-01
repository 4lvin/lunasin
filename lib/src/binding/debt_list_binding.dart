import 'package:get/get.dart';

import '../controller/debt_list_controller.dart';

class DebtListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DebtListController>(() => DebtListController());
  }
}