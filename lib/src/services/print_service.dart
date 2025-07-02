// lib/src/services/print_service.dart
import 'dart:async';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:flutter/material.dart' hide Alignment;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
// import 'package:permission_handler/permission_handler.dart';
import '../models/invoice_model.dart';
import '../models/debt_model.dart';
import 'db_service.dart';

class PrintService extends GetxService {
  final EscCommand _esc = EscCommand();
  final DatabaseService _db = Get.find<DatabaseService>();

  List<BluetoothDevice> devices = [];
  BluetoothDevice? selectedDevice;

  StreamSubscription<List<BluetoothDevice>>? _scanSubscription;
  StreamSubscription<BlueState>? _connectionSubscription;

  var isConnected = false.obs;
  var connectedDevice = Rxn<BluetoothDevice>();
  var availableDevices = <BluetoothDevice>[].obs;
  var isScanning = false.obs;
  var isPrinting = false.obs;
  var storeName = 'TOKO SAYA'.obs;
  var storeAddress = ''.obs;

  bool _isConnected = false;

  @override
  void onInit() {
    super.onInit();
    _loadStoreSettings();
  }

  @override
  void onClose() {
    dispose();
    super.onClose();
  }

  Future<void> _loadStoreSettings() async {
    try {
      final settings = await _db.database.query('settings');
      for (final setting in settings) {
        switch (setting['key']) {
          case 'store_name':
            storeName.value = setting['value'] as String;
            break;
          case 'store_address':
            storeAddress.value = setting['value'] as String;
            break;
        }
      }
    } catch (e) {
      print('Error loading store settings: $e');
    }
  }

  Future<void> startScan({Duration timeout = const Duration(seconds: 4)}) async {
    try {
      isScanning.value = true;
      devices.clear();
      availableDevices.clear();

      // Request BLE permissions
      // await [
      //   Permission.bluetoothScan,
      //   Permission.bluetoothConnect,
      //   Permission.location,
      // ].request();

      await BluetoothPrintPlus.startScan(timeout: timeout);

      _scanSubscription?.cancel();
      _scanSubscription = BluetoothPrintPlus.scanResults.listen((results) {
        devices = results;
        availableDevices.value = results;
        print("Found devices: ${devices.length}");
      });

      await Future.delayed(timeout);
      await BluetoothPrintPlus.stopScan();
      await _scanSubscription?.cancel();
    } catch (e) {
      Get.snackbar('Error', 'Gagal memindai perangkat: $e');
    } finally {
      isScanning.value = false;
    }
  }

  void selectDevice(BluetoothDevice device) {
    selectedDevice = device;
  }

  Future<bool> connect() async {
    if (selectedDevice == null) return false;

    _isConnected = false;
    _connectionSubscription?.cancel();

    final completer = Completer<bool>();

    _connectionSubscription = BluetoothPrintPlus.blueState.listen((state) {
      if (state == BlueState.blueOn) {
        _isConnected = true;
        isConnected.value = true;
        connectedDevice.value = selectedDevice;
        completer.complete(true);
      } else if (state == BlueState.blueOff) {
        _isConnected = false;
        isConnected.value = false;
        connectedDevice.value = null;
        completer.complete(false);
      }
    });

    await BluetoothPrintPlus.connect(selectedDevice!);

    // Wait maximum 5 seconds
    return completer.future.timeout(Duration(seconds: 5), onTimeout: () => false);
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      selectDevice(device);
      bool success = await connect();
      if (success) {
        Get.snackbar('Sukses', 'Terhubung ke ${device.name}');
      } else {
        Get.snackbar('Error', 'Gagal terhubung ke ${device.name}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal terhubung: $e');
    }
  }

  Future<void> disconnect() async {
    try {
      await BluetoothPrintPlus.disconnect();
      _connectionSubscription?.cancel();
      _isConnected = false;
      isConnected.value = false;
      connectedDevice.value = null;
      Get.snackbar('Info', 'Perangkat terputus');
    } catch (e) {
      Get.snackbar('Error', 'Gagal memutus koneksi: $e');
    }
  }

  Future<void> dispose() async {
    await _scanSubscription?.cancel();
    await disconnect();
  }

  void showDeviceSelectionDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Pilih Printer',
          style: TextStyle(color: Colors.white),
        ),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              if (isConnected.value && connectedDevice.value != null) ...[
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bluetooth_connected, color: Color(0xFF10B981)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Terhubung: ${connectedDevice.value!.name}',
                          style: TextStyle(color: Color(0xFF10B981)),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Color(0xFFEF4444)),
                        onPressed: disconnect,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
              ],

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isScanning.value ? null : startScan,
                      icon: isScanning.value
                          ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Icon(Icons.search),
                      label: Text(isScanning.value ? 'Memindai...' : 'Pindai'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              Expanded(
                child: Obx(() => ListView.builder(
                  itemCount: availableDevices.length,
                  itemBuilder: (context, index) {
                    final device = availableDevices[index];
                    return ListTile(
                      leading: Icon(Icons.print, color: Colors.white54),
                      title: Text(
                        device.name ?? 'Unknown Device',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        device.address ?? '',
                        style: TextStyle(color: Colors.white54),
                      ),
                      onTap: () {
                        connectToDevice(device);
                        Get.back();
                      },
                    );
                  },
                )),
              ),
            ],
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

  // Helper methods for formatting
  String centerText(String text, int lineWidth) {
    if (text.length >= lineWidth) return text;
    int padding = (lineWidth - text.length) ~/ 2;
    return ' ' * padding + text;
  }

  String createSpacedLine(String left, String right, int lineWidth) {
    int totalLength = left.length + right.length;
    if (totalLength >= lineWidth) return '$left $right';

    int spaces = lineWidth - totalLength;
    return left + ' ' * spaces + right;
  }

  double _parseAmount(String amount) {
    // Remove currency symbols and parse
    String cleaned = amount.replaceAll(RegExp(r'[^\d,.]'), '');
    cleaned = cleaned.replaceAll(',', '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  Future<void> printInvoice(Invoice invoice, List<InvoiceItem> items, {
    String? storeName,
    String? storeAddress,
  }) async {
    if (!isConnected.value) {
      Get.snackbar('Error', 'Tidak ada printer yang terhubung');
      return;
    }

    try {
      isPrinting.value = true;

      // Ensure printer is connected
      if (selectedDevice == null) {
        throw Exception("Printer belum dipilih");
      }

      final connected = await connect();
      if (!connected) {
        throw Exception("Gagal terhubung ke printer");
      }

      await _esc.cleanCommand();
      const int lineWidth = 32;
      const String separator = '--------------------------------';

      // Header - Store Info
      await _esc.text(
        content: centerText(storeName ?? this.storeName.value, lineWidth),
        alignment: Alignment.center,
        style: EscTextStyle.bold,
        fontSize: EscFontSize.size2,
      );
      await _esc.text(content: '');

      if ((storeAddress ?? this.storeAddress.value).isNotEmpty) {
        await _esc.text(
          content: centerText(storeAddress ?? this.storeAddress.value, lineWidth),
          alignment: Alignment.center,
        );
      }
      await _esc.text(content: '');
      await _esc.text(content: separator);

      // Invoice Info
      await _esc.text(
        content: centerText('INVOICE', lineWidth),
        alignment: Alignment.center,
        style: EscTextStyle.bold,
      );
      await _esc.text(content: '');

      final dateTime = DateTime.parse(invoice.createdAt);
      final datePart = DateFormat('dd/MM/yyyy').format(dateTime);
      final timePart = DateFormat('HH:mm').format(dateTime);

      await _esc.text(
        content: createSpacedLine('No', invoice.invoiceNumber, lineWidth),
      );
      await _esc.text(
        content: createSpacedLine('Tanggal', datePart, lineWidth),
      );
      await _esc.text(content: createSpacedLine('Waktu', timePart, lineWidth));

      if (invoice.customerName != null) {
        await _esc.text(
          content: createSpacedLine('Pelanggan', invoice.customerName!, lineWidth),
        );
      }
      await _esc.text(content: separator);

      // Items Header
      await _esc.text(content: 'ITEM PEMBELIAN', style: EscTextStyle.bold);
      await _esc.text(content: '');

      // Items with better formatting
      for (final item in items) {
        final name = item.productName;
        final qty = item.quantity;
        final price = item.price;
        final totalPrice = item.total;

        // Product name (truncate if too long)
        String displayName = name.length > lineWidth
            ? name.substring(0, lineWidth - 3) + '...'
            : name;
        await _esc.text(content: displayName);

        // Quantity x Price = Total
        String qtyPrice = '${qty}x${_formatCurrency(price)}';
        String totalStr = _formatCurrency(totalPrice);
        await _esc.text(
          content: createSpacedLine(qtyPrice, totalStr, lineWidth),
        );
        await _esc.text(content: '');
      }

      await _esc.text(content: separator);

      // Summary
      await _esc.text(
        content: createSpacedLine(
          'Subtotal',
          _formatCurrency(invoice.subtotal),
          lineWidth,
        ),
      );

      if (invoice.discount > 0) {
        await _esc.text(
          content: createSpacedLine(
            'Diskon',
            '-${_formatCurrency(invoice.discount)}',
            lineWidth,
          ),
        );
      }

      if (invoice.tax > 0) {
        await _esc.text(
          content: createSpacedLine(
            'Pajak',
            '+${_formatCurrency(invoice.tax)}',
            lineWidth,
          ),
        );
      }

      await _esc.text(content: '');

      await _esc.text(
        content: createSpacedLine(
          'TOTAL',
          _formatCurrency(invoice.total),
          lineWidth,
        ),
        style: EscTextStyle.bold,
        fontSize: EscFontSize.size1,
      );

      await _esc.text(content: separator);

      // Footer
      await _esc.text(
        content: centerText('TERIMA KASIH', lineWidth),
        alignment: Alignment.center,
        style: EscTextStyle.bold,
      );
      await _esc.text(
        content: centerText('ATAS KUNJUNGAN ANDA', lineWidth),
        alignment: Alignment.center,
      );
      await _esc.text(content: '');
      await _esc.text(content: '');
      await _esc.text(content: '');

      // Print the receipt
      await _esc.print();
      final cmd = await _esc.getCommand();

      if (cmd != null) {
        await BluetoothPrintPlus.write(cmd);
        Get.snackbar(
          'Sukses',
          'Invoice berhasil dicetak',
          backgroundColor: Color(0xFF10B981),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal mencetak: $e',
        backgroundColor: Color(0xFFEF4444),
        colorText: Colors.white,
      );
    } finally {
      isPrinting.value = false;
    }
  }

  Future<void> printDebtReceipt(Debt debt, {
    String? storeName,
    String? storeAddress,
    double? paymentAmount,
    String? notes,
  }) async {
    if (!isConnected.value) {
      Get.snackbar('Error', 'Tidak ada printer yang terhubung');
      return;
    }

    try {
      isPrinting.value = true;

      // Ensure printer is connected
      if (selectedDevice == null) {
        throw Exception("Printer belum dipilih");
      }

      final connected = await connect();
      if (!connected) {
        throw Exception("Gagal terhubung ke printer");
      }

      await _esc.cleanCommand();
      const int lineWidth = 32;
      const String separator = '--------------------------------';

      // Header - Store Info
      await _esc.text(
        content: centerText(storeName ?? this.storeName.value, lineWidth),
        alignment: Alignment.center,
        style: EscTextStyle.bold,
        fontSize: EscFontSize.size2,
      );
      await _esc.text(content: '');

      if ((storeAddress ?? this.storeAddress.value).isNotEmpty) {
        await _esc.text(
          content: centerText(storeAddress ?? this.storeAddress.value, lineWidth),
          alignment: Alignment.center,
        );
      }
      await _esc.text(content: '');
      await _esc.text(content: separator);

      // Receipt type
      String receiptType = paymentAmount != null ? 'BUKTI PEMBAYARAN HUTANG' : 'BUKTI HUTANG';
      await _esc.text(
        content: centerText(receiptType, lineWidth),
        alignment: Alignment.center,
        style: EscTextStyle.bold,
      );
      await _esc.text(content: '');

      final now = DateTime.now();
      final datePart = DateFormat('dd/MM/yyyy').format(now);
      final timePart = DateFormat('HH:mm').format(now);

      await _esc.text(
        content: createSpacedLine('Tanggal', datePart, lineWidth),
      );
      await _esc.text(content: createSpacedLine('Waktu', timePart, lineWidth));
      await _esc.text(
        content: createSpacedLine('Pelanggan', debt.customerName ?? 'Unknown', lineWidth),
      );
      await _esc.text(content: separator);

      // Debt details
      await _esc.text(
        content: createSpacedLine(
          'Total Hutang',
          _formatCurrency(debt.amount),
          lineWidth,
        ),
      );

      if (paymentAmount != null) {
        await _esc.text(
          content: createSpacedLine(
            'Pembayaran',
            _formatCurrency(paymentAmount),
            lineWidth,
          ),
        );

        double newRemaining = debt.remainingAmount - paymentAmount;
        await _esc.text(
          content: createSpacedLine(
            'Sisa Hutang',
            _formatCurrency(newRemaining),
            lineWidth,
          ),
          style: EscTextStyle.bold,
        );
      } else {
        await _esc.text(
          content: createSpacedLine(
            'Sisa Hutang',
            _formatCurrency(debt.remainingAmount),
            lineWidth,
          ),
          style: EscTextStyle.bold,
        );
      }

      if (debt.dueDate != null) {
        final dueDate = DateFormat('dd/MM/yyyy').format(DateTime.parse(debt.dueDate!));
        await _esc.text(
          content: createSpacedLine('Jatuh Tempo', dueDate, lineWidth),
        );
      }

      if (debt.description != null && debt.description!.isNotEmpty) {
        await _esc.text(content: '');
        await _esc.text(content: 'Keterangan:', style: EscTextStyle.bold);
        await _esc.text(content: debt.description!);
      }

      if (notes != null && notes.isNotEmpty) {
        await _esc.text(content: '');
        await _esc.text(content: 'Catatan:', style: EscTextStyle.bold);
        await _esc.text(content: notes);
      }

      await _esc.text(content: separator);

      // Footer
      await _esc.text(
        content: centerText('TERIMA KASIH', lineWidth),
        alignment: Alignment.center,
        style: EscTextStyle.bold,
      );
      await _esc.text(content: '');
      await _esc.text(content: '');
      await _esc.text(content: '');

      // Print the receipt
      await _esc.print();
      final cmd = await _esc.getCommand();

      if (cmd != null) {
        await BluetoothPrintPlus.write(cmd);
        Get.snackbar(
          'Sukses',
          'Bukti hutang berhasil dicetak',
          backgroundColor: Color(0xFF10B981),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal mencetak: $e',
        backgroundColor: Color(0xFFEF4444),
        colorText: Colors.white,
      );
    } finally {
      isPrinting.value = false;
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }
}