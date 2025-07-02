import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/debt_model.dart';
import '../services/db_service.dart';
import '../services/print_service.dart';

class DebtListController extends GetxController {
  final DatabaseService _db = Get.find<DatabaseService>();
  final PrintService _printService = Get.find<PrintService>();

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
              child: Icon(Icons.payment, color: Color(0xFF10B981)),
            ),
            SizedBox(width: 12),
            Text(
              'Bayar Hutang',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Hutang
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF374151),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildPaymentDetailRow('Pelanggan', debt.customerName ?? 'Unknown'),
                  _buildPaymentDetailRow('Total Hutang', formatCurrency(debt.amount)),
                  _buildPaymentDetailRow('Sudah Dibayar', formatCurrency(debt.paidAmount)),
                  Divider(color: Colors.white24),
                  _buildPaymentDetailRow(
                    'Sisa Hutang',
                    formatCurrency(debt.remainingAmount),
                    valueColor: Color(0xFFF59E0B),
                    isBold: true,
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Input Jumlah Bayar
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF374151),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: paymentAmountController,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Jumlah Bayar',
                  labelStyle: TextStyle(color: Colors.white54),
                  prefixIcon: Container(
                    margin: EdgeInsets.all(12),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.monetization_on_outlined,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                  ),
                  prefixText: 'Rp ',
                  prefixStyle: TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),

            SizedBox(height: 12),

            // Input Catatan
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF374151),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: paymentNotesController,
                style: TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  labelStyle: TextStyle(color: Colors.white54),
                  prefixIcon: Container(
                    margin: EdgeInsets.all(12),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.note_outlined,
                      color: Color(0xFF3B82F6),
                      size: 20,
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Quick Amount Buttons
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      paymentAmountController.text = (debt.remainingAmount / 2).toStringAsFixed(0);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Color(0xFF4F46E5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xFF4F46E5).withOpacity(0.3)),
                      ),
                      child: Text(
                        '50%',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF4F46E5),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      paymentAmountController.text = debt.remainingAmount.toStringAsFixed(0);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xFF10B981).withOpacity(0.3)),
                      ),
                      child: Text(
                        'Lunas',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton.icon(
              onPressed: () => processPayment(debt),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(Icons.payment, color: Colors.white),
              label: Text(
                'Bayar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

// Helper method untuk payment detail row
  Widget _buildPaymentDetailRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _askPrintPaymentReceipt(Debt debt, double paymentAmount, String notes) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.receipt_long, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text(
              'Cetak Bukti Pembayaran?',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'Pembayaran berhasil dicatat. Apakah Anda ingin mencetak bukti pembayaran?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Tidak',
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
                _printPaymentReceipt(debt, paymentAmount, notes);
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

  void _printPaymentReceipt(Debt debt, double paymentAmount, String notes) {
    if (!_printService.isConnected.value) {
      _showPrintOptions(debt, paymentAmount, notes);
    } else {
      _printService.printDebtReceipt(
        debt,
        storeName: _printService.storeName.value,
        storeAddress: _printService.storeAddress.value,
        paymentAmount: paymentAmount,
        notes: notes.isNotEmpty ? notes : null,
      );
    }
  }

  void _showPrintOptions(Debt debt, double paymentAmount, String notes) {
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
                  _printService.printDebtReceipt(
                    debt,
                    storeName: _printService.storeName.value,
                    storeAddress: _printService.storeAddress.value,
                    paymentAmount: paymentAmount,
                    notes: notes.isNotEmpty ? notes : null,
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
                'Bagikan Bukti',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Bagikan detail pembayaran',
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () {
                Get.back();
                _sharePaymentReceipt(debt, paymentAmount, notes);
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

  void _sharePaymentReceipt(Debt debt, double paymentAmount, String notes) {
    String receiptText = '''
${_printService.storeName.value}
${_printService.storeAddress.value.isNotEmpty ? _printService.storeAddress.value + '\n' : ''}
================================

BUKTI PEMBAYARAN HUTANG
Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}
Pelanggan: ${debt.customerName ?? 'Unknown'}

--------------------------------
Total Hutang: ${formatCurrency(debt.amount)}
Pembayaran: ${formatCurrency(paymentAmount)}
Sisa Hutang: ${formatCurrency(debt.remainingAmount - paymentAmount)}

${debt.dueDate != null ? 'Jatuh Tempo: ${formatDate(debt.dueDate!)}\n' : ''}${debt.description != null && debt.description!.isNotEmpty ? 'Keterangan: ${debt.description}\n' : ''}${notes.isNotEmpty ? 'Catatan: $notes\n' : ''}
================================

Terima kasih
''';

    Get.dialog(
      AlertDialog(
        backgroundColor: Color(0xFF1F2937),
        title: Text(
          'Bukti Pembayaran Hutang',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Text(
            receiptText,
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

  // Method showDebtDetail yang sudah diperbaiki
  void showDebtDetail(Debt debt) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Detail Hutang',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Pelanggan', debt.customerName ?? 'Unknown'),
              _buildDetailRow('Total Hutang', formatCurrency(debt.amount)),
              _buildDetailRow('Dibayar', formatCurrency(debt.paidAmount)),
              _buildDetailRow('Sisa Hutang', formatCurrency(debt.remainingAmount)),
              if (debt.dueDate != null)
                _buildDetailRow('Jatuh Tempo', formatDate(debt.dueDate!)),
              _buildDetailRow('Status', getStatusText(debt.status)),
              if (debt.description != null && debt.description!.isNotEmpty)
                _buildDetailRow('Keterangan', debt.description!),
              _buildDetailRow('Dibuat', formatDate(debt.createdAt)),
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
          if (debt.status == 'unpaid')
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.back();
                  showPaymentDialog(debt);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(Icons.payment, color: Colors.white),
                label: Text(
                  'Bayar',
                  style: TextStyle(color: Colors.white),
                ),
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
                printDebtReceipt(debt);
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

  // Method printDebtReceipt yang diperbaiki
  void printDebtReceipt(Debt debt) {
    if (!_printService.isConnected.value) {
      _showDebtPrintOptions(debt);
    } else {
      _printService.printDebtReceipt(
        debt,
        storeName: _printService.storeName.value,
        storeAddress: _printService.storeAddress.value,
      );
    }
  }

  // Method khusus untuk print debt tanpa payment
  void _showDebtPrintOptions(Debt debt) {
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
                  _printService.printDebtReceipt(
                    debt,
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
                'Bagikan Bukti',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Bagikan detail hutang',
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () {
                Get.back();
                _shareDebtReceipt(debt);
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

  // Method untuk share debt receipt tanpa payment
  void _shareDebtReceipt(Debt debt) {
    String receiptText = '''
${_printService.storeName.value}
${_printService.storeAddress.value.isNotEmpty ? _printService.storeAddress.value + '\n' : ''}
================================

BUKTI HUTANG
Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}
Pelanggan: ${debt.customerName ?? 'Unknown'}

--------------------------------
Total Hutang: ${formatCurrency(debt.amount)}
Dibayar: ${formatCurrency(debt.paidAmount)}
Sisa Hutang: ${formatCurrency(debt.remainingAmount)}

${debt.dueDate != null ? 'Jatuh Tempo: ${formatDate(debt.dueDate!)}\n' : ''}${debt.description != null && debt.description!.isNotEmpty ? 'Keterangan: ${debt.description}\n' : ''}
Status: ${getStatusText(debt.status)}

================================

Terima kasih
''';

    Get.dialog(
      AlertDialog(
        backgroundColor: Color(0xFF1F2937),
        title: Text(
          'Bukti Hutang',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Text(
            receiptText,
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

  // Update processPayment untuk menambahkan auto print dialog
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
      Get.snackbar(
        'Sukses',
        'Pembayaran berhasil dicatat',
        backgroundColor: Color(0xFF10B981),
        colorText: Colors.white,
      );

      // Ask if user wants to print receipt
      _askPrintPaymentReceipt(debt, paymentAmount, paymentNotesController.text);

      await loadDebts();

    } catch (e) {
      Get.snackbar('Error', 'Gagal memproses pembayaran');
    }
  }

  // Method helper lainnya tetap sama...
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


  Color getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Color(0xFF10B981);
      case 'unpaid':
        return Color(0xFFF59E0B);
      default:
        return Colors.grey;
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