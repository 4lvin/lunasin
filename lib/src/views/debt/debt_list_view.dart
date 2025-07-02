import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/debt_list_controller.dart';

class DebtListView extends GetView<DebtListController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1B3A), // Dark blue background
      appBar: AppBar(
        title: Text(
          'Daftar Hutang',
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
            icon: Icon(Icons.search, color: Colors.white54),
            onPressed: () {
              // Show search functionality
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white54),
            onPressed: () {
              // Show more options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Header
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Obx(() {
              final totalDebts = controller.filteredDebts.length;
              final totalAmount = controller.filteredDebts.fold(
                0.0,
                    (sum, debt) => sum + debt.remainingAmount,
              );

              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Hutang',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '$totalDebts',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sisa Hutang',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          controller.formatCurrency(totalAmount),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),

          // Filter tabs
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Obx(() => _buildFilterChip(
                    'Semua',
                    controller.selectedStatus.value == 'all',
                        () => controller.changeFilter('all'),
                    Icons.list_alt_outlined,
                  )),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Obx(() => _buildFilterChip(
                    'Belum Lunas',
                    controller.selectedStatus.value == 'unpaid',
                        () => controller.changeFilter('unpaid'),
                    Icons.schedule_outlined,
                  )),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Obx(() => _buildFilterChip(
                    'Lunas',
                    controller.selectedStatus.value == 'paid',
                        () => controller.changeFilter('paid'),
                    Icons.check_circle_outline,
                  )),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Debts list
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                  ),
                );
              }

              if (controller.filteredDebts.isEmpty) {
                return RefreshIndicator(
                  onRefresh: controller.loadDebts,
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Color(0xFF1F2937),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.assignment_outlined,
                                size: 40,
                                color: Colors.white54,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Belum ada hutang',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Hutang yang dicatat akan muncul di sini',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.loadDebts,
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: controller.filteredDebts.length,
                  itemBuilder: (context, index) {
                    final debt = controller.filteredDebts[index];
                    final isOverdue = controller.isOverdue(debt);

                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Color(0xFF1F2937),
                        borderRadius: BorderRadius.circular(16),
                        border: isOverdue
                            ? Border.all(color: Color(0xFFEF4444).withOpacity(0.3))
                            : null,
                      ),
                      child: InkWell(
                        onTap: () => controller.showDebtDetail(debt),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Status indicator
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: controller.getStatusColor(debt.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  debt.status == 'paid'
                                      ? Icons.check_circle_outline
                                      : Icons.schedule_outlined,
                                  color: controller.getStatusColor(debt.status),
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 16),

                              // Debt info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          debt.customerName ?? 'Unknown',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: controller.getStatusColor(debt.status).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            controller.getStatusText(debt.status),
                                            style: TextStyle(
                                              color: controller.getStatusColor(debt.status),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),

                                    // Amount info
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.monetization_on_outlined,
                                          size: 14,
                                          color: Colors.white54,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Total: ${controller.formatCurrency(debt.amount)}',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.payment_outlined,
                                              size: 14,
                                              color: Colors.white54,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Sisa: ${controller.formatCurrency(debt.remainingAmount)}',
                                              style: TextStyle(
                                                color: Color(0xFFF59E0B),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            if (debt.status == 'unpaid')
                                              InkWell(
                                                onTap: () => controller.showPaymentDialog(debt),
                                                child: Container(
                                                  padding: EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Color(0xFF10B981).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(
                                                    Icons.payment_outlined,
                                                    color: Color(0xFF10B981),
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                            SizedBox(width: 8),
                                            InkWell(
                                              onTap: () => controller.printDebtReceipt(debt),
                                              child: Container(
                                                padding: EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFF4F46E5).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.print_outlined,
                                                  color: Color(0xFF4F46E5),
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    if (debt.dueDate != null) ...[
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            isOverdue
                                                ? Icons.warning_outlined
                                                : Icons.event_outlined,
                                            size: 14,
                                            color: isOverdue
                                                ? Color(0xFFEF4444)
                                                : Colors.white54,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Jatuh tempo: ${controller.formatDate(debt.dueDate!)}',
                                            style: TextStyle(
                                              color: isOverdue
                                                  ? Color(0xFFEF4444)
                                                  : Colors.white54,
                                              fontSize: 12,
                                              fontWeight: isOverdue
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          if (isOverdue) ...[
                                            SizedBox(width: 8),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Color(0xFFEF4444).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'TERLAMBAT',
                                                style: TextStyle(
                                                  color: Color(0xFFEF4444),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            // Navigate to create debt
            Get.toNamed('/debt-create');
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: Icon(Icons.add, color: Colors.white),
          label: Text(
            'Catat Hutang',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, IconData icon) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF4F46E5) : Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Color(0xFF4F46E5)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.white54,
            ),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}