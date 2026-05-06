import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../config/api_client.dart';
import '../../services/api_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _topItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final stats = await ApiService.fetchStats();
      final top = await ApiService.fetchTopItems(limit: 8);
      if (mounted) setState(() { _stats = stats; _topItems = top; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.warmBrown,
        title: Text('Xác nhận Reset?', style: GoogleFonts.inter(color: AppTheme.accentGold, fontWeight: FontWeight.bold)),
        content: Text('Hành động này sẽ xóa toàn bộ đơn hàng và đánh giá hiện có. Bạn có chắc chắn không?',
          style: GoogleFonts.inter(color: AppTheme.textLight)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('HỦY', style: GoogleFonts.inter(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            child: const Text('XÓA HẾT'),
          ),
        ],
      ),
    );

    if (ok == true) {
      setState(() => _loading = true);
      try {
        await ApiService.resetStats();
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã reset dữ liệu thành công!')));
        }
      } catch (e) {
        if (mounted) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange));
    if (_stats == null) return Center(child: Text('Không tải được dữ liệu', style: GoogleFonts.inter(color: AppTheme.textMuted)));

    final isWide = MediaQuery.of(context).size.width > 700;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Reset Button Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng quan kinh doanh', style: GoogleFonts.inter(
                  color: AppTheme.textLight, fontWeight: FontWeight.w700, fontSize: 18)),
              TextButton.icon(
                onPressed: _confirmReset,
                icon: const Icon(Icons.delete_sweep, color: AppTheme.dangerRed, size: 20),
                label: Text('Reset Thống kê', style: GoogleFonts.inter(color: AppTheme.dangerRed, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.dangerRed.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Revenue & summary cards
          Wrap(spacing: 14, runSpacing: 14, children: [
            _statCard('Doanh thu hôm nay', AppTheme.formatPrice((_stats!['revenue_today'] as num?)?.toInt() ?? 0),
                Icons.monetization_on_outlined, AppTheme.accentGold, isWide),
            _statCard('Tổng doanh thu (Tất cả)', AppTheme.formatPrice((_stats!['revenue_all_time'] as num?)?.toInt() ?? 0),
                Icons.account_balance_wallet_outlined, AppTheme.successGreen, isWide),
            _statCard('Đơn đang phục vụ', '${_stats!['active_orders'] ?? 0}',
                Icons.delivery_dining, AppTheme.primaryOrange, isWide),
            _statCard('Tổng đơn hôm nay', '${_stats!['total_orders_today'] ?? 0}',
                Icons.receipt_long, AppTheme.infoBlueDark, isWide),
            _statCard('Tổng đơn tất cả', '${_stats!['total_orders_all_time'] ?? 0}',
                Icons.inventory_2_outlined, AppTheme.textMuted, isWide),
          ]),

          const SizedBox(height: 24),

          // Order status breakdown
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppTheme.cardBrown, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Trạng thái đơn hàng', style: GoogleFonts.inter(
                  color: AppTheme.textLight, fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 16),
              _statusRow('Chờ xác nhận', _stats!['pending'] ?? 0, AppTheme.warningYellow),
              _statusRow('Đã xác nhận', _stats!['confirmed'] ?? 0, AppTheme.infoBlueDark),
              _statusRow('Đang chế biến', _stats!['preparing'] ?? 0, AppTheme.primaryOrange),
              _statusRow('Sẵn sàng', _stats!['ready'] ?? 0, AppTheme.successGreen),
              _statusRow('Hoàn thành hôm nay', _stats!['completed_today'] ?? 0, AppTheme.textMuted),
            ]),
          ),

          const SizedBox(height: 24),

          // Top selling items
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppTheme.cardBrown, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.trending_up, color: AppTheme.primaryOrange, size: 22),
                const SizedBox(width: 10),
                Text('Top Món Bán Chạy', style: GoogleFonts.inter(
                    color: AppTheme.textLight, fontWeight: FontWeight.w700, fontSize: 16)),
              ]),
              const SizedBox(height: 16),
              if (_topItems.isEmpty)
                Padding(padding: const EdgeInsets.all(20),
                    child: Text('Chưa có dữ liệu', style: GoogleFonts.inter(color: AppTheme.textMuted)))
              else
                ..._topItems.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final maxQty = (_topItems.first['total_quantity'] as num?)?.toDouble() ?? 1;
                  final qty = (item['total_quantity'] as num?)?.toDouble() ?? 0;
                  final pct = maxQty > 0 ? qty / maxQty : 0.0;
                  return _topItemRow(i + 1, item['name'] ?? '', qty.toInt(),
                      AppTheme.formatPrice((item['total_revenue'] as num?)?.toInt() ?? 0), pct);
                }),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, bool isWide) {
    return Container(
      width: isWide ? 200 : double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBrown,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 14),
        Text(value, style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 12)),
      ]),
    );
  }

  Widget _statusRow(String label, dynamic count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 14))),
        Text('$count', style: GoogleFonts.inter(color: AppTheme.textLight, fontWeight: FontWeight.w700, fontSize: 16)),
      ]),
    );
  }

  Widget _topItemRow(int rank, String name, int qty, String revenue, double pct) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(children: [
        Row(children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              color: rank <= 3 ? AppTheme.primaryOrange.withOpacity(0.15) : AppTheme.surfaceBrown,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text('#$rank', style: GoogleFonts.inter(
                color: rank <= 3 ? AppTheme.primaryOrange : AppTheme.textMuted,
                fontSize: 11, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 13))),
          Text('$qty phần', style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 12)),
          const SizedBox(width: 12),
          Text(revenue, style: GoogleFonts.inter(color: AppTheme.primaryOrange, fontWeight: FontWeight.w600, fontSize: 12)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppTheme.surfaceBrown,
            valueColor: const AlwaysStoppedAnimation(AppTheme.primaryOrange),
            minHeight: 6,
          ),
        ),
      ]),
    );
  }
}
