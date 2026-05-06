import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/order.dart';
import '../../services/api_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order> _orders = [];
  bool _loading = true;
  String _filterStatus = '';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    // Auto-refresh every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadOrders());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await ApiService.fetchOrders(
        status: _filterStatus.isNotEmpty ? _filterStatus : null,
      );
      if (mounted) setState(() { _orders = orders; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    try {
      await ApiService.updateOrderStatus(orderId, newStatus);
      _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã cập nhật: ${AppTheme.statusText(newStatus)}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group by status for KPI
    final pending = _orders.where((o) => o.status == 'pending').length;
    final confirmed = _orders.where((o) => o.status == 'confirmed').length;
    final preparing = _orders.where((o) => o.status == 'preparing').length;
    final ready = _orders.where((o) => o.status == 'ready').length;

    return _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange))
        : RefreshIndicator(
            onRefresh: _loadOrders,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // KPI cards
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _kpiCard('Tổng đơn', '${_orders.length}', Icons.receipt_long, AppTheme.textMuted),
                    _kpiCard('Chờ xác nhận', '$pending', Icons.schedule, AppTheme.warningYellow),
                    _kpiCard('Đang chế biến', '${confirmed + preparing}', Icons.restaurant, AppTheme.primaryOrange),
                    _kpiCard('Sẵn sàng', '$ready', Icons.notifications_active, AppTheme.successGreen),
                  ],
                ),
                const SizedBox(height: 20),

                // Status filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('', 'Tất cả'),
                      _filterChip('pending', 'Chờ xác nhận'),
                      _filterChip('confirmed', 'Đã xác nhận'),
                      _filterChip('preparing', 'Đang chế biến'),
                      _filterChip('ready', 'Sẵn sàng'),
                      _filterChip('completed', 'Hoàn thành'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Orders list
                if (_orders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined, size: 60, color: AppTheme.textMuted.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        Text('Chưa có đơn hàng', style: GoogleFonts.inter(color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                ..._orders.map(_buildOrderCard),
              ],
            ),
          );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBrown,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.inter(
            color: AppTheme.textLight, fontSize: 28, fontWeight: FontWeight.w800)),
          Text(label, style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _filterChip(String status, String label) {
    final isSelected = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label, style: GoogleFonts.inter(
          color: isSelected ? Colors.white : AppTheme.textLight, fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
        onSelected: (_) {
          setState(() => _filterStatus = status);
          _loadOrders();
        },
        selectedColor: AppTheme.primaryOrange,
        backgroundColor: AppTheme.cardBrown,
        checkmarkColor: Colors.white,
        side: BorderSide.none,
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final statusColor = AppTheme.statusColor(order.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardBrown,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Bàn ${order.tableNumber}',
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              const SizedBox(width: 10),
              Text(order.customerName,
                  style: GoogleFonts.inter(color: AppTheme.textLight, fontWeight: FontWeight.w600, fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppTheme.statusIcon(order.status), color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(AppTheme.statusText(order.status),
                        style: GoogleFonts.inter(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Items
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Text('${item.quantity}x', style: GoogleFonts.inter(
                  color: AppTheme.primaryOrange, fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(width: 8),
                Expanded(child: Text(item.menuItemName,
                    style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 13))),
                Text(AppTheme.formatPrice(item.price * item.quantity),
                    style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          )),
          const SizedBox(height: 10),
          const Divider(color: AppTheme.surfaceBrown),
          // Footer
          Row(
            children: [
              Text('Tổng: ', style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13)),
              Text(AppTheme.formatPrice(order.total),
                  style: GoogleFonts.inter(color: AppTheme.primaryOrange, fontWeight: FontWeight.w800, fontSize: 16)),
              const Spacer(),
              // Action buttons
              ..._buildActionButtons(order),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(Order order) {
    String? nextStatus;
    String? nextLabel;
    IconData? nextIcon;

    switch (order.status) {
      case 'pending':
        nextStatus = 'confirmed';
        nextLabel = 'Xác nhận';
        nextIcon = Icons.check;
        break;
      case 'confirmed':
        nextStatus = 'preparing';
        nextLabel = 'Chế biến';
        nextIcon = Icons.restaurant;
        break;
      case 'preparing':
        nextStatus = 'ready';
        nextLabel = 'Sẵn sàng';
        nextIcon = Icons.done;
        break;
      case 'ready':
        nextStatus = 'completed';
        nextLabel = 'Hoàn thành';
        nextIcon = Icons.done_all;
        break;
    }

    if (nextStatus == null) return [];

    return [
      SizedBox(
        height: 36,
        child: ElevatedButton.icon(
          onPressed: () => _updateStatus(order.id, nextStatus!),
          icon: Icon(nextIcon, size: 16),
          label: Text(nextLabel!, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.statusColor(nextStatus),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    ];
  }
}
