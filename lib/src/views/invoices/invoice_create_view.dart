import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/invoice_create_controller.dart';
import '../../models/customer_model.dart';
import '../../models/products_model.dart';

class InvoiceCreateView extends GetView<InvoiceCreateController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1B3A), // Dark blue background
      appBar: AppBar(
        title: Text(
          'Buat Invoice',
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
              // Customer selection
              _buildSectionHeader(
                'Informasi Pelanggan',
                Icons.person_outline,
              ),
              SizedBox(height: 12),
              _buildDropdownField<Customer>(
                value: controller.selectedCustomer.value,
                hint: 'Pilih Pelanggan (Opsional)',
                items: controller.customers.map((customer) {
                  return DropdownMenuItem(
                    value: customer,
                    child: Text(
                      customer.name,
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (customer) {
                  controller.selectedCustomer.value = customer;
                },
              ),

              SizedBox(height: 24),

              // Product selection
              _buildSectionHeader(
                'Tambah Produk',
                Icons.shopping_cart_outlined,
              ),
              SizedBox(height: 12),

              // Product selection row
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildDropdownField<Product>(
                            value: controller.selectedProduct.value,
                            hint: 'Pilih Produk',
                            items: controller.products.map((product) {
                              return DropdownMenuItem(
                                value: product,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      product.name,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    Text(
                                      controller.formatCurrency(product.price),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (product) {
                              controller.selectedProduct.value = product;
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: controller.quantityController,
                            hint: 'Qty',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: controller.addProductToInvoice,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(Icons.add, color: Colors.white),
                          label: Text(
                            'Tambah ke Invoice',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Invoice items
              if (controller.invoiceItems.isNotEmpty) ...[
                _buildSectionHeader(
                  'Item Invoice (${controller.invoiceItems.length})',
                  Icons.receipt_outlined,
                ),
                SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: controller.invoiceItems.asMap().entries.map((entry) {
                      int index = entry.key;
                      var item = entry.value;

                      return Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: index > 0
                              ? Border(top: BorderSide(color: Colors.white.withOpacity(0.1)))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Color(0xFF3B82F6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.inventory_2_outlined,
                                color: Color(0xFF3B82F6),
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${item.quantity} x ${controller.formatCurrency(item.price)}',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  controller.formatCurrency(item.total),
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                InkWell(
                                  onTap: () => controller.removeProductFromInvoice(index),
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFEF4444).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.delete_outline,
                                      color: Color(0xFFEF4444),
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                SizedBox(height: 24),

                // Discount and tax
                _buildSectionHeader(
                  'Penyesuaian',
                  Icons.tune_outlined,
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: controller.discountController,
                        label: 'Diskon',
                        prefix: 'Rp ',
                        keyboardType: TextInputType.number,
                        onChanged: (value) => controller.calculateTotal(),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: controller.taxController,
                        label: 'Pajak',
                        prefix: 'Rp ',
                        keyboardType: TextInputType.number,
                        onChanged: (value) => controller.calculateTotal(),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Total calculation
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF1F2937),
                        Color(0xFF374151),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Color(0xFF4F46E5).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildTotalRow(
                        'Subtotal',
                        controller.formatCurrency(controller.subtotal.value),
                        isSubtotal: true,
                      ),
                      if (controller.discount.value > 0) ...[
                        SizedBox(height: 8),
                        _buildTotalRow(
                          'Diskon',
                          '-${controller.formatCurrency(controller.discount.value)}',
                          color: Color(0xFFEF4444),
                        ),
                      ],
                      if (controller.tax.value > 0) ...[
                        SizedBox(height: 8),
                        _buildTotalRow(
                          'Pajak',
                          '+${controller.formatCurrency(controller.tax.value)}',
                          color: Color(0xFFF59E0B),
                        ),
                      ],
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(
                          color: Colors.white.withOpacity(0.1),
                          thickness: 1,
                        ),
                      ),
                      _buildTotalRow(
                        'Total',
                        controller.formatCurrency(controller.total.value),
                        isTotal: true,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Save button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: controller.saveInvoice,
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
                      'Simpan Invoice',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Empty state
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Color(0xFF1F2937),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.receipt_outlined,
                          size: 40,
                          color: Colors.white54,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Belum ada item',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tambahkan produk untuk memulai invoice',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        style: TextStyle(color: Colors.white),
        dropdownColor: Color(0xFF374151),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white54),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? label,
    String? hint,
    String? prefix,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF374151),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: Colors.white),
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: Colors.white54),
          hintStyle: TextStyle(color: Colors.white54),
          prefixText: prefix,
          prefixStyle: TextStyle(color: Colors.white54),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildTotalRow(
      String label,
      String value, {
        Color? color,
        bool isSubtotal = false,
        bool isTotal = false,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? Colors.white : Colors.white70,
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal
                ? Color(0xFF10B981)
                : color ?? (isSubtotal ? Colors.white : Colors.white70),
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}