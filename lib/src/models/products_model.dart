class Product {
  final int? id;
  final String name;
  final double price;
  final int stock;
  final String createdAt;

  Product({
    this.id,
    required this.name,
    required this.price,
    this.stock = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'created_at': createdAt,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      price: map['price'].toDouble(),
      stock: map['stock'],
      createdAt: map['created_at'],
    );
  }
}
