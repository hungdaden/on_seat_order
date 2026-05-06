import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database.dart';

Router reviewRouter() {
  final router = Router();

  router.post('/', (Request request) async {
    final body = jsonDecode(await request.readAsString());
    final id = generateId();
    final db = openDatabase();
    try {
      db.execute('INSERT INTO reviews (id,order_id,table_number,rating,comment) VALUES (?,?,?,?,?)',
        [id, body['order_id'], body['table_number'] ?? 0, body['rating'], body['comment'] ?? '']);
      return Response.ok(jsonEncode({'id': id, 'message': 'Review submitted'}),
        headers: {'Content-Type': 'application/json'});
    } finally { db.dispose(); }
  });

  router.get('/', (Request request) {
    final db = openDatabase();
    try {
      final r = db.select('SELECT * FROM reviews ORDER BY created_at DESC LIMIT 50');
      final reviews = r.map((row) => {'id': row['id'], 'order_id': row['order_id'],
        'table_number': row['table_number'], 'rating': row['rating'],
        'comment': row['comment'], 'created_at': row['created_at']}).toList();
      return Response.ok(jsonEncode(reviews), headers: {'Content-Type': 'application/json'});
    } finally { db.dispose(); }
  });

  return router;
}
