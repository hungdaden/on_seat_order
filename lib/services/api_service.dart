import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category.dart';
import '../models/menu_item.dart';
import '../models/order.dart';

class ApiService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // ─── AUTH ──────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String username, String password) async {
    // Map username "admin" → "admin@gmail.com"
    String email = username;
    if (!email.contains('@')) {
      email = '$username@gmail.com';
    }
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return {
      'token': await credential.user?.getIdToken() ?? '',
      'username': username,
    };
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }

  static Future<bool> verifyToken() async {
    return _auth.currentUser != null;
  }

  static bool get isLoggedIn => _auth.currentUser != null;

  // ─── MENU ─────────────────────────────────────────
  static Future<List<Category>> fetchCategories() async {
    final snapshot = await _firestore
        .collection('categories')
        .orderBy('sort_order')
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Category.fromJson(data);
    }).toList();
  }

  static Future<List<MenuItem>> fetchMenu({String? categoryId}) async {
    Query<Map<String, dynamic>> query = _firestore.collection('menu_items');
    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
      query = query.where('category_id', isEqualTo: categoryId);
    }
    query = query.orderBy('sort_order');
    final snapshot = await query.get();

    // Fetch category names for display
    final categories = await fetchCategories();
    final catMap = {for (var c in categories) c.id: c.name};

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      data['category_name'] = catMap[data['category_id']] ?? '';
      return MenuItem.fromJson(data);
    }).toList();
  }

  static Future<void> createMenuItem(Map<String, dynamic> data) async {
    await _firestore.collection('menu_items').add(data);
  }

  static Future<void> updateMenuItem(String id, Map<String, dynamic> data) async {
    await _firestore.collection('menu_items').doc(id).update(data);
  }

  static Future<void> deleteMenuItem(String id) async {
    await _firestore.collection('menu_items').doc(id).delete();
  }

  static Future<void> updateMenuItemAvailability(String id, bool isAvailable) async {
    await _firestore.collection('menu_items').doc(id).update({'is_available': isAvailable});
  }

  // ─── ORDERS ───────────────────────────────────────
  static Future<Map<String, dynamic>> createOrder({
    required int tableNumber,
    required String customerName,
    required List<CartItem> items,
    String note = '',
  }) async {
    int total = 0;
    for (final i in items) {
      total += i.menuItem.price * i.quantity;
    }

    final now = DateTime.now().toIso8601String();
    final orderRef = await _firestore.collection('orders').add({
      'table_number': tableNumber,
      'customer_name': customerName,
      'status': 'pending',
      'total': total,
      'note': note,
      'created_at': now,
      'updated_at': now,
    });

    // Add order items as subcollection
    final batch = _firestore.batch();
    for (final item in items) {
      final itemRef = orderRef.collection('items').doc();
      batch.set(itemRef, {
        'menu_item_id': item.menuItem.id,
        'menu_item_name': item.menuItem.name,
        'quantity': item.quantity,
        'price': item.menuItem.price,
        'note': item.note,
      });
    }
    await batch.commit();

    return {'id': orderRef.id, 'status': 'pending', 'total': total, 'message': 'Order created'};
  }

  static Future<List<Order>> fetchOrders({String? status, bool today = false}) async {
    Query<Map<String, dynamic>> query = _firestore.collection('orders');
    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }
    query = query.orderBy('created_at', descending: true);
    final snapshot = await query.get();

    List<Order> orders = [];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      data['id'] = doc.id;

      // Filter today client-side (Firestore doesn't have date() function like SQLite)
      if (today) {
        final createdAt = DateTime.tryParse(data['created_at'] ?? '');
        if (createdAt != null) {
          final now = DateTime.now();
          if (createdAt.year != now.year || createdAt.month != now.month || createdAt.day != now.day) {
            continue;
          }
        }
      }

      // Fetch subcollection items
      final itemsSnapshot = await _firestore
          .collection('orders')
          .doc(doc.id)
          .collection('items')
          .get();
      data['items'] = itemsSnapshot.docs.map((itemDoc) {
        final itemData = itemDoc.data();
        itemData['id'] = itemDoc.id;
        return itemData;
      }).toList();

      orders.add(Order.fromJson(data));
    }
    return orders;
  }

  static Future<Order> fetchOrder(String id) async {
    final doc = await _firestore.collection('orders').doc(id).get();
    if (!doc.exists) throw Exception('Order not found');
    final data = doc.data()!;
    data['id'] = doc.id;

    // Fetch subcollection items
    final itemsSnapshot = await _firestore
        .collection('orders')
        .doc(id)
        .collection('items')
        .get();
    data['items'] = itemsSnapshot.docs.map((itemDoc) {
      final itemData = itemDoc.data();
      itemData['id'] = itemDoc.id;
      return itemData;
    }).toList();

    return Order.fromJson(data);
  }

  static Future<List<Order>> fetchTableOrders(int tableNumber) async {
    final snapshot = await _firestore
        .collection('orders')
        .where('table_number', isEqualTo: tableNumber)
        .where('status', whereNotIn: ['completed'])
        .orderBy('created_at', descending: true)
        .get();

    List<Order> orders = [];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      data['id'] = doc.id;

      final itemsSnapshot = await _firestore
          .collection('orders')
          .doc(doc.id)
          .collection('items')
          .get();
      data['items'] = itemsSnapshot.docs.map((itemDoc) {
        final itemData = itemDoc.data();
        itemData['id'] = itemDoc.id;
        return itemData;
      }).toList();

      orders.add(Order.fromJson(data));
    }
    return orders;
  }

  static Future<void> updateOrderStatus(String orderId, String status) async {
    final valid = ['pending', 'confirmed', 'preparing', 'ready', 'completed'];
    if (!valid.contains(status)) throw Exception('Invalid status');
    await _firestore.collection('orders').doc(orderId).update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ─── STATS ────────────────────────────────────────
  static Future<Map<String, dynamic>> fetchStats() async {
    final allOrders = await _firestore.collection('orders').get();
    final now = DateTime.now();

    int revenueToday = 0;
    int revenueAllTime = 0;
    int totalOrdersToday = 0;
    int totalOrdersAllTime = allOrders.docs.length;
    int activeOrders = 0;
    int pending = 0;
    int confirmed = 0;
    int preparing = 0;
    int ready = 0;
    int completedToday = 0;

    for (final doc in allOrders.docs) {
      final data = doc.data();
      final status = data['status'] as String? ?? '';
      final total = (data['total'] as num?)?.toInt() ?? 0;
      final createdAt = DateTime.tryParse(data['created_at'] ?? '');
      final isToday = createdAt != null &&
          createdAt.year == now.year &&
          createdAt.month == now.month &&
          createdAt.day == now.day;

      if (status != 'pending') {
        revenueAllTime += total;
        if (isToday) revenueToday += total;
      }
      if (isToday) totalOrdersToday++;
      if (status != 'completed') activeOrders++;
      if (status == 'pending') pending++;
      if (status == 'confirmed') confirmed++;
      if (status == 'preparing') preparing++;
      if (status == 'ready') ready++;
      if (status == 'completed' && isToday) completedToday++;
    }

    return {
      'revenue_today': revenueToday,
      'revenue_all_time': revenueAllTime,
      'total_orders_today': totalOrdersToday,
      'total_orders_all_time': totalOrdersAllTime,
      'active_orders': activeOrders,
      'pending': pending,
      'confirmed': confirmed,
      'preparing': preparing,
      'ready': ready,
      'completed_today': completedToday,
    };
  }

  static Future<void> resetStats() async {
    // Delete all orders and their subcollection items
    final orders = await _firestore.collection('orders').get();
    for (final doc in orders.docs) {
      // Delete subcollection items first
      final items = await doc.reference.collection('items').get();
      for (final item in items.docs) {
        await item.reference.delete();
      }
      await doc.reference.delete();
    }

    // Delete all reviews
    final reviews = await _firestore.collection('reviews').get();
    for (final doc in reviews.docs) {
      await doc.reference.delete();
    }
  }

  static Future<List<Map<String, dynamic>>> fetchTopItems({int limit = 10}) async {
    // Fetch all orders that are not pending
    final ordersSnapshot = await _firestore.collection('orders')
        .where('status', isNotEqualTo: 'pending')
        .get();

    // Aggregate order items
    Map<String, Map<String, dynamic>> itemAgg = {};
    for (final orderDoc in ordersSnapshot.docs) {
      final itemsSnapshot = await orderDoc.reference.collection('items').get();
      for (final itemDoc in itemsSnapshot.docs) {
        final data = itemDoc.data();
        final itemId = data['menu_item_id'] as String? ?? '';
        final name = data['menu_item_name'] as String? ?? '';
        final quantity = (data['quantity'] as num?)?.toInt() ?? 0;
        final price = (data['price'] as num?)?.toInt() ?? 0;

        if (itemAgg.containsKey(itemId)) {
          itemAgg[itemId]!['total_quantity'] += quantity;
          itemAgg[itemId]!['total_revenue'] += quantity * price;
          (itemAgg[itemId]!['order_ids'] as Set).add(orderDoc.id);
        } else {
          itemAgg[itemId] = {
            'name': name,
            'menu_item_id': itemId,
            'total_quantity': quantity,
            'total_revenue': quantity * price,
            'order_ids': {orderDoc.id},
          };
        }
      }
    }

    // Convert to list and sort
    final result = itemAgg.values.map((item) {
      return {
        'name': item['name'],
        'menu_item_id': item['menu_item_id'],
        'total_quantity': item['total_quantity'],
        'total_revenue': item['total_revenue'],
        'order_count': (item['order_ids'] as Set).length,
      };
    }).toList();

    result.sort((a, b) => (b['total_quantity'] as int).compareTo(a['total_quantity'] as int));
    return result.take(limit).toList();
  }

  static Future<List<Map<String, dynamic>>> fetchTableStatuses() async {
    const int totalTables = 10;
    final occupiedSnapshot = await _firestore.collection('orders')
        .where('status', whereNotIn: ['completed'])
        .get();

    final occupiedTables = occupiedSnapshot.docs
        .map((doc) => (doc.data()['table_number'] as num?)?.toInt() ?? 0)
        .toSet();

    List<Map<String, dynamic>> tables = [];
    for (int i = 1; i <= totalTables; i++) {
      tables.add({
        'table_number': i,
        'is_available': !occupiedTables.contains(i),
      });
    }
    return tables;
  }

  // ─── REVIEWS ──────────────────────────────────────
  static Future<void> submitReview({
    String? orderId,
    required int tableNumber,
    required int rating,
    String comment = '',
  }) async {
    await _firestore.collection('reviews').add({
      'order_id': orderId,
      'table_number': tableNumber,
      'rating': rating,
      'comment': comment,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
