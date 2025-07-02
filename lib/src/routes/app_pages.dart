import 'package:get/get.dart';
import 'package:lunasi/src/views/login/login.dart';
import 'package:lunasi/src/views/splash_screen.dart';

import '../binding/create_invoice_binding.dart';
import '../binding/customer_binding.dart';
import '../binding/dashboard_binding.dart';
import '../binding/debt_binding.dart';
import '../binding/debt_list_binding.dart';
import '../binding/history_binding.dart';
import '../binding/product_binding.dart';
import '../binding/settings_binding.dart';
import '../views/customers/customer_view.dart';
import '../views/dashboard/dashboard_view.dart';
import '../views/debt/debt_create_view.dart';
import '../views/debt/debt_list_view.dart';
import '../views/history/history_view.dart';
import '../views/invoices/invoice_create_view.dart';
import '../views/products/product_view.dart';
import '../views/settings/setting_view.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.SPLASH,
      page: () => SplashScreen(),
    ),
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => LoginView(),
    ),
    GetPage(
      name: AppRoutes.DASHBOARD,
      page: () => DashboardView(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.PRODUCTS,
      page: () => ProductsView(),
      binding: ProductsBinding(),
    ),
    GetPage(
      name: AppRoutes.CUSTOMERS,
      page: () => CustomersView(),
      binding: CustomersBinding(),
    ),
    GetPage(
      name: AppRoutes.INVOICE_CREATE,
      page: () => InvoiceCreateView(),
      binding: InvoiceCreateBinding(),
    ),
    GetPage(
      name: AppRoutes.INVOICE_HISTORY,
      page: () => InvoiceHistoryView(),
      binding: InvoiceHistoryBinding(),
    ),
    GetPage(
      name: AppRoutes.DEBT_CREATE,
      page: () => DebtCreateView(),
      binding: DebtCreateBinding(),
    ),
    GetPage(
      name: AppRoutes.DEBT_LIST,
      page: () => DebtListView(),
      binding: DebtListBinding(),
    ),
    GetPage(
      name: AppRoutes.SETTINGS,
      page: () => SettingsView(),
      binding: SettingsBinding(),
    ),
  ];
}

// Cetak Invoice PDF (framework sudah ada)
// Notifikasi push untuk hutang jatuh tempo
// Barcode scanner untuk produk
// Multi-user dengan login system
// Sync cloud untuk backup online