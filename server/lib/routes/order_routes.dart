import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database.dart';

Router orderRouter() {
  final router = Router();

  router.post('/', (Request request) async {
    final body = jsonDecode(await request.readAsString());
    final db = openDatabase();
    try {
      final orderId = generateId();
      final items = body['items'] as List;
      int total = 0;
      for (final i in items) total += ((i['price'] as num) * (i['quantity'] as num)).toInt();
      db.execute('INSERT INTO orders (id,table_number,customer_name,status,total,note) VALUES (?,?,?,\'pending\',?,?)',
        [orderId, body['table_number'], body['customer_name'] ?? 'Khách', total, body['note'] ?? '']);
      for (final i in items) {
        db.execute('INSERT INTO order_items (id,order_id,menu_item_id,menu_item_name,quantity,price,note) VALUES (?,?,?,?,?,?,?)',
          [generateId(), orderId, i['menu_item_id'], i['menu_item_name'] ?? '', i['quantity'], i['price'], i['note'] ?? '']);
      }
      return Response.ok(jsonEncode({'id': orderId, 'status': 'pending', 'total': total, 'message': 'Order created'}),
        headers: {'Content-Type': 'application/json'});
    } finally { db.dispose(); }
  });

  router.get('/', (Request request) {
    final db = openDatabase();
    try {
      final status = request.url.queryParameters['status'];
      final today = request.url.queryParameters['today'];
      String q = 'SELECT * FROM orders';
      List<Object> p = [];
      List<String> conds = [];
      if (status != null && status.isNotEmpty) { conds.add('status = ?'); p.add(status); }
      if (today == 'true') conds.add("date(created_at) = date('now','localtime')");
      if (conds.isNotEmpty) q += ' WHERE ${conds.join(' AND ')}';
      q += ' ORDER BY created_at DESC';
      final orders = db.select(q, p);
      final result = orders.map((o) {
        final items = db.select('SELECT * FROM order_items WHERE order_id = ?', [o['id']]);
        return {
          'id': o['id'], 'table_number': o['table_number'], 'customer_name': o['customer_name'],
          'status': o['status'], 'total': o['total'], 'note': o['note'],
          'created_at': o['created_at'], 'updated_at': o['updated_at'],
          'items': items.map((i) => {'id': i['id'], 'menu_item_id': i['menu_item_id'],
            'menu_item_name': i['menu_item_name'], 'quantity': i['quantity'],
            'price': i['price'], 'note': i['note']}).toList(),
        };
      }).toList();
      return Response.ok(jsonEncode(result), headers: {'Content-Type': 'application/json'});
    } finally { db.dispose(); }
  });

  router.get('/<id>', (Request request, String id) {
    if (id == 'table') return Response.notFound(''); // handled below
    final db = openDatabase();
    try {
      final orders = db.select('SELECT * FROM orders WHERE id = ?', [id]);
      if (orders.isEmpty) return Response.notFound(jsonEncode({'error': 'Not found'}));
      final o = orders.first;
      final items = db.select('SELECT * FROM order_items WHERE order_id = ?', [id]);
      return Response.ok(jsonEncode({
        'id': o['id'], 'table_number': o['table_number'], 'customer_name': o['customer_name'],
        'status': o['status'], 'total': o['total'], 'note': o['note'],
        'created_at': o['created_at'], 'updated_at': o['updated_at'],
        'items': items.map((i) => {'id': i['id'], 'menu_item_id': i['menu_item_id'],
          'menu_item_name': i['menu_item_name'], 'quantity': i['quantity'],
          'price': i['price'], 'note': i['note']}).toList(),
      }), headers: {'Content-Type': 'application/json'});
    } finally { db.dispose(); }
  });

  router.get('/table/<tableNumber>', (Request request, String tableNumber) {
    final db = openDatabase();
    try {
      final orders = db.select(
        "SELECT * FROM orders WHERE table_number = ? AND status != 'completed' ORDER BY created_at DESC",
        [int.parse(tableNumber)]);
      final result = orders.map((o) {
        final items = db.select('SELECT * FROM order_items WHERE order_id = ?', [o['id']]);
        return {
          'id': o['id'], 'table_number': o['table_number'], 'customer_name': o['customer_name'],
          'status': o['status'], 'total': o['total'], 'note': o['note'],
          'created_at': o['created_at'], 'updated_at': o['updated_at'],
          'items': items.map((i) => {'id': i['id'], 'menu_item_id': i['menu_item_id'],
            'menu_item_name': i['menu_item_name'], 'quantity': i['quantity'],
            'price': i['price'], 'note': i['note']}).toList(),
        };
      }).toList();
      return Response.ok(jsonEncode(result), headers: {'Content-Type': 'application/json'});
    } finally { db.dispose(); }
  });

  router.put('/<id>/status', (Request request, String id) async {
    final body = jsonDecode(await request.readAsString());
    final status = body['status'] as String;
    final valid = ['pending', 'confirmed', 'preparing', 'ready', 'completed'];
    if (!valid.contains(status)) {
      return Response(400, body: jsonEncode({'error': 'Invalid status'}), headers: {'Content-Type': 'application/json'});
    }
    final db = openDatabase();
    try {
      db.execute("UPDATE orders SET status = ?, updated_at = datetime('now') WHERE id = ?", [status, id]);
      return Response.ok(jsonEncode({'message': 'Status updated to $status'}), headers: {'Content-Type': 'application/json'});
    } finally { db.dispose(); }
  });

  return router;
}
