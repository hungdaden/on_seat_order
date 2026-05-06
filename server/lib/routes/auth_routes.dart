import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database.dart';

Router authRouter() {
  final router = Router();

  router.post('/login', (Request request) async {
    final body = jsonDecode(await request.readAsString());
    final username = body['username'] as String? ?? '';
    final password = body['password'] as String? ?? '';
    if (username.isEmpty || password.isEmpty) {
      return _json(400, {'error': 'Username and password required'});
    }
    final db = openDatabase();
    try {
      final hash = hashPassword(password);
      final results = db.select(
        'SELECT id, username FROM admin_users WHERE username = ? AND password_hash = ?',
        [username, hash]);
      if (results.isEmpty) return _json(401, {'error': 'Invalid credentials'});
      final userId = results.first['id'] as String;
      final token = generateId();
      final expiresAt = DateTime.now().add(Duration(hours: 24)).toIso8601String();
      db.execute('DELETE FROM sessions WHERE user_id = ?', [userId]);
      db.execute('INSERT INTO sessions (token, user_id, expires_at) VALUES (?, ?, ?)', [token, userId, expiresAt]);
      return _json(200, {'token': token, 'username': results.first['username'], 'expires_at': expiresAt});
    } finally { db.dispose(); }
  });

  router.post('/logout', (Request request) async {
    final token = extractToken(request);
    if (token != null) {
      final db = openDatabase();
      try { db.execute('DELETE FROM sessions WHERE token = ?', [token]); }
      finally { db.dispose(); }
    }
    return _json(200, {'message': 'Logged out'});
  });

  router.get('/verify', (Request request) {
    final token = extractToken(request);
    if (token == null) return _json(401, {'valid': false});
    final db = openDatabase();
    try {
      final results = db.select(
        "SELECT s.token, a.username FROM sessions s JOIN admin_users a ON s.user_id = a.id WHERE s.token = ? AND s.expires_at > datetime('now')",
        [token]);
      if (results.isEmpty) return _json(401, {'valid': false});
      return _json(200, {'valid': true, 'username': results.first['username']});
    } finally { db.dispose(); }
  });

  return router;
}

String? extractToken(Request request) {
  final auth = request.headers['authorization'];
  if (auth != null && auth.startsWith('Bearer ')) return auth.substring(7);
  return null;
}

bool isValidToken(String? token) {
  if (token == null) return false;
  final db = openDatabase();
  try {
    final results = db.select(
      "SELECT token FROM sessions WHERE token = ? AND expires_at > datetime('now')", [token]);
    return results.isNotEmpty;
  } finally { db.dispose(); }
}

Middleware requireAuth() {
  return (Handler innerHandler) {
    return (Request request) {
      final token = extractToken(request);
      if (!isValidToken(token)) return _json(401, {'error': 'Unauthorized'});
      return innerHandler(request);
    };
  };
}

Response _json(int status, Map<String, dynamic> body) {
  return Response(status, body: jsonEncode(body), headers: {'Content-Type': 'application/json'});
}
