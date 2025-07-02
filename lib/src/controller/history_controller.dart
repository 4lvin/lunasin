import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/invoice_model.dart';
import '../services/db_service.dart';
import '../services/print_service.dart';

class InvoiceHistoryController extends GetxController {
  final DatabaseService _db = Get.find<DatabaseService>();
  final PrintService _printService = Get.find<PrintService>();

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
        backgroundColor: Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.receipt_outlined, color: Color(0xFF10B981)),
            ),
            SizedBox(width: 12),
            Text(
              'Detail Invoice',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF374151),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('No. Invoice', invoice.invoiceNumber),
                    _buildDetailRow(
                        'Tanggal',
                        DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(invoice.createdAt))
                    ),
                    if (invoice.customerName != null)
                      _buildDetailRow('Pelanggan', invoice.customerName!),
                  ],
                ),
              ),

              SizedBox(height: 16),

              Text(
                'Item Pembelian:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),

              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF374151),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ...items.map((item) => Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${item.quantity} x ${formatCurrency(item.price)}',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formatCurrency(item.total),
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),

              SizedBox(height: 16),

              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF374151),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildTotalRow('Subtotal', formatCurrency(invoice.subtotal)),
                    if (invoice.discount > 0)
                      _buildTotalRow(
                        'Diskon',
                        '-${formatCurrency(invoice.discount)}',
                        color: Color(0xFFEF4444),
                      ),
                    if (invoice.tax > 0)
                      _buildTotalRow(
                        'Pajak',
                        '+${formatCurrency(invoice.tax)}',
                        color: Color(0xFFF59E0B),
                      ),
                    Divider(color: Colors.white24),
                    _buildTotalRow(
                      'Total',
                      formatCurrency(invoice.total),
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Tutup',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                Get.back();
                printInvoice(invoice, items);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(Icons.print, color: Colors.white),
              label: Text(
                'Cetak',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {Color? color, bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.white : Colors.white70,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isTotal ? Color(0xFF10B981) : (color ?? Colors.white),
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void printInvoice(Invoice invoice, List<InvoiceItem> items) {
    if (!_printService.isConnected.value) {
      _showPrintOptions(invoice, items);
    } else {
      _printService.printInvoice(
        invoice,
        items,
        storeName: _printService.storeName.value,
        storeAddress: _printService.storeAddress.value,
      );
    }
  }

  void _showPrintOptions(Invoice invoice, List<InvoiceItem> items) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.print, color: Color(0xFF4F46E5)),
            SizedBox(width: 8),
            Text(
              'Opsi Cetak',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.bluetooth, color: Color(0xFF3B82F6)),
              ),
              title: Text(
                'Cetak via Bluetooth',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Hubungkan ke printer thermal 58mm',
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () {
                Get.back();
                if (_printService.isConnected.value) {
                  _printService.printInvoice(
                    invoice,
                    items,
                    storeName: _printService.storeName.value,
                    storeAddress: _printService.storeAddress.value,
                  );
                } else {
                  _printService.showDeviceSelectionDialog();
                }
              },
            ),
            SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.share, color: Color(0xFF10B981)),
              ),
              title: Text(
                'Bagikan Invoice',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Bagikan detail invoice',
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () {
                Get.back();
                _shareInvoice(invoice, items);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Batal',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  void _shareInvoice(Invoice invoice, List<InvoiceItem> items) {
    String invoiceText = '''
${_printService.storeName.value}
${_printService.storeAddress.value.isNotEmpty ? _printService.storeAddress.value + '\n' : ''}
================================

INVOICE
No: ${invoice.invoiceNumber}
Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(invoice.createdAt))}
${invoice.customerName != null ? 'Pelanggan: ${invoice.customerName}\n' : ''}
--------------------------------

ITEM PEMBELIAN:
${items.map((item) => '''
${item.productName}
${item.quantity}x${formatCurrency(item.price)} = ${formatCurrency(item.total)}
''').join('')}
--------------------------------
Subtotal: ${formatCurrency(invoice.subtotal)}
${invoice.discount > 0 ? 'Diskon: -${formatCurrency(invoice.discount)}\n' : ''}${invoice.tax > 0 ? 'Pajak: +${formatCurrency(invoice.tax)}\n' : ''}
TOTAL: ${formatCurrency(invoice.total)}

================================
Terima kasih atas kunjungan Anda
''';

    Get.dialog(
      AlertDialog(
        backgroundColor: Color(0xFF1F2937),
        title: Text(
          'Invoice ${invoice.invoiceNumber}',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Text(
            invoiceText,
            style: TextStyle(
              color: Colors.white70,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Tutup', style: TextStyle(color: Colors.white54)),
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