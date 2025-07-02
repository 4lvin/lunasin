import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/invoice_model.dart';
import '../services/db_service.dart';

class InvoiceHistoryController extends GetxController {
  final DatabaseService _db = Get.find<DatabaseService>();


  var invoices = <Invoice>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadInvoices();
  }

  Future<void> loadInvoices() async {
    try {
      isLoading(true);
      final data = await _db.database.rawQuery('''
        SELECT i.*, c.name as customer_name 
        FROM invoices i 
        LEFT JOIN customers c ON i.customer_id = c.id 
        ORDER BY i.created_at DESC
      ''');

      invoices.value = data.map((json) => Invoice.fromMap(json)).toList();
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat riwayat invoice');
    } finally {
      isLoading(false);
    }
  }

  Future<List<InvoiceItem>> getInvoiceItems(int invoiceId) async {
    try {
      final data = await _db.database.query(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
      );

      return data.map((json) => InvoiceItem.fromMap(json)).toList();
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat detail invoice');
      return [];
    }
  }

  void showInvoiceDetail(Invoice invoice) async {
    final items = await getInvoiceItems(invoice.id!);

    Get.dialog(
      AlertDialog(
        title: Text('Detail Invoice'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No. Invoice: ${invoice.invoiceNumber}'),
              Text('Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(invoice.createdAt))}'),
              if (invoice.customerName != null)
                Text('Pelanggan: ${invoice.customerName}'),

              SizedBox(height: 16),
              Text('Item:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),

              ...items.map((item) => Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('${item.productName} (${item.quantity}x)'),
                    ),
                    Text(formatCurrency(item.total)),
                  ],
                ),
              )),

              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    formatCurrency(invoice.total),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // TODO: Implement print functionality
              Get.snackbar('Info', 'Fitur cetak akan ditambahkan');
            },
            child: Text('Cetak'),
          ),
        ],
      ),
    );
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
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}
