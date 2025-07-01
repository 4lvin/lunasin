class Debt {
  final int? id;
  final int customerId;
  final String? customerName;
  final double amount;
  final double paidAmount;
  final double remainingAmount;
  final String? dueDate;
  final String? description;
  final String status;
  final String createdAt;

  Debt({
    this.id,
    required this.customerId,
    this.customerName,
    required this.amount,
    this.paidAmount = 0,
    required this.remainingAmount,
    this.dueDate,
    this.description,
    this.status = 'unpaid',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'amount': amount,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'due_date': dueDate,
      'description': description,
      'status': status,
      'created_at': createdAt,
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'],
      customerId: map['customer_id'],
      customerName: map['customer_name'],
      amount: map['amount'].toDouble(),
      paidAmount: map['paid_amount']?.toDouble() ?? 0,
      remainingAmount: map['remaining_amount'].toDouble(),
      dueDate: map['due_date'],
      description: map['description'],
      status: map['status'] ?? 'unpaid',
      createdAt: map['created_at'],
    );
  }
}

class DebtPayment {
  final int? id;
  final int debtId;
  final double amount;
  final String paymentDate;
  final String? notes;

  DebtPayment({
    this.id,
    required this.debtId,
    required this.amount,
    required this.paymentDate,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'debt_id': debtId,
      'amount': amount,
      'payment_date': paymentDate,
      'notes': notes,
    };
  }

  factory DebtPayment.fromMap(Map<String, dynamic> map) {
    return DebtPayment(
      id: map['id'],
      debtId: map['debt_id'],
      amount: map['amount'].toDouble(),
      paymentDate: map['payment_date'],
      notes: map['notes'],
    );
  }
}