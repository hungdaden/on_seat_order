class MenuItem {
  final String id;
  final String name;
  final String description;
  final int price;
  final String imageUrl;
  final String categoryId;
  final String categoryName;
  final bool isPopular;
  final bool isAvailable;
  final int sortOrder;

  MenuItem({
    required this.id,
    required this.name,
    this.description = '',
    required this.price,
    this.imageUrl = '',
    required this.categoryId,
    this.categoryName = '',
    this.isPopular = false,
    this.isAvailable = true,
    this.sortOrder = 0,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: json['price'] as int,
      imageUrl: json['image_url'] as String? ?? '',
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String? ?? '',
      isPopular: json['is_popular'] == true || json['is_popular'] == 1,
      isAvailable: json['is_available'] == true || json['is_available'] == 1,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'price': price,
    'image_url': imageUrl,
    'category_id': categoryId,
    'is_popular': isPopular,
    'is_available': isAvailable,
    'sort_order': sortOrder,
  };
}

class CartItem {
  final MenuItem menuItem;
  int quantity;
  String note;

  CartItem({required this.menuItem, this.quantity = 1, this.note = ''});

  int get subtotal => menuItem.price * quantity;

  Map<String, dynamic> toOrderJson() => {
    'menu_item_id': menuItem.id,
    'menu_item_name': menuItem.name,
    'quantity': quantity,
    'price': menuItem.price,
    'note': note,
  };
}
