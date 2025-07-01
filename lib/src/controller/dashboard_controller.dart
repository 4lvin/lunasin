import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../services/db_service.dart';

class DashboardController extends GetxController {
  final DatabaseService _db = Get.find<DatabaseService>();

  var totalTransactionsToday = 0.obs;
  var totalRevenueToday = 0.0.obs;
  var totalActiveDebts = 0.0.obs;
  var totalTransactions = 0.obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    try {
      isLoading(true);
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Total transaksi hari ini
      var todayTransactions = await _db.database.rawQuery(
        'SELECT COUNT(*) as count, SUM(total) as revenue FROM invoices WHERE DATE(created_at) = ?',
        [today],
      );

      totalTransactionsToday.value = todayTransactions.first['count'] as int;
      totalRevenueToday.value =
          (todayTransactions.first['revenue'] as double?) ?? 0.0;

      // Total piutang aktif
      var activeDebts = await _db.database.rawQuery(
        'SELECT SUM(remaining_amount) as total FROM debts WHERE status = "unpaid"',
      );

      totalActiveDebts.value = (activeDebts.first['total'] as double?) ?? 0.0;

      // Total transaksi keseluruhan
      var allTransactions = await _db.database.rawQuery(
        'SELECT COUNT(*) as count FROM invoices',
      );

      totalTransactions.value = allTransactions.first['count'] as int;
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data dashboard');
    } finally {
      isLoading(false);
    }
  }

  String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }
}
