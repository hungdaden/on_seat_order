import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database.dart';

Router menuRouter() {
  final router = Router();

  router.get('/', (Request request) {
    final cat = request.url.queryParameters['category'];
    final db = openDatabase();
    try {
      String q = 'SELECT m.*, c.name as category_name FROM menu_items m JOIN categories c ON m.category_id = c.id';
      List<Object> p = [];
      if (cat != null && cat.isNotEmpty && cat != 'all') { q += ' WHERE m.category_id = ?'; p.add(cat); }
      q += ' ORDER BY c.sort_order, m.sort_order';
      final r = db.select(q, p);
      final items = r.map((row) => {
        'id': row['id'], 'name': row['name'], 'description': row['description'],
        'price': row['price'], 'image_url': row['image_url'], 'category_id': row['category_id'],
        'category_name': row['category_name'], 'is_popular': row['is_popular'] == 1,
        'is_available': row['is_available'] == 1, 'sort_order': row['sort_order'],
      }).toList();
      return Response.ok(jsonEncode(items), headers: {'Content-Type': 'application/json'});
    } finally { db.dispose(); }
  });

  router.get('/categories', (Request request) {
    final db = openDatabase();
    try {
      final r = db.select('SELECT * FROM categories ORDER BY sort_order');
      final cats = r.map((row) => {'id': row['id'], 'name': row['name'], 'sort_order': row['sort_order']}).toList();
      return Response.ok(jsonEncode(cats), headers: {'Content-Type': 'application/json'});
    } finally { db.dispose(); }
  });

  router.post('/', (Request request) async {
    final body = jsonDecode(await request.readAsString());
    final id = generateId();
    final db = openDatabase();
    try {
      db.execute(
        'INSERT INTO menu_items (id,name,description,price,image_url,category_id,is_popular,is_available,sort_order) VALUES (?,?,?,?,?,?,?,?,?)',
        [id, body['name'], body['description'] ?? '', body['price'], body['image_url'] ?? '',
         body['category_id'], (body['is_popular'] == true) ? 1 : 0, (body['is_available'] == false) ? 0 : 1, body['sort_order'] ?? 0]);
      return Response.ok(jsonEncode({'id': id, 'message': 'Created'}), headers: {'Content-Type': 'application/json'});
    } finally { db.dispose(); }
  });

  router.put('/<id>', (Request request, String id) async {
    final body = jsonDecode(await request.readAsString());
    final db = openDatabase();
    try {
      final f = <String>[]; final v = <Object>[];
      void add(String key, String col, [bool? isBool]) {
        if (!body.containsKey(key)) return;
        f.add('$col = ?');
        v.add(isBool == true ? ((body[key] == true) ? 1 : 0) : body[key]);
      }
      add('name', 'name'); add('description', 'description'); add('price', 'price');
      add('image_url', 'image_url'); add('category_id', 'category_id');
      add('is_popular', 'is_popular', true); add('is_available', 'is_available', true);
      add('sort_order', 'sort_order');
      if (f.isEmpty) return Response(400, body: jsonEncode({'error': 'Nothing to update'}), headers: {'Content-Type': 'application/json'});
      v.add(id);
      db.execute('UPDATE menu_items SET ${f.join(', ')} WHERE id = ?', v);
      return Response.ok(jsonEncode({'message': 'Updated'}), headers: {'Content-Type': 'application/json'});
    } finally { db.dispose(); }
  });

  router.delete('/<id>', (Request request, String id) {
    final db = openDatabase();
    try {
      db.execute('DELETE FROM menu_items WHERE id = ?', [id]);
      return Response.ok(jsonEncode({'message': 'Deleted'}), headers: {'Content-Type': 'application/json'});
    } finally { db.dispose(); }
  });

  return router;
}
