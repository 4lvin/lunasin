import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pengaturan'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store Information
              Text(
                'Informasi Toko',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              TextField(
                controller: controller.storeNameController,
                decoration: InputDecoration(
                  labelText: 'Nama Toko',
                  border: OutlineInputBorder(),
                ),
              ),

              SizedBox(height: 12),

              TextField(
                controller: controller.storeAddressController,
                decoration: InputDecoration(
                  labelText: 'Alamat Toko',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.saveSettings,
                  child: Text('Simpan Pengaturan'),
                ),
              ),

              SizedBox(height: 32),

              // Data Management
              Text(
                'Manajemen Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.file_download, color: Colors.blue),
                      title: Text('Ekspor Data'),
                      subtitle: Text('Ekspor data ke file CSV'),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: controller.exportData,
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.backup, color: Colors.green),
                      title: Text('Backup Database'),
                      subtitle: Text('Buat cadangan database'),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: controller.backupDatabase,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // App Information
              Text(
                'Informasi Aplikasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              Card(
                child: ListTile(
                  leading: Icon(Icons.info, color: Colors.blue),
                  title: Text('Tentang Aplikasi'),
                  subtitle: Text('Versi dan informasi aplikasi'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: controller.showAbout,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}