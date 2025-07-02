// lib/src/services/print_service.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:flutter/material.dart' hide Alignment;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/invoice_model.dart';
import '../models/debt_model.dart';
import 'db_service.dart';

class PrintService extends GetxService {
  final DatabaseService _db = Get.find<DatabaseService>();

  StreamSubscription<List<BluetoothDevice>>? _scanSubscription;
  StreamSubscription<BlueState>? _connectionSubscription;

  var isConnected = false.obs;
  var connectedDevice = Rxn<BluetoothDevice>();
  var availableDevices = <BluetoothDevice>[].obs;
  var isScanning = false.obs;
  var isPrinting = false.obs;
  var storeName = 'TOKO SAYA'.obs;
  var storeAddress = ''.obs;

  BluetoothDevice? _selectedDevice;

  @override
  void onInit() {
    super.onInit();
    _loadStoreSettings();
    _initBluetoothState();
  }

  @override
  void onClose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
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

  void _initBluetoothState() {
    _connectionSubscription = BluetoothPrintPlus.blueState.listen((state) {
      print('Bluetooth state: $state');
      switch (state) {
        case BlueState.blueOn:
          isConnected.value = true;
          break;
        case BlueState.blueOff:
          isConnected.value = false;
          connectedDevice.value = null;
          _selectedDevice = null;
          break;
      }
    });
  }

  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      isScanning.value = true;
      availableDevices.clear();

      // Start scanning
      await BluetoothPrintPlus.startScan(timeout: timeout);

      // Listen to scan results
      _scanSubscription?.cancel();
      _scanSubscription = BluetoothPrintPlus.scanResults.listen((devices) {
        availableDevices.value = devices.where((device) {
          // Filter only devices with names (likely printers)
          return device.name != null && device.name!.isNotEmpty;
        }).toList();
        print("Found ${availableDevices.length} devices");
      });

      // Wait for scan to complete
      await Future.delayed(timeout);
      await BluetoothPrintPlus.stopScan();
    } catch (e) {
      print('Scan error: $e');
      Get.snackbar(
        'Error',
        'Gagal memindai perangkat: $e',
        backgroundColor: Color(0xFFEF4444),
        colorText: Colors.white,
      );
    } finally {
      isScanning.value = false;
      _scanSubscription?.cancel();
    }
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      _selectedDevice = device;

      // Connect to the device
      await BluetoothPrintPlus.connect(device);

      // Wait a bit and check connection
      await Future.delayed(Duration(milliseconds: 500));

      // Update state
      connectedDevice.value = device;
      isConnected.value = true;

      Get.snackbar(
        'Berhasil',
        'Terhubung ke ${device.name}',
        backgroundColor: Color(0xFF10B981),
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      print('Connection error: $e');
      Get.snackbar(
        'Error',
        'Gagal terhubung ke ${device.name}: $e',
        backgroundColor: Color(0xFFEF4444),
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await BluetoothPrintPlus.disconnect();
      isConnected.value = false;
      connectedDevice.value = null;
      _selectedDevice = null;

      Get.snackbar(
        'Info',
        'Printer terputus',
        backgroundColor: Color(0xFF6B7280),
        colorText: Colors.white,
      );
    } catch (e) {
      print('Disconnect error: $e');
    }
  }

  void showDeviceSelectionDialog() {
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
              'Pilih Printer',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              // Connection Status
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Terhubung',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              connectedDevice.value!.name ?? 'Unknown',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 12,
                              ),
                            ),
                          ],
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

              // Scan Button
              Row(
                children: [
                  Expanded(
                    child: Obx(() => ElevatedButton.icon(
                      onPressed: isScanning.value ? null : startScan,
                      icon: isScanning.value
                          ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Icon(Icons.search, color: Colors.white),
                      label: Text(
                        isScanning.value ? 'Memindai...' : 'Pindai Printer',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4F46E5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Device List
              Expanded(
                child: Obx(() {
                  if (availableDevices.isEmpty && !isScanning.value) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bluetooth_disabled,
                            size: 48,
                            color: Colors.white54,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Tidak ada printer ditemukan',
                            style: TextStyle(color: Colors.white54),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Pastikan printer Bluetooth aktif',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: availableDevices.length,
                    itemBuilder: (context, index) {
                      final device = availableDevices[index];
                      final isCurrentDevice = connectedDevice.value?.address == device.address;

                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isCurrentDevice
                              ? Color(0xFF10B981).withOpacity(0.1)
                              : Color(0xFF374151),
                          borderRadius: BorderRadius.circular(12),
                          border: isCurrentDevice
                              ? Border.all(color: Color(0xFF10B981))
                              : null,
                        ),
                        child: ListTile(
                          leading: Icon(
                            isCurrentDevice
                                ? Icons.bluetooth_connected
                                : Icons.print,
                            color: isCurrentDevice
                                ? Color(0xFF10B981)
                                : Colors.white54,
                          ),
                          title: Text(
                            device.name ?? 'Unknown Device',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: isCurrentDevice
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            device.address ?? '',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          trailing: isCurrentDevice
                              ? Icon(Icons.check_circle, color: Color(0xFF10B981))
                              : Icon(Icons.arrow_forward_ios,
                              color: Colors.white54, size: 16),
                          onTap: isCurrentDevice
                              ? null
                              : () async {
                            final success = await connectToDevice(device);
                            if (success) {
                              Get.back();
                            }
                          },
                        ),
                      );
                    },
                  );
                }),
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

  // Helper method to create ESC/POS commands for thermal paper
  List<int> _buildReceiptData({
    required String storeName,
    required String storeAddress,
    required String receiptType,
    required Map<String, String> details,
    required List<Map<String, String>> items,
    required Map<String, String> totals,
  }) {
    List<int> bytes = [];

    // Initialize printer
    bytes.addAll([0x1B, 0x40]); // ESC @

    // Set character size and alignment
    bytes.addAll([0x1B, 0x21, 0x00]); // Normal size
    bytes.addAll([0x1B, 0x61, 0x01]); // Center align

    // Store name (larger font)
    bytes.addAll([0x1B, 0x21, 0x30]); // Double height and width
    bytes.addAll(storeName.codeUnits);
    bytes.addAll([0x0A, 0x0A]); // New lines

    // Store address (normal font)
    bytes.addAll([0x1B, 0x21, 0x00]); // Normal size
    if (storeAddress.isNotEmpty) {
      bytes.addAll(storeAddress.codeUnits);
      bytes.addAll([0x0A]);
    }

    // Separator line
    bytes.addAll([0x0A]);
    String separator = '================================';
    bytes.addAll(separator.substring(0, 32).codeUnits);
    bytes.addAll([0x0A]);

    // Receipt type
    bytes.addAll([0x1B, 0x21, 0x10]); // Bold
    bytes.addAll(receiptType.codeUnits);
    bytes.addAll([0x0A, 0x0A]);

    // Details
    bytes.addAll([0x1B, 0x21, 0x00]); // Normal size
    bytes.addAll([0x1B, 0x61, 0x00]); // Left align

    details.forEach((key, value) {
      String line = _formatLine(key, value, 32);
      bytes.addAll(line.codeUnits);
      bytes.addAll([0x0A]);
    });

    bytes.addAll(separator.substring(0, 32).codeUnits);
    bytes.addAll([0x0A]);

    // Items
    if (items.isNotEmpty) {
      for (var item in items) {
        // Item name
        bytes.addAll(item['name']!.codeUnits);
        bytes.addAll([0x0A]);

        // Quantity and price
        String qtyPrice = '${item['qty']}x${item['price']}';
        String total = item['total']!;
        String line = _formatLine(qtyPrice, total, 32);
        bytes.addAll(line.codeUnits);
        bytes.addAll([0x0A, 0x0A]);
      }

      bytes.addAll(separator.substring(0, 32).codeUnits);
      bytes.addAll([0x0A]);
    }

    // Totals
    totals.forEach((key, value) {
      String line = _formatLine(key, value, 32);
      if (key.contains('TOTAL')) {
        bytes.addAll([0x1B, 0x21, 0x10]); // Bold for total
      }
      bytes.addAll(line.codeUnits);
      bytes.addAll([0x0A]);
      if (key.contains('TOTAL')) {
        bytes.addAll([0x1B, 0x21, 0x00]); // Back to normal
      }
    });

    bytes.addAll(separator.substring(0, 32).codeUnits);
    bytes.addAll([0x0A, 0x0A]);

    // Footer
    bytes.addAll([0x1B, 0x61, 0x01]); // Center align
    bytes.addAll([0x1B, 0x21, 0x10]); // Bold
    bytes.addAll('TERIMA KASIH'.codeUnits);
    bytes.addAll([0x0A]);
    bytes.addAll([0x1B, 0x21, 0x00]); // Normal
    bytes.addAll('ATAS KUNJUNGAN ANDA'.codeUnits);
    bytes.addAll([0x0A, 0x0A, 0x0A, 0x0A]);

    // Cut paper
    bytes.addAll([0x1D, 0x56, 0x00]);

    return bytes;
  }

  String _formatLine(String left, String right, int width) {
    int totalLength = left.length + right.length;
    if (totalLength >= width) {
      return '$left $right';
    }
    int spaces = width - totalLength;
    return left + (' ' * spaces) + right;
  }

  Future<void> printInvoice(Invoice invoice, List<InvoiceItem> items, {
    String? storeName,
    String? storeAddress,
  }) async {
    if (!isConnected.value) {
      Get.snackbar(
        'Error',
        'Tidak ada printer yang terhubung',
        backgroundColor: Color(0xFFEF4444),
        colorText: Colors.white,
      );
      return;
    }

    try {
      isPrinting.value = true;

      final receiptData = _buildReceiptData(
        storeName: storeName ?? this.storeName.value,
        storeAddress: storeAddress ?? this.storeAddress.value,
        receiptType: 'INVOICE',
        details: {
          'No': invoice.invoiceNumber,
          'Tanggal': _formatDate(DateTime.parse(invoice.createdAt)),
          'Waktu': _formatTime(DateTime.parse(invoice.createdAt)),
          if (invoice.customerName != null) 'Pelanggan': invoice.customerName!,
        },
        items: items.map((item) => {
          'name': item.productName,
          'qty': item.quantity.toString(),
          'price': _formatCurrency(item.price),
          'total': _formatCurrency(item.total),
        }).toList(),
        totals: {
          'Subtotal': _formatCurrency(invoice.subtotal),
          if (invoice.discount > 0) 'Diskon': '-${_formatCurrency(invoice.discount)}',
          if (invoice.tax > 0) 'Pajak': '+${_formatCurrency(invoice.tax)}',
          'TOTAL': _formatCurrency(invoice.total),
        },
      );

      await BluetoothPrintPlus.write(receiptData as Uint8List?);

      Get.snackbar(
        'Berhasil',
        'Invoice berhasil dicetak',
        backgroundColor: Color(0xFF10B981),
        colorText: Colors.white,
      );
    } catch (e) {
      print('Print error: $e');
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
      Get.snackbar(
        'Error',
        'Tidak ada printer yang terhubung',
        backgroundColor: Color(0xFFEF4444),
        colorText: Colors.white,
      );
      return;
    }

    try {
      isPrinting.value = true;

      String receiptType = paymentAmount != null ? 'BUKTI PEMBAYARAN HUTANG' : 'BUKTI HUTANG';

      Map<String, String> details = {
        'Tanggal': _formatDate(DateTime.now()),
        'Waktu': _formatTime(DateTime.now()),
        'Pelanggan': debt.customerName ?? 'Unknown',
      };

      Map<String, String> totals = {
        'Total Hutang': _formatCurrency(debt.amount),
      };

      if (paymentAmount != null) {
        totals['Pembayaran'] = _formatCurrency(paymentAmount);
        totals['Sisa Hutang'] = _formatCurrency(debt.remainingAmount - paymentAmount);
      } else {
        totals['Sisa Hutang'] = _formatCurrency(debt.remainingAmount);
      }

      if (debt.dueDate != null) {
        details['Jatuh Tempo'] = _formatDate(DateTime.parse(debt.dueDate!));
      }

      final receiptData = _buildReceiptData(
        storeName: storeName ?? this.storeName.value,
        storeAddress: storeAddress ?? this.storeAddress.value,
        receiptType: receiptType,
        details: details,
        items: [], // No items for debt receipt
        totals: totals,
      );

      await BluetoothPrintPlus.write(receiptData as Uint8List?);

      Get.snackbar(
        'Berhasil',
        'Bukti hutang berhasil dicetak',
        backgroundColor: Color(0xFF10B981),
        colorText: Colors.white,
      );
    } catch (e) {
      print('Print error: $e');
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

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }
}