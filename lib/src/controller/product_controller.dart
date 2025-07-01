import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/products_model.dart';
import '../services/db_service.dart';

class ProductsController extends GetxController {
  final DatabaseService _db = Get.find<DatabaseService>();

  var products = <Product>[].obs;
  var filteredProducts = <Product>[].obs;
  var isLoading = true.obs;
  var searchQuery = ''.obs;

  final searchController = TextEditingController();
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadProducts();

    // Listen to search changes
    searchController.addListener(() {
      searchQuery.value = searchController.text;
      filterProducts();
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    super.onClose();
  }

  Future<void> loadProducts() async {
    try {
      isLoading(true);
      final data = await _db.database.query('products', orderBy: 'name ASC');
      products.value = data.map((json) => Product.fromMap(json)).toList();
      filterProducts();
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data produk');
    } finally {
      isLoading(false);
    }
  }

  void filterProducts() {
    if (searchQuery.value.isEmpty) {
      filteredProducts.value = products;
    } else {
      filteredProducts.value = products.where((product) =>
          product.name.toLowerCase().contains(searchQuery.value.toLowerCase())
      ).toList();
    }
  }

  Future<void> addProduct() async {
    if (nameController.text.isEmpty || priceController.text.isEmpty) {
      Get.snackbar('Error', 'Nama dan harga produk wajib diisi');
      return;
    }

    try {
      final product = Product(
        name: nameController.text,
        price: double.parse(priceController.text),
        stock: int.tryParse(stockController.text) ?? 0,
        createdAt: DateTime.now().toIso8601String(),
      );

      await _db.database.insert('products', product.toMap());

      // Clear form
      nameController.clear();
      priceController.clear();
      stockController.clear();

      Get.back();
      Get.snackbar('Sukses', 'Produk berhasil ditambahkan');
      await loadProducts();
    } catch (e) {
      Get.snackbar('Error', 'Gagal menambahkan produk');
    }
  }

  Future<void> updateProduct(Product product) async {
    nameController.text = product.name;
    priceController.text = product.price.toString();
    stockController.text = product.stock.toString();

    Get.dialog(
      AlertDialog(
        title: Text('Edit Produk'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nama Produk',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: priceController,
              decoration: InputDecoration(
                labelText: 'Harga',
                border: OutlineInputBorder(),
                prefixText: 'Rp ',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            TextField(
              controller: stockController,
              decoration: InputDecoration(
                labelText: 'Stok (Opsional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveProductUpdate(product);
            },
            child: Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProductUpdate(Product product) async {
    if (nameController.text.isEmpty || priceController.text.isEmpty) {
      Get.snackbar('Error', 'Nama dan harga produk wajib diisi');
      return;
    }

    try {
      await _db.database.update(
        'products',
        {
          'name': nameController.text,
          'price': double.parse(priceController.text),
          'stock': int.tryParse(stockController.text) ?? 0,
        },
        where: 'id = ?',
        whereArgs: [product.id],
      );

      Get.back();
      Get.snackbar('Sukses', 'Produk berhasil diperbarui');
      await loadProducts();
    } catch (e) {
      Get.snackbar('Error', 'Gagal memperbarui produk');
    }
  }

  Future<void> deleteProduct(Product product) async {
    Get.dialog(
      AlertDialog(
        title: Text('Hapus Produk'),
        content: Text('Apakah Anda yakin ingin menghapus produk "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _confirmDeleteProduct(product);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteProduct(Product product) async {
    try {
      await _db.database.delete(
        'products',
        where: 'id = ?',
        whereArgs: [product.id],
      );

      Get.back();
      Get.snackbar('Sukses', 'Produk berhasil dihapus');
      await loadProducts();
    } catch (e) {
      Get.snackbar('Error', 'Gagal menghapus produk');
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
