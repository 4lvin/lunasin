import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/debt_model.dart';
import '../services/db_service.dart';

class DebtListController extends GetxController {
  final DatabaseService _db = Get.find<DatabaseService>();

  var debts = <Debt>[].obs;
  var filteredDebts = <Debt>[].obs;
  var isLoading = true.obs;
  var selectedStatus = 'all'.obs;

  final paymentAmountController = TextEditingController();
  final paymentNotesController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadDebts();
  }

  @override
  void onClose() {
    paymentAmountController.dispose();
    paymentNotesController.dispose();
    super.onClose();
  }

  Future<void> loadDebts() async {
    try {
      isLoading(true);
      final data = await _db.database.rawQuery('''
        SELECT d.*, c.name as customer_name 
        FROM debts d 
        JOIN customers c ON d.customer_id = c.id 
        ORDER BY d.created_at DESC
      ''');

      debts.value = data.map((json) => Debt.fromMap(json)).toList();
      filterDebts();
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data hutang');
    } finally {
      isLoading(false);
    }
  }

  void filterDebts() {
    if (selectedStatus.value == 'all') {
      filteredDebts.value = debts;
    } else {
      filteredDebts.value = debts.where((debt) =>
      debt.status == selectedStatus.value
      ).toList();
    }
  }

  void changeFilter(String status) {
    selectedStatus.value = status;
    filterDebts();
  }

  void showPaymentDialog(Debt debt) {
    paymentAmountController.text = debt.remainingAmount.toString();
    paymentNotesController.clear();

    Get.dialog(
      AlertDialog(
        title: Text('Bayar Hutang'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pelanggan: ${debt.customerName}'),
            Text('Sisa Hutang: ${formatCurrency(debt.remainingAmount)}'),

            SizedBox(height: 16),

            TextField(
              controller: paymentAmountController,
              decoration: InputDecoration(
                labelText: 'Jumlah Bayar',
                border: OutlineInputBorder(),
                prefixText: 'Rp ',
              ),
              keyboardType: TextInputType.number,
            ),

            SizedBox(height: 12),

            TextField(
              controller: paymentNotesController,
              decoration: InputDecoration(
                labelText: 'Catatan (Opsional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => processPayment(debt),
            child: Text('Bayar'),
          ),
        ],
      ),
    );
  }

  Future<void> processPayment(Debt debt) async {
    final paymentAmount = double.tryParse(paymentAmountController.text);

    if (paymentAmount == null || paymentAmount <= 0) {
      Get.snackbar('Error', 'Jumlah pembayaran tidak valid');
      return;
    }

    if (paymentAmount > debt.remainingAmount) {
      Get.snackbar('Error', 'Jumlah pembayaran melebihi sisa hutang');
      return;
    }

    try {
      // Record payment
      await _db.database.insert('debt_payments', {
        'debt_id': debt.id,
        'amount': paymentAmount,
        'payment_date': DateTime.now().toIso8601String(),
        'notes': paymentNotesController.text.isEmpty ? null : paymentNotesController.text,
      });

      // Update debt
      final newPaidAmount = debt.paidAmount + paymentAmount;
      final newRemainingAmount = debt.amount - newPaidAmount;
      final newStatus = newRemainingAmount <= 0 ? 'paid' : 'unpaid';

      await _db.database.update(
        'debts',
        {
          'paid_amount': newPaidAmount,
          'remaining_amount': newRemainingAmount,
          'status': newStatus,
        },
        where: 'id = ?',
        whereArgs: [debt.id],
      );

      Get.back();
      Get.snackbar('Sukses', 'Pembayaran berhasil dicatat');
      await loadDebts();

    } catch (e) {
      Get.snackbar('Error', 'Gagal memproses pembayaran');
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String getStatusText(String status) {
    switch (status) {
      case 'paid':
        return 'Lunas';
      case 'unpaid':
        return 'Belum Lunas';
      default:
        return 'Tidak Diketahui';
    }
  }

  String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('dd/MM/yyyy').format(date);
  }

  bool isOverdue(Debt debt) {
    if (debt.dueDate == null || debt.status == 'paid') return false;

    final dueDate = DateTime.parse(debt.dueDate!);
    return DateTime.now().isAfter(dueDate);
  }
}
