import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/db_service.dart';

class SettingsController extends GetxController {
  final DatabaseService _db = Get.find<DatabaseService>();

  var isLoading = false.obs;

  final storeNameController = TextEditingController();
  final storeAddressController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  @override
  void onClose() {
    storeNameController.dispose();
    storeAddressController.dispose();
    super.onClose();
  }

  Future<void> loadSettings() async {
    try {
      isLoading(true);

      final settings = await _db.database.query('settings');

      for (final setting in settings) {
        switch (setting['key']) {
          case 'store_name':
            storeNameController.text = setting['value'] as String;
            break;
          case 'store_address':
            storeAddressController.text = setting['value'] as String;
            break;
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat pengaturan');
    } finally {
      isLoading(false);
    }
  }

  Future<void> saveSettings() async {
    try {
      isLoading(true);

      await _db.database.update(
        'settings',
        {'value': storeNameController.text},
        where: 'key = ?',
        whereArgs: ['store_name'],
      );

      await _db.database.update(
        'settings',
        {'value': storeAddressController.text},
        where: 'key = ?',
        whereArgs: ['store_address'],
      );

      Get.snackbar('Sukses', 'Pengaturan berhasil disimpan');

    } catch (e) {
      Get.snackbar('Error', 'Gagal menyimpan pengaturan');
    } finally {
      isLoading(false);
    }
  }

  Future<void> exportData() async {
    try {
      isLoading(true);

      // TODO: Implement data export functionality
      Get.snackbar('Info', 'Fitur ekspor data akan ditambahkan');

    } catch (e) {
      Get.snackbar('Error', 'Gagal mengekspor data');
    } finally {
      isLoading(false);
    }
  }

  Future<void> backupDatabase() async {
    try {
      isLoading(true);

      // TODO: Implement database backup functionality
      Get.snackbar('Info', 'Fitur backup database akan ditambahkan');

    } catch (e) {
      Get.snackbar('Error', 'Gagal backup database');
    } finally {
      isLoading(false);
    }
  }

  void showAbout() {
    Get.dialog(
      AlertDialog(
        title: Text('Tentang Aplikasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aplikasi Kasir'),
            Text('Versi 1.0.0'),
            SizedBox(height: 8),
            Text('Fitur:'),
            Text('• Manajemen Produk & Pelanggan'),
            Text('• Pembuatan Invoice'),
            Text('• Pencatatan Hutang'),
            Text('• Dashboard & Laporan'),
            Text('• Offline & Lokal'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  }
}