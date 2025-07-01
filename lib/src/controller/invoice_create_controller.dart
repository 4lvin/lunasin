import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/customer_model.dart';
import '../models/invoice_model.dart';
import '../models/products_model.dart';
import '../services/db_service.dart';

class InvoiceCreateController extends GetxController {
  final DatabaseService _db = Get.find<DatabaseService>();

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

      // Reset form
      _resetForm();

    } catch (e) {
      Get.snackbar('Error', 'Gagal menyimpan invoice');
    } finally {
      isLoading(false);
    }
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