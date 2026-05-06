import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:path/path.dart' as p;

import '../lib/database.dart';
import '../lib/seed_data.dart';
import '../lib/routes/auth_routes.dart';
import '../lib/routes/menu_routes.dart';
import '../lib/routes/order_routes.dart';
import '../lib/routes/stats_routes.dart';
import '../lib/routes/review_routes.dart';

void main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;

  // Database
  final dbPath = p.join(Directory.current.path, 'server', 'onseat_order.db');
  initializeDatabase(dbPath);
  seedData();

  // API router
  final api = Router();
  api.mount('/api/auth/', authRouter().call);
  api.mount('/api/menu/', menuRouter().call);
  api.mount('/api/orders/', orderRouter().call);
  api.mount('/api/reviews/', reviewRouter().call);

  final protectedStats = Pipeline()
      .addMiddleware(requireAuth())
      .addHandler(statsRouter().call);
  api.mount('/api/stats/', protectedStats);

  // Static file handler
  Handler? staticHandler;
  final webPath = p.join(Directory.current.path, 'build', 'web');
  if (Directory(webPath).existsSync()) {
    staticHandler = createStaticHandler(webPath, defaultDocument: 'index.html');
  }

  // CORS
  Middleware cors() => (Handler h) => (Request req) async {
    const headers = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
    };
    if (req.method == 'OPTIONS') return Response.ok('', headers: headers);
    final resp = await h(req);
    return resp.change(headers: headers);
  };

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(cors())
      .addHandler((Request req) async {
        if (req.url.path.startsWith('api/')) return await api.call(req);
        if (staticHandler != null) {
          try {
            final r = await staticHandler!(req);
            if (r.statusCode != 404) return r;
          } catch (_) {}
          return await staticHandler!(Request('GET', Uri.parse('http://localhost/index.html'), headers: req.headers));
        }
        return Response.notFound('Not found');
      });

  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  print('');
  print('🍜 Phở Cẩm Phả — OnSeat Order Server');
  print('🚀 http://localhost:${server.port}');
  print('📱 QR: http://localhost:${server.port}/order?table=N');
  print('🔐 Admin: http://localhost:${server.port}/admin');
  print('   Login: admin / pho2025');
  print('');
}
