import '../config/api_client.dart';
import '../models/category.dart';
import '../models/menu_item.dart';
import '../models/order.dart';

class ApiService {
  // ─── AUTH ──────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final result = await ApiClient.post('/api/auth/login', {
      'username': username,
      'password': password,
    });
    ApiClient.setToken(result['token']);
    return result;
  }

  static Future<void> logout() async {
    try {
      await ApiClient.post('/api/auth/logout', {});
    } catch (_) {}
    ApiClient.setToken(null);
  }

  static Future<bool> verifyToken() async {
    try {
      final result = await ApiClient.get('/api/auth/verify');
      return result['valid'] == true;
    } catch (_) {
      return false;
    }
  }

  // ─── MENU ─────────────────────────────────────────
  static Future<List<Category>> fetchCategories() async {
    final result = await ApiClient.get('/api/menu/categories');
    return (result as List).map((e) => Category.fromJson(e)).toList();
  }

  static Future<List<MenuItem>> fetchMenu({String? categoryId}) async {
    String path = '/api/menu/';
    if (categoryId != null && categoryId != 'all') {
      path += '?category=$categoryId';
    }
    final result = await ApiClient.get(path);
    return (result as List).map((e) => MenuItem.fromJson(e)).toList();
  }

  static Future<void> createMenuItem(Map<String, dynamic> data) async {
    await ApiClient.post('/api/menu/', data);
  }

  static Future<void> updateMenuItem(String id, Map<String, dynamic> data) async {
    await ApiClient.put('/api/menu/$id', data);
  }

  static Future<void> deleteMenuItem(String id) async {
    await ApiClient.delete('/api/menu/$id');
  }

  // ─── ORDERS ───────────────────────────────────────
  static Future<Map<String, dynamic>> createOrder({
    required int tableNumber,
    required String customerName,
    required List<CartItem> items,
    String note = '',
  }) async {
    return await ApiClient.post('/api/orders/', {
      'table_number': tableNumber,
      'customer_name': customerName,
      'note': note,
      'items': items.map((e) => e.toOrderJson()).toList(),
    });
  }

  static Future<List<Order>> fetchOrders({String? status, bool today = false}) async {
    String path = '/api/orders/?';
    if (status != null) path += 'status=$status&';
    if (today) path += 'today=true&';
    final result = await ApiClient.get(path);
    return (result as List).map((e) => Order.fromJson(e)).toList();
  }

  static Future<Order> fetchOrder(String id) async {
    final result = await ApiClient.get('/api/orders/$id');
    return Order.fromJson(result);
  }

  static Future<List<Order>> fetchTableOrders(int tableNumber) async {
    final result = await ApiClient.get('/api/orders/table/$tableNumber');
    return (result as List).map((e) => Order.fromJson(e)).toList();
  }

  static Future<void> updateOrderStatus(String orderId, String status) async {
    await ApiClient.put('/api/orders/$orderId/status', {'status': status});
  }

  // ─── STATS ────────────────────────────────────────
  static Future<Map<String, dynamic>> fetchStats() async {
    return await ApiClient.get('/api/stats/summary');
  }

  static Future<void> resetStats() async {
    await ApiClient.post('/api/stats/reset', {});
  }

  static Future<List<Map<String, dynamic>>> fetchTopItems({int limit = 10}) async {
    final result = await ApiClient.get('/api/stats/top-items?limit=$limit');
    return (result as List).cast<Map<String, dynamic>>();
  }

  // ─── REVIEWS ──────────────────────────────────────
  static Future<void> submitReview({
    String? orderId,
    required int tableNumber,
    required int rating,
    String comment = '',
  }) async {
    await ApiClient.post('/api/reviews/', {
      'order_id': orderId,
      'table_number': tableNumber,
      'rating': rating,
      'comment': comment,
    });
  }
}
