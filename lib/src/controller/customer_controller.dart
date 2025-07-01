import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/customer_model.dart';
import '../services/db_service.dart';

class CustomersController extends GetxController {
  final DatabaseService _db = Get.find<DatabaseService>();

  var customers = <Customer>[].obs;
  var filteredCustomers = <Customer>[].obs;
  var isLoading = true.obs;
  var searchQuery = ''.obs;

  final searchController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadCustomers();

    searchController.addListener(() {
      searchQuery.value = searchController.text;
      filterCustomers();
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.onClose();
  }

  Future<void> loadCustomers() async {
    try {
      isLoading(true);
      final data = await _db.database.query('customers', orderBy: 'name ASC');
      customers.value = data.map((json) => Customer.fromMap(json)).toList();
      filterCustomers();
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data pelanggan');
    } finally {
      isLoading(false);
    }
  }

  void filterCustomers() {
    if (searchQuery.value.isEmpty) {
      filteredCustomers.value = customers;
    } else {
      filteredCustomers.value = customers.where((customer) =>
      customer.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          (customer.phone?.toLowerCase().contains(searchQuery.value.toLowerCase()) ?? false)
      ).toList();
    }
  }

  Future<void> addCustomer() async {
    if (nameController.text.isEmpty) {
      Get.snackbar('Error', 'Nama pelanggan wajib diisi');
      return;
    }

    try {
      final customer = Customer(
        name: nameController.text,
        phone: phoneController.text.isEmpty ? null : phoneController.text,
        address: addressController.text.isEmpty ? null : addressController.text,
        createdAt: DateTime.now().toIso8601String(),
      );

      await _db.database.insert('customers', customer.toMap());

      nameController.clear();
      phoneController.clear();
      addressController.clear();

      Get.back();
      Get.snackbar('Sukses', 'Pelanggan berhasil ditambahkan');
      await loadCustomers();
    } catch (e) {
      Get.snackbar('Error', 'Gagal menambahkan pelanggan');
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    nameController.text = customer.name;
    phoneController.text = customer.phone ?? '';
    addressController.text = customer.address ?? '';

    Get.dialog(
      AlertDialog(
        title: Text('Edit Pelanggan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nama Pelanggan *',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Nomor HP',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: 'Alamat',
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
            onPressed: () async {
              await _saveCustomerUpdate(customer);
            },
            child: Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCustomerUpdate(Customer customer) async {
    if (nameController.text.isEmpty) {
      Get.snackbar('Error', 'Nama pelanggan wajib diisi');
      return;
    }

    try {
      await _db.database.update(
        'customers',
        {
          'name': nameController.text,
          'phone': phoneController.text.isEmpty ? null : phoneController.text,
          'address': addressController.text.isEmpty ? null : addressController.text,
        },
        where: 'id = ?',
        whereArgs: [customer.id],
      );

      Get.back();
      Get.snackbar('Sukses', 'Pelanggan berhasil diperbarui');
      await loadCustomers();
    } catch (e) {
      Get.snackbar('Error', 'Gagal memperbarui pelanggan');
    }
  }

  Future<void> deleteCustomer(Customer customer) async {
    Get.dialog(
      AlertDialog(
        title: Text('Hapus Pelanggan'),
        content: Text('Apakah Anda yakin ingin menghapus pelanggan "${customer.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _confirmDeleteCustomer(customer);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteCustomer(Customer customer) async {
    try {
      await _db.database.delete(
        'customers',
        where: 'id = ?',
        whereArgs: [customer.id],
      );

      Get.back();
      Get.snackbar('Sukses', 'Pelanggan berhasil dihapus');
      await loadCustomers();
    } catch (e) {
      Get.snackbar('Error', 'Gagal menghapus pelanggan');
    }
  }
}
