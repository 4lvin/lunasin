import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/customer_model.dart';
import '../models/invoice_model.dart';
import '../models/products_model.dart';
import '../services/db_service.dart';
import '../services/print_service.dart';

class InvoiceCreateController extends GetxController {
  final DatabaseService _db = Get.find<DatabaseService>();
  final PrintService _printService = Get.find<PrintService>();

  var customers = <Customer>[].obs;
  var products = <Product>[].obs;
  var selectedCustomer = Rxn<Customer>();
  var invoiceItems = <InvoiceItem>[].obs;
  var selectedProduct = Rxn<Product>();

  var subtotal = 0.0.obs;
  var discount = 0.0.obs;
  var tax = 0.0.obs;
  var total = 0.0.obs;

  var isLoading = false.obs;

  final quantityController = TextEditingController();
  final discountController = TextEditingController();
  final taxController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  @override
  void onClose() {
    quantityController.dispose();
    discountController.dispose();
    taxController.dispose();
    super.onClose();
  }


  Future<void> loadInitialData() async {
    try {
      isLoading(true);

      // Load customers
      final customerData = await _db.database.query('customers', orderBy: 'name ASC');
      customers.value = customerData.map((json) => Customer.fromMap(json)).toList();

      // Load products
      final productData = await _db.database.query('products', orderBy: 'name ASC');
      products.value = productData.map((json) => Product.fromMap(json)).toList();

    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data');
    } finally {
      isLoading(false);
    }
  }

  void addProductToInvoice() {
    if (selectedProduct.value == null) {
      Get.snackbar('Error', 'Pilih produk terlebih dahulu');
      return;
    }

    if (quantityController.text.isEmpty) {
      Get.snackbar('Error', 'Masukkan jumlah produk');
      return;
    }

    int quantity = int.tryParse(quantityController.text) ?? 0;
    if (quantity <= 0) {
      Get.snackbar('Error', 'Jumlah harus lebih dari 0');
      return;
    }

    final product = selectedProduct.value!;
    final itemTotal = product.price * quantity;

    // Check if product already exists in invoice
    final existingIndex = invoiceItems.indexWhere((item) => item.productId == product.id);

    if (existingIndex != -1) {
      // Update existing item
      final existingItem = invoiceItems[existingIndex];
      final newQuantity = existingItem.quantity + quantity;
      final newTotal = product.price * newQuantity;

      invoiceItems[existingIndex] = InvoiceItem(
        invoiceId: 0, // Will be set when saving
        productId: product.id!,
        productName: product.name,
        price: product.price,
        quantity: newQuantity,
        total: newTotal,
      );
    } else {
      // Add new item
      invoiceItems.add(InvoiceItem(
        invoiceId: 0, // Will be set when saving
        productId: product.id!,
        productName: product.name,
        price: product.price,
        quantity: quantity,
        total: itemTotal,
      ));
    }

    // Clear form
    selectedProduct.value = null;
    quantityController.clear();

    calculateTotal();
  }

  void removeProductFromInvoice(int index) {
    invoiceItems.removeAt(index);
    calculateTotal();
  }

  void calculateTotal() {
    subtotal.value = invoiceItems.fold(0.0, (sum, item) => sum + item.total);

    discount.value = double.tryParse(discountController.text) ?? 0.0;
    tax.value = double.tryParse(taxController.text) ?? 0.0;

    total.value = subtotal.value - discount.value + tax.value;
  }

  Future<void> saveInvoice() async {
    if (invoiceItems.isEmpty) {
      Get.snackbar('Error', 'Tambahkan minimal satu produk');
      return;
    }

    try {
      isLoading(true);

      // Generate invoice number
      final invoiceNumber = 'INV-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}';

      // Create invoice
      final invoice = Invoice(
        invoiceNumber: invoiceNumber,
        customerId: selectedCustomer.value?.id,
        customerName: selectedCustomer.value?.name, // Tambah ini
        subtotal: subtotal.value,
        discount: discount.value,
        tax: tax.value,
        total: total.value,
        createdAt: DateTime.now().toIso8601String(),
      );

      // Save invoice
      final invoiceId = await _db.database.insert('invoices', invoice.toMap());

      // Save invoice items
      for (final item in invoiceItems) {
        await _db.database.insert('invoice_items', {
          'invoice_id': invoiceId,
          'product_id': item.productId,
          'product_name': item.productName,
          'price': item.price,
          'quantity': item.quantity,
          'total': item.total,
        });
      }

      Get.snackbar('Sukses', 'Invoice berhasil disimpan');

      // Ask if user wants to print invoice
      _askPrintInvoice(invoice.copyWith(id: invoiceId), invoiceItems);

      // Reset form
      _resetForm();

    } catch (e) {
      Get.snackbar('Error', 'Gagal menyimpan invoice');
    } finally {
      isLoading(false);
    }
  }

  void _askPrintInvoice(Invoice invoice, List<InvoiceItem> items) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.print, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text(
              'Cetak Invoice?',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'Invoice berhasil disimpan. Apakah Anda ingin mencetak invoice sekarang?',
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
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                Get.back();
                _printInvoice(invoice, items);
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

  void _printInvoice(Invoice invoice, List<InvoiceItem> items) {
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


  void _resetForm() {
    selectedCustomer.value = null;
    selectedProduct.value = null;
    invoiceItems.clear();
    quantityController.clear();
    discountController.clear();
    taxController.clear();
    subtotal.value = 0.0;
    discount.value = 0.0;
    tax.value = 0.0;
    total.value = 0.0;
  }

  String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }
}