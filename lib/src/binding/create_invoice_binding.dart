import 'package:get/get.dart';
import '../controller/invoice_create_controller.dart';

class InvoiceCreateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InvoiceCreateController>(() => InvoiceCreateController());
  }
}