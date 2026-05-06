class Order {
  final String id;
  final int tableNumber;
  final String customerName;
  final String status;
  final int total;
  final String note;
  final String createdAt;
  final String updatedAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.tableNumber,
    this.customerName = 'Khách',
    this.status = 'pending',
    this.total = 0,
    this.note = '',
    this.createdAt = '',
    this.updatedAt = '',
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      tableNumber: json['table_number'] as int,
      customerName: json['customer_name'] as String? ?? 'Khách',
      status: json['status'] as String? ?? 'pending',
      total: json['total'] as int? ?? 0,
      note: json['note'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      items: (json['items'] as List?)
          ?.map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class OrderItem {
  final String id;
  final String menuItemId;
  final String menuItemName;
  final int quantity;
  final int price;
  final String note;

  OrderItem({
    required this.id,
    required this.menuItemId,
    required this.menuItemName,
    this.quantity = 1,
    required this.price,
    this.note = '',
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String? ?? '',
      menuItemId: json['menu_item_id'] as String,
      menuItemName: json['menu_item_name'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      price: json['price'] as int,
      note: json['note'] as String? ?? '',
    );
  }
}
