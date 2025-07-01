import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/debt_create_controller.dart';
import '../../models/customer_model.dart';

class DebtCreateView extends GetView<DebtCreateController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1B3A), // Dark blue background
      appBar: AppBar(
        title: Text(
          'Catat Hutang',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Color(0xFF1A1B3A),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: Colors.white54),
            onPressed: () {
              // Show help dialog
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header info card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pencatatan Hutang',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Catat hutang pelanggan untuk tracking yang lebih baik',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Customer selection
              _buildSectionHeader(
                'Informasi Pelanggan',
                Icons.person_outline,
                isRequired: true,
              ),
              SizedBox(height: 12),
              _buildDropdownField<Customer>(
                value: controller.selectedCustomer.value,
                hint: 'Pilih Pelanggan',
                items: controller.customers.map((customer) {
                  return DropdownMenuItem(
                    value: customer,
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Color(0xFF3B82F6).withOpacity(0.1),
                          radius: 16,
                          child: Icon(
                            Icons.person,
                            size: 16,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          customer.name,
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (customer) {
                  controller.selectedCustomer.value = customer;
                },
              ),

              SizedBox(height: 24),

              // Amount input
              _buildSectionHeader(
                'Jumlah Hutang',
                Icons.attach_money_outlined,
                isRequired: true,
              ),
              SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: controller.amountController,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Masukkan jumlah hutang',
                    hintStyle: TextStyle(color: Colors.white54),
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Due date selection
              _buildSectionHeader(
                'Tanggal Jatuh Tempo',
                Icons.event_outlined,
              ),
              SizedBox(height: 12),
              InkWell(
                onTap: controller.selectDueDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.calendar_today_outlined,
                          color: Color(0xFF3B82F6),
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.selectedDueDate.value != null
                                  ? controller.formatDate(controller.selectedDueDate.value!)
                                  : 'Pilih tanggal jatuh tempo',
                              style: TextStyle(
                                color: controller.selectedDueDate.value != null
                                    ? Colors.white
                                    : Colors.white54,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (controller.selectedDueDate.value != null) ...[
                              SizedBox(height: 4),
                              Text(
                                _getDaysUntilDue(controller.selectedDueDate.value!),
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white54,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Description input
              _buildSectionHeader(
                'Keterangan',
                Icons.note_outlined,
              ),
              SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: controller.descriptionController,
                  style: TextStyle(color: Colors.white),
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Tambahkan keterangan tentang hutang ini...',
                    hintStyle: TextStyle(color: Colors.white54),
                    prefixIcon: Container(
                      margin: EdgeInsets.all(12),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF8B5CF6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.edit_note_outlined,
                        color: Color(0xFF8B5CF6),
                        size: 20,
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  ),
                ),
              ),

              SizedBox(height: 32),

              // Summary card (if amount is entered)
              // Obx(() {
                controller.amountController.text.isNotEmpty ?
                   Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 24),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Color(0xFFF59E0B).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.summarize_outlined,
                              color: Color(0xFFF59E0B),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Ringkasan Hutang',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Jumlah:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Rp ${controller.amountController.text}',
                              style: TextStyle(
                                color: Color(0xFFF59E0B),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (controller.selectedDueDate.value != null) ...[
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Jatuh Tempo:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                controller.formatDate(controller.selectedDueDate.value!),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ):SizedBox.shrink(),
              // }),
              // Save button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton.icon(
                  onPressed: controller.saveDebt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: Icon(Icons.save_outlined, color: Colors.white),
                  label: Text(
                    'Simpan Hutang',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {bool isRequired = false}) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFF4F46E5), size: 20),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (isRequired) ...[
          SizedBox(width: 4),
          Text(
            '*',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        style: TextStyle(color: Colors.white),
        dropdownColor: Color(0xFF374151),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white54),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  String _getDaysUntilDue(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(DateTime(now.year, now.month, now.day)).inDays;

    if (difference < 0) {
      return 'Sudah jatuh tempo ${difference.abs()} hari yang lalu';
    } else if (difference == 0) {
      return 'Jatuh tempo hari ini';
    } else if (difference == 1) {
      return 'Jatuh tempo besok';
    } else {
      return 'Jatuh tempo dalam $difference hari';
    }
  }
}