import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';

/// Trang seed dữ liệu lên Firestore.
/// Truy cập tại /admin/seed (tạm thời, xóa sau khi seed xong)
class SeedDataScreen extends StatefulWidget {
  const SeedDataScreen({super.key});

  @override
  State<SeedDataScreen> createState() => _SeedDataScreenState();
}

class _SeedDataScreenState extends State<SeedDataScreen> {
  bool _seeding = false;
  String _log = '';

  void _addLog(String msg) {
    setState(() => _log += '$msg\n');
  }

  Future<void> _seedData() async {
    setState(() {
      _seeding = true;
      _log = '';
    });

    final firestore = FirebaseFirestore.instance;

    try {
      // Check if data already exists
      final existing = await firestore.collection('categories').get();
      if (existing.docs.isNotEmpty) {
        _addLog('⚠️ Dữ liệu đã tồn tại! (${existing.docs.length} categories)');
        _addLog('Bỏ qua seed để tránh trùng lặp.');
        setState(() => _seeding = false);
        return;
      }

      _addLog('🌱 Bắt đầu seed dữ liệu...\n');

      // === CATEGORIES ===
      final cats = [
        {'id': 'cat-pho', 'name': 'Phở', 'sort_order': 1},
        {'id': 'cat-bun', 'name': 'Bún', 'sort_order': 2},
        {'id': 'cat-com', 'name': 'Cơm', 'sort_order': 3},
        {'id': 'cat-banhmi', 'name': 'Bánh Mì', 'sort_order': 4},
        {'id': 'cat-khaivi', 'name': 'Khai Vị', 'sort_order': 5},
        {'id': 'cat-douong', 'name': 'Đồ Uống', 'sort_order': 6},
      ];

      for (final c in cats) {
        final id = c.remove('id') as String;
        await firestore.collection('categories').doc(id).set(c);
      }
      _addLog('✅ Đã seed ${cats.length} categories');

      // === MENU ITEMS ===
      final items = [
        {'name': 'Phở Bò Tái', 'description': 'Phở bò tái truyền thống với nước dùng đậm đà', 'price': 75000,
         'image_url': 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=400&h=300&fit=crop',
         'category_id': 'cat-pho', 'is_popular': true, 'is_available': true, 'sort_order': 1},
        {'name': 'Phở Gà', 'description': 'Phở gà ta thả vườn, thịt gà ngọt tự nhiên', 'price': 65000,
         'image_url': 'https://images.unsplash.com/photo-1576577445504-6af96477db52?w=400&h=300&fit=crop',
         'category_id': 'cat-pho', 'is_popular': true, 'is_available': true, 'sort_order': 2},
        {'name': 'Phở Bò Viên', 'description': 'Phở bò viên dai giòn, nước dùng thanh ngọt', 'price': 70000,
         'image_url': 'https://images.unsplash.com/photo-1555126634-323283e090fa?w=400&h=300&fit=crop',
         'category_id': 'cat-pho', 'is_popular': false, 'is_available': true, 'sort_order': 3},
        {'name': 'Phở Đặc Biệt', 'description': 'Phở bò đặc biệt: tái, nạm, gầu, gân, sách', 'price': 95000,
         'image_url': 'https://images.unsplash.com/photo-1617093727343-374698b1b08d?w=400&h=300&fit=crop',
         'category_id': 'cat-pho', 'is_popular': true, 'is_available': true, 'sort_order': 4},
        {'name': 'Bún Bò Huế', 'description': 'Bún bò Huế cay nồng, giò heo, huyết, chả cua', 'price': 70000,
         'image_url': 'https://images.unsplash.com/photo-1569058242253-92a9c755a0ec?w=400&h=300&fit=crop',
         'category_id': 'cat-bun', 'is_popular': true, 'is_available': true, 'sort_order': 1},
        {'name': 'Bún Riêu Cua', 'description': 'Bún riêu cua đồng, cà chua, đậu hũ chiên', 'price': 68000,
         'image_url': 'https://images.unsplash.com/photo-1583224994076-0a3e5dfa49e4?w=400&h=300&fit=crop',
         'category_id': 'cat-bun', 'is_popular': false, 'is_available': true, 'sort_order': 2},
        {'name': 'Bún Chả Hà Nội', 'description': 'Bún chả nướng than hoa kiểu Hà Nội', 'price': 72000,
         'image_url': 'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?w=400&h=300&fit=crop',
         'category_id': 'cat-bun', 'is_popular': true, 'is_available': true, 'sort_order': 3},
        {'name': 'Cơm Tấm Sườn Bì Chả', 'description': 'Cơm tấm sườn nướng, bì, chả trứng', 'price': 65000,
         'image_url': 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=400&h=300&fit=crop',
         'category_id': 'cat-com', 'is_popular': true, 'is_available': true, 'sort_order': 1},
        {'name': 'Cơm Chiên Dương Châu', 'description': 'Cơm chiên tôm, lạp xưởng, trứng', 'price': 60000,
         'image_url': 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=400&h=300&fit=crop',
         'category_id': 'cat-com', 'is_popular': false, 'is_available': true, 'sort_order': 2},
        {'name': 'Bánh Mì Thịt Nướng', 'description': 'Bánh mì giòn kẹp thịt nướng, rau, đồ chua', 'price': 35000,
         'image_url': 'https://images.unsplash.com/photo-1600688640154-9619e002df30?w=400&h=300&fit=crop',
         'category_id': 'cat-banhmi', 'is_popular': true, 'is_available': true, 'sort_order': 1},
        {'name': 'Bánh Mì Ốp La', 'description': 'Bánh mì giòn, trứng ốp la, pate, xíu mại', 'price': 30000,
         'image_url': 'https://images.unsplash.com/photo-1509722747041-616f39b57569?w=400&h=300&fit=crop',
         'category_id': 'cat-banhmi', 'is_popular': false, 'is_available': true, 'sort_order': 2},
        {'name': 'Gỏi Cuốn Tôm Thịt', 'description': 'Gỏi cuốn tươi mát kèm nước chấm đậu phộng', 'price': 45000,
         'image_url': 'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=400&h=300&fit=crop',
         'category_id': 'cat-khaivi', 'is_popular': true, 'is_available': true, 'sort_order': 1},
        {'name': 'Chả Giò Chiên', 'description': 'Chả giò chiên giòn nhân thịt, miến, mộc nhĩ', 'price': 50000,
         'image_url': 'https://images.unsplash.com/photo-1544025162-d76694265947?w=400&h=300&fit=crop',
         'category_id': 'cat-khaivi', 'is_popular': false, 'is_available': true, 'sort_order': 2},
        {'name': 'Trà Đá', 'description': 'Trà đá truyền thống', 'price': 5000,
         'image_url': 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400&h=300&fit=crop',
         'category_id': 'cat-douong', 'is_popular': true, 'is_available': true, 'sort_order': 1},
        {'name': 'Cà Phê Sữa Đá', 'description': 'Cà phê phin truyền thống kèm sữa đặc', 'price': 29000,
         'image_url': 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefda?w=400&h=300&fit=crop',
         'category_id': 'cat-douong', 'is_popular': true, 'is_available': true, 'sort_order': 2},
        {'name': 'Nước Chanh Tươi', 'description': 'Nước chanh vắt, đường hoặc muối', 'price': 20000,
         'image_url': 'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=400&h=300&fit=crop',
         'category_id': 'cat-douong', 'is_popular': false, 'is_available': true, 'sort_order': 3},
        {'name': 'Sinh Tố Bơ', 'description': 'Sinh tố bơ béo ngậy, sữa đặc', 'price': 35000,
         'image_url': 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=400&h=300&fit=crop',
         'category_id': 'cat-douong', 'is_popular': false, 'is_available': true, 'sort_order': 4},
      ];

      for (final item in items) {
        await firestore.collection('menu_items').add(item);
      }
      _addLog('✅ Đã seed ${items.length} menu items');

      _addLog('\n🎉 Hoàn thành seed dữ liệu!');
    } catch (e) {
      _addLog('❌ Lỗi: $e');
    }

    setState(() => _seeding = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBrown,
      appBar: AppBar(
        title: Text('Seed Data → Firestore', style: GoogleFonts.inter(color: AppTheme.accentGold)),
        backgroundColor: AppTheme.warmBrown,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Đẩy dữ liệu Categories + Menu Items lên Firestore',
                style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Chỉ cần chạy 1 lần. Nếu đã có dữ liệu, sẽ bỏ qua.',
                style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _seeding ? null : _seedData,
              icon: _seeding
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.cloud_upload),
              label: Text(_seeding ? 'Đang seed...' : 'Seed Data ngay',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBrown,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(_log.isEmpty ? 'Nhấn "Seed Data ngay" để bắt đầu...' : _log,
                      style: GoogleFonts.sourceCodePro(color: AppTheme.textLight, fontSize: 13, height: 1.6)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
