class Invoice {
  final int? id;
  final String invoiceNumber;
  final int? customerId;
  final String? customerName;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String createdAt;
  final List<InvoiceItem> items;

  Invoice({
    this.id,
    required this.invoiceNumber,
    this.customerId,
    this.customerName,
    required this.subtotal,
    this.discount = 0,
    this.tax = 0,
    required this.total,
    required this.createdAt,
    this.items = const [],
  });

  Invoice copyWith({
    int? id,
    String? invoiceNumber,
    int? customerId,
    String? customerName,
    double? subtotal,
    double? discount,
    double? tax,
    double? total,
    String? createdAt,
    List<InvoiceItem>? items,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'customer_id': customerId,
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'total': total,
      'created_at': createdAt,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      invoiceNumber: map['invoice_number'],
      customerId: map['customer_id'],
      customerName: map['customer_name'],
      subtotal: map['subtotal'].toDouble(),
      discount: map['discount']?.toDouble() ?? 0,
      tax: map['tax']?.toDouble() ?? 0,
      total: map['total'].toDouble(),
      createdAt: map['created_at'],
    );
  }
}

class InvoiceItem {
  final int? id;
  final int invoiceId;
  final int productId;
  final String productName;
  final double price;
  final int quantity;
  final double total;

  InvoiceItem({
    this.id,
    required this.invoiceId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
      'total': total,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'],
      invoiceId: map['invoice_id'],
      productId: map['product_id'],
      productName: map['product_name'],
      price: map['price'].toDouble(),
      quantity: map['quantity'],
      total: map['total'].toDouble(),
    );
  }
}