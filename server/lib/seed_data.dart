import 'database.dart';

void seedData() {
  final db = openDatabase();
  try {
    final existing = db.select('SELECT COUNT(*) as cnt FROM categories');
    if ((existing.first['cnt'] as int) > 0) {
      print('  📦 Data already exists, skipping seed.');
      return;
    }

    print('  🌱 Seeding sample data...');

    final cats = [
      ['cat-pho', 'Phở', 1], ['cat-bun', 'Bún', 2], ['cat-com', 'Cơm', 3],
      ['cat-banhmi', 'Bánh Mì', 4], ['cat-khaivi', 'Khai Vị', 5], ['cat-douong', 'Đồ Uống', 6],
    ];
    for (final c in cats) {
      db.execute('INSERT INTO categories (id, name, sort_order) VALUES (?, ?, ?)', c);
    }

    final items = [
      [generateId(), 'Phở Bò Tái', 'Phở bò tái truyền thống với nước dùng đậm đà', 75000,
       'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=400&h=300&fit=crop', 'cat-pho', 1, 1],
      [generateId(), 'Phở Gà', 'Phở gà ta thả vườn, thịt gà ngọt tự nhiên', 65000,
       'https://images.unsplash.com/photo-1576577445504-6af96477db52?w=400&h=300&fit=crop', 'cat-pho', 1, 2],
      [generateId(), 'Phở Bò Viên', 'Phở bò viên dai giòn, nước dùng thanh ngọt', 70000,
       'https://images.unsplash.com/photo-1555126634-323283e090fa?w=400&h=300&fit=crop', 'cat-pho', 0, 3],
      [generateId(), 'Phở Đặc Biệt', 'Phở bò đặc biệt: tái, nạm, gầu, gân, sách', 95000,
       'https://images.unsplash.com/photo-1617093727343-374698b1b08d?w=400&h=300&fit=crop', 'cat-pho', 1, 4],
      [generateId(), 'Bún Bò Huế', 'Bún bò Huế cay nồng, giò heo, huyết, chả cua', 70000,
       'https://images.unsplash.com/photo-1569058242253-92a9c755a0ec?w=400&h=300&fit=crop', 'cat-bun', 1, 1],
      [generateId(), 'Bún Riêu Cua', 'Bún riêu cua đồng, cà chua, đậu hũ chiên', 68000,
       'https://images.unsplash.com/photo-1583224994076-0a3e5dfa49e4?w=400&h=300&fit=crop', 'cat-bun', 0, 2],
      [generateId(), 'Bún Chả Hà Nội', 'Bún chả nướng than hoa kiểu Hà Nội', 72000,
       'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?w=400&h=300&fit=crop', 'cat-bun', 1, 3],
      [generateId(), 'Cơm Tấm Sườn Bì Chả', 'Cơm tấm sườn nướng, bì, chả trứng', 65000,
       'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=400&h=300&fit=crop', 'cat-com', 1, 1],
      [generateId(), 'Cơm Chiên Dương Châu', 'Cơm chiên tôm, lạp xưởng, trứng', 60000,
       'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=400&h=300&fit=crop', 'cat-com', 0, 2],
      [generateId(), 'Bánh Mì Thịt Nướng', 'Bánh mì giòn kẹp thịt nướng, rau, đồ chua', 35000,
       'https://images.unsplash.com/photo-1600688640154-9619e002df30?w=400&h=300&fit=crop', 'cat-banhmi', 1, 1],
      [generateId(), 'Bánh Mì Ốp La', 'Bánh mì giòn, trứng ốp la, pate, xíu mại', 30000,
       'https://images.unsplash.com/photo-1509722747041-616f39b57569?w=400&h=300&fit=crop', 'cat-banhmi', 0, 2],
      [generateId(), 'Gỏi Cuốn Tôm Thịt', 'Gỏi cuốn tươi mát kèm nước chấm đậu phộng', 45000,
       'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=400&h=300&fit=crop', 'cat-khaivi', 1, 1],
      [generateId(), 'Chả Giò Chiên', 'Chả giò chiên giòn nhân thịt, miến, mộc nhĩ', 50000,
       'https://images.unsplash.com/photo-1544025162-d76694265947?w=400&h=300&fit=crop', 'cat-khaivi', 0, 2],
      [generateId(), 'Trà Đá', 'Trà đá truyền thống', 5000,
       'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400&h=300&fit=crop', 'cat-douong', 1, 1],
      [generateId(), 'Cà Phê Sữa Đá', 'Cà phê phin truyền thống kèm sữa đặc', 29000,
       'https://images.unsplash.com/photo-1514432324607-a09d9b4aefda?w=400&h=300&fit=crop', 'cat-douong', 1, 2],
      [generateId(), 'Nước Chanh Tươi', 'Nước chanh vắt, đường hoặc muối', 20000,
       'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=400&h=300&fit=crop', 'cat-douong', 0, 3],
      [generateId(), 'Sinh Tố Bơ', 'Sinh tố bơ béo ngậy, sữa đặc', 35000,
       'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=400&h=300&fit=crop', 'cat-douong', 0, 4],
    ];

    for (final m in items) {
      db.execute(
        'INSERT INTO menu_items (id,name,description,price,image_url,category_id,is_popular,sort_order) VALUES (?,?,?,?,?,?,?,?)',
        m,
      );
    }
    print('  ✅ Seeded ${cats.length} categories, ${items.length} menu items.');
  } finally {
    db.dispose();
  }
}
