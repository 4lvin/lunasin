import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/customer_model.dart';
import '../models/debt_model.dart';
import '../services/db_service.dart';

class DebtCreateController extends GetxController {
  final DatabaseService _db = Get.find<DatabaseService>();

  var customers = <Customer>[].obs;
  var selectedCustomer = Rxn<Customer>();
  var isLoading = false.obs;
  var selectedDueDate = Rxn<DateTime>();

  final amountController = TextEditingController();
  final descriptionController = TextEditingController();

  var showSummary = false.obs;
  var amountText = ''.obs;

  @override
  void onInit() {
    super.onInit();
    amountController.addListener(() {
      amountText.value = amountController.text;
      showSummary.value = amountController.text.isNotEmpty;
    });
    loadCustomers();
  }

  @override
  void onClose() {
    amountController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  Future<void> loadCustomers() async {
    try {
      isLoading(true);
      final data = await _db.database.query('customers', orderBy: 'name ASC');
      customers.value = data.map((json) => Customer.fromMap(json)).toList();
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data pelanggan');
    } finally {
      isLoading(false);
    }
  }

  Future<void> selectDueDate() async {
    final date = await showDatePicker(
      context: Get.context!,
      initialDate: DateTime.now().add(Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (date != null) {
      selectedDueDate.value = date;
    }
  }

  Future<void> saveDebt() async {
    if (selectedCustomer.value == null) {
      Get.snackbar('Error', 'Pilih pelanggan terlebih dahulu');
      return;
    }

    if (amountController.text.isEmpty) {
      Get.snackbar('Error', 'Masukkan jumlah hutang');
      return;
    }

    final amount = double.tryParse(amountController.text);
    if (amount == null || amount <= 0) {
      Get.snackbar('Error', 'Jumlah hutang tidak valid');
      return;
    }

    try {
      isLoading(true);

      final debt = Debt(
        customerId: selectedCustomer.value!.id!,
        amount: amount,
        remainingAmount: amount,
        dueDate: selectedDueDate.value?.toIso8601String(),
        description: descriptionController.text.isEmpty ? null : descriptionController.text,
        createdAt: DateTime.now().toIso8601String(),
      );

      await _db.database.insert('debts', debt.toMap());

      Get.snackbar('Sukses', 'Hutang berhasil dicatat');
      _resetForm();

    } catch (e) {
      Get.snackbar('Error', 'Gagal menyimpan hutang');
    } finally {
      isLoading(false);
    }
  }

  void _resetForm() {
    selectedCustomer.value = null;
    selectedDueDate.value = null;
    amountController.clear();
    descriptionController.clear();
  }

  String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}