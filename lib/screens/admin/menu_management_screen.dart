import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/category.dart';
import '../../models/menu_item.dart';
import '../../services/api_service.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});
  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  List<MenuItem> _items = [];
  List<Category> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cats = await ApiService.fetchCategories();
      final items = await ApiService.fetchMenu();
      if (mounted) setState(() { _categories = cats; _items = items; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showItemDialog({MenuItem? item}) {
    final nameC = TextEditingController(text: item?.name ?? '');
    final descC = TextEditingController(text: item?.description ?? '');
    final priceC = TextEditingController(text: item?.price.toString() ?? '');
    final imgC = TextEditingController(text: item?.imageUrl ?? '');
    String catId = item?.categoryId ?? (_categories.isNotEmpty ? _categories.first.id : '');
    bool popular = item?.isPopular ?? false;
    bool available = item?.isAvailable ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          backgroundColor: AppTheme.warmBrown,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(item == null ? 'Thêm món mới' : 'Sửa món',
              style: GoogleFonts.playfairDisplay(color: AppTheme.accentGold, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _field('Tên món', nameC),
                const SizedBox(height: 12),
                _field('Mô tả', descC, maxLines: 2),
                const SizedBox(height: 12),
                _field('Giá (VND)', priceC, isNum: true),
                const SizedBox(height: 12),
                _field('URL hình ảnh', imgC),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: catId.isNotEmpty ? catId : null,
                  decoration: const InputDecoration(labelText: 'Danh mục', fillColor: AppTheme.surfaceBrown),
                  dropdownColor: AppTheme.cardBrown,
                  style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 14),
                  items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (v) => setS(() => catId = v ?? catId),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Checkbox(value: popular, onChanged: (v) => setS(() => popular = v!),
                      activeColor: AppTheme.primaryOrange),
                  Text('Phổ biến', style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 14)),
                  const SizedBox(width: 20),
                  Checkbox(value: available, onChanged: (v) => setS(() => available = v!),
                      activeColor: AppTheme.successGreen),
                  Text('Có sẵn', style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 14)),
                ]),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: Text('Hủy', style: GoogleFonts.inter(color: AppTheme.textMuted))),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'name': nameC.text,
                  'description': descC.text,
                  'price': int.tryParse(priceC.text) ?? 0,
                  'image_url': imgC.text,
                  'category_id': catId,
                  'is_popular': popular,
                  'is_available': available,
                };
                try {
                  if (item == null) {
                    await ApiService.createMenuItem(data);
                  } else {
                    await ApiService.updateMenuItem(item.id, data);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              },
              child: Text(item == null ? 'Thêm' : 'Lưu', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _deleteItem(MenuItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.warmBrown,
        title: Text('Xóa ${item.name}?', style: GoogleFonts.inter(color: AppTheme.textLight)),
        content: Text('Bạn có chắc muốn xóa món này?', style: GoogleFonts.inter(color: AppTheme.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            child: Text('Xóa', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.deleteMenuItem(item.id);
      _load();
    }
  }

  Widget _field(String label, TextEditingController c, {int maxLines = 1, bool isNum = false}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 14),
      decoration: InputDecoration(labelText: label, labelStyle: GoogleFonts.inter(color: AppTheme.textMuted),
          fillColor: AppTheme.surfaceBrown),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(children: [
            Text('${_items.length} món', style: GoogleFonts.inter(color: AppTheme.textMuted)),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _showItemDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: Text('Thêm món', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            itemCount: _items.length,
            itemBuilder: (_, i) => _buildItemTile(_items[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildItemTile(MenuItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.cardBrown, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: item.imageUrl.isNotEmpty
              ? Image.network(item.imageUrl, width: 60, height: 60, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: AppTheme.surfaceBrown,
                      child: const Icon(Icons.restaurant, color: AppTheme.textMuted)))
              : Container(width: 60, height: 60, color: AppTheme.surfaceBrown,
                  child: const Icon(Icons.restaurant, color: AppTheme.textMuted)),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.name, style: GoogleFonts.inter(color: AppTheme.textLight, fontWeight: FontWeight.w600, fontSize: 14)),
          Text(item.categoryName, style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 12)),
          Text(AppTheme.formatPrice(item.price),
              style: GoogleFonts.inter(color: AppTheme.primaryOrange, fontWeight: FontWeight.w700, fontSize: 14)),
        ])),
        IconButton(icon: const Icon(Icons.edit, color: AppTheme.textMuted, size: 20),
            onPressed: () => _showItemDialog(item: item)),
        IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.dangerRed, size: 20),
            onPressed: () => _deleteItem(item)),
      ]),
    );
  }
}
