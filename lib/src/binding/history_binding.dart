import 'package:get/get.dart';

import '../controller/history_controller.dart';

class InvoiceHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InvoiceHistoryController>(() => InvoiceHistoryController());
  }
}