import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database.dart';

Router statsRouter() {
  final router = Router();

  router.get('/summary', (Request request) {
    final db = openDatabase();
    try {
      // Robust date comparison: matches both local and UTC as fallback
      final revToday = db.select("""
        SELECT COALESCE(SUM(total),0) as r FROM orders 
        WHERE (date(created_at, 'localtime') = date('now', 'localtime') OR date(created_at) = date('now'))
        AND status != 'pending'
      """);
      
      final revAll = db.select("SELECT COALESCE(SUM(total),0) as r FROM orders WHERE status != 'pending'");
      
      final totToday = db.select("SELECT COUNT(*) as c FROM orders WHERE (date(created_at, 'localtime') = date('now', 'localtime') OR date(created_at) = date('now'))");
      final allTime = db.select("SELECT COUNT(*) as c FROM orders");
      final act = db.select("SELECT COUNT(*) as c FROM orders WHERE status NOT IN ('completed')");
      final pen = db.select("SELECT COUNT(*) as c FROM orders WHERE status='pending'");
      final con = db.select("SELECT COUNT(*) as c FROM orders WHERE status='confirmed'");
      final pre = db.select("SELECT COUNT(*) as c FROM orders WHERE status='preparing'");
      final rdy = db.select("SELECT COUNT(*) as c FROM orders WHERE status='ready'");
      final cmp = db.select("SELECT COUNT(*) as c FROM orders WHERE status='completed' AND (date(created_at, 'localtime') = date('now', 'localtime') OR date(created_at) = date('now'))");
      
      return Response.ok(jsonEncode({
        'revenue_today': revToday.first['r'],
        'revenue_all_time': revAll.first['r'],
        'total_orders_today': totToday.first['c'],
        'total_orders_all_time': allTime.first['c'],
        'active_orders': act.first['c'],
        'pending': pen.first['c'],
        'confirmed': con.first['c'],
        'preparing': pre.first['c'],
        'ready': rdy.first['c'],
        'completed_today': cmp.first['c'],
      }), headers: {'Content-Type': 'application/json'});
    } finally { db.dispose(); }
  });

  router.post('/reset', (Request request) {
    final db = openDatabase();
    try {
      db.execute('DELETE FROM order_items');
      db.execute('DELETE FROM orders');
      db.execute('DELETE FROM reviews');
      return Response.ok(jsonEncode({'success': true, 'message': 'Statistics reset successfully'}), 
        headers: {'Content-Type': 'application/json'});
    } finally { db.dispose(); }
  });

  router.get('/top-items', (Request request) {
    final limit = int.tryParse(request.url.queryParameters['limit'] ?? '10') ?? 10;
    final db = openDatabase();
    try {
      final r = db.select('''
        SELECT oi.menu_item_name as name, oi.menu_item_id,
          SUM(oi.quantity) as total_quantity, SUM(oi.quantity*oi.price) as total_revenue,
          COUNT(DISTINCT oi.order_id) as order_count
        FROM order_items oi JOIN orders o ON oi.order_id=o.id WHERE o.status!='pending'
        GROUP BY oi.menu_item_id, oi.menu_item_name ORDER BY total_quantity DESC LIMIT ?
      ''', [limit]);
      final items = r.map((row) => {'name': row['name'], 'menu_item_id': row['menu_item_id'],
        'total_quantity': row['total_quantity'], 'total_revenue': row['total_revenue'],
        'order_count': row['order_count']}).toList();
      return Response.ok(jsonEncode(items), headers: {'Content-Type': 'application/json'});
    } finally { db.dispose(); }
  });

  router.get('/tables-status', (Request request) {
    final db = openDatabase();
    try {
      // Adjusted to 10 tables as requested
      const int totalTables = 10;
      final occupiedResult = db.select("SELECT DISTINCT table_number FROM orders WHERE status NOT IN ('completed')");
      final occupiedTables = occupiedResult.map((r) => r['table_number'] as int).toList();
      
      List<Map<String, dynamic>> tables = [];
      for (int i = 1; i <= totalTables; i++) {
        tables.add({
          'table_number': i,
          'is_available': !occupiedTables.contains(i),
        });
      }
      return Response.ok(jsonEncode(tables), headers: {'Content-Type': 'application/json'});
    } finally { db.dispose(); }
  });

  return router;
}
