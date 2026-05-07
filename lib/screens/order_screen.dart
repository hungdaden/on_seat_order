import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';
import '../models/category.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import 'cart_screen.dart';

class OrderScreen extends StatefulWidget {
  final int tableNumber;
  const OrderScreen({super.key, required this.tableNumber});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _isCartExtended = true;
  List<Category> _categories = [];
  List<MenuItem> _allItems = [];
  List<MenuItem> _filteredItems = [];
  String _selectedCategory = 'all';
  final List<CartItem> _cart = [];
  String _customerName = '';
  bool _loading = true;
  final _nameController = TextEditingController();

  // Order tracking
  List<Order> _myOrders = [];
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadData();
    _loadMyOrders();
    _startPolling();
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isCartExtended) setState(() => _isCartExtended = false);
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_isCartExtended) setState(() => _isCartExtended = true);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final categories = await ApiService.fetchCategories();
      final items = await ApiService.fetchMenu();
      setState(() {
        _categories = categories;
        _allItems = items.where((i) => i.isAvailable).toList();
        _filteredItems = _allItems;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thực đơn: $e')),
        );
      }
    }
  }

  Future<void> _loadMyOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList('my_order_ids') ?? [];
      if (ids.isEmpty) return;

      List<Order> orders = [];
      for (String id in ids) {
        try {
          final o = await ApiService.fetchOrder(id);
          orders.add(o);
        } catch (_) {}
      }
      setState(() => _myOrders = orders);
    } catch (e) {
      debugPrint('Error loading my orders: $e');
    }
  }

  void _startPolling() {
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      // 1. Refresh menu items for availability
      try {
        final newMenu = await ApiService.fetchMenu(categoryId: _selectedCategory);
        if (mounted) {
          setState(() {
            _allItems = newMenu;
            _filterByCategory(_selectedCategory);
          });
        }
      } catch (_) {}

      // 2. Refresh order status
      if (_myOrders.isEmpty) return;
      
      bool changed = false;
      List<Order> updatedOrders = [];
      
      for (Order oldOrder in _myOrders) {
        try {
          final newOrder = await ApiService.fetchOrder(oldOrder.id);
          if (newOrder.status != oldOrder.status) {
            changed = true;
            _showStatusNotification(newOrder);
          }
          updatedOrders.add(newOrder);
        } catch (_) {
          updatedOrders.add(oldOrder);
        }
      }

      if (changed && mounted) {
        setState(() => _myOrders = updatedOrders);
      }
    });
  }

  void _showStatusNotification(Order order) {
    String statusText = '';
    IconData icon = Icons.info_outline;
    Color color = AppTheme.primaryOrange;

    switch (order.status) {
      case 'confirmed':
        statusText = 'Đã xác nhận';
        icon = Icons.check_circle_outline;
        break;
      case 'preparing':
        statusText = 'Đang chế biến';
        icon = Icons.restaurant;
        break;
      case 'ready':
        statusText = 'Sẵn sàng phục vụ! 🍜';
        icon = Icons.notifications_active;
        color = AppTheme.successGreen;
        break;
      case 'completed':
        statusText = 'Đã hoàn thành';
        icon = Icons.done_all;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.cardBrown,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cập nhật đơn hàng!', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.textLight)),
                  Text('Đơn hàng #${order.id.substring(0, 4)}: $statusText', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _tabController.animateTo(1),
              child: Text('XEM', style: GoogleFonts.inter(color: AppTheme.accentGold, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveOrder(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('my_order_ids') ?? [];
    if (!ids.contains(orderId)) {
      ids.add(orderId);
      await prefs.setStringList('my_order_ids', ids);
    }
    _loadMyOrders();
    _tabController.animateTo(1); // Switch to orders tab
  }

  void _filterByCategory(String categoryId) {
    setState(() {
      _selectedCategory = categoryId;
      if (categoryId == 'all') {
        _filteredItems = _allItems;
      } else {
        _filteredItems = _allItems.where((i) => i.categoryId == categoryId).toList();
      }
    });
  }

  void _addToCart(MenuItem item) {
    setState(() {
      final existing = _cart.indexWhere((c) => c.menuItem.id == item.id);
      if (existing >= 0) {
        _cart[existing].quantity++;
      } else {
        _cart.add(CartItem(menuItem: item));
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm ${item.name}'),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  int get _cartCount => _cart.fold(0, (sum, item) => sum + item.quantity);
  int get _cartTotal => _cart.fold(0, (sum, item) => sum + item.subtotal);

  void _openCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CartScreen(
        cart: _cart,
        tableNumber: widget.tableNumber,
        customerName: _customerName.isNotEmpty ? _customerName : 'Khách',
        onOrderSubmitted: (orderId) {
          setState(() => _cart.clear());
          _saveOrder(orderId);
          Navigator.pop(ctx);
        },
        onCartUpdated: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: AppTheme.primaryBrown,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange))
          : Column(
              children: [
                _buildHeader(isWide),
                // TabBar
                Container(
                  color: AppTheme.primaryBrown,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.primaryOrange,
                    labelColor: AppTheme.primaryOrange,
                    unselectedLabelColor: AppTheme.textMuted,
                    labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                    tabs: const [
                      Tab(text: 'Thực đơn', icon: Icon(Icons.restaurant_menu, size: 20)),
                      Tab(text: 'Đơn của tôi', icon: Icon(Icons.receipt_long, size: 20)),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Menu Tab
                      _buildMenuTab(isWide),
                      // Orders Tab
                      _buildOrdersTab(),
                    ],
                  ),
                ),
              ],
            ),
      // Floating cart button
      floatingActionButton: _cart.isNotEmpty && _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _openCart,
              isExtended: _isCartExtended,
              backgroundColor: AppTheme.primaryOrange,
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              label: Text(
                '$_cartCount món · ${AppTheme.formatPrice(_cartTotal)}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildMenuTab(bool isWide) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Customer name
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Text('Tên của bạn:', style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 14)),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: TextField(
                      controller: _nameController,
                      onChanged: (v) => _customerName = v,
                      style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Khách',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        fillColor: AppTheme.cardBrown,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Category chips
        SliverToBoxAdapter(
          child: _buildCategoryChips(),
        ),
        // Menu grid
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWide ? 3 : 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.72,
            ),
            delegate: SliverChildBuilderDelegate(
              (ctx, index) => _buildMenuCard(_filteredItems[index]),
              childCount: _filteredItems.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersTab() {
    if (_myOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.textMuted.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text('Bạn chưa có đơn hàng nào', style: GoogleFonts.inter(color: AppTheme.textMuted)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(0),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryOrange),
              child: const Text('Xem thực đơn ngay'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myOrders.length,
      itemBuilder: (context, index) {
        final order = _myOrders.reversed.toList()[index];
        return _buildOrderTrackingCard(order);
      },
    );
  }

  Widget _buildOrderTrackingCard(Order order) {
    String statusLabel = '';
    Color statusColor = AppTheme.textMuted;
    
    switch (order.status) {
      case 'pending': statusLabel = 'Chờ xác nhận'; statusColor = AppTheme.accentGold; break;
      case 'confirmed': statusLabel = 'Đã xác nhận'; statusColor = Colors.blue; break;
      case 'preparing': statusLabel = 'Đang chế biến'; statusColor = AppTheme.primaryOrange; break;
      case 'ready': statusLabel = 'Sẵn sàng phục vụ!'; statusColor = AppTheme.successGreen; break;
      case 'completed': statusLabel = 'Đã hoàn thành'; statusColor = AppTheme.textMuted; break;
    }

    return Card(
      color: AppTheme.cardBrown,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Đơn hàng #${order.id.substring(0, 4)}', 
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.textLight)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(statusLabel, style: GoogleFonts.inter(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const Divider(height: 24, color: AppTheme.warmBrown),
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text('${item.quantity}x', style: GoogleFonts.inter(color: AppTheme.accentGold, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(item.menuItemName, style: GoogleFonts.inter(color: AppTheme.textLight))),
                  Text(AppTheme.formatPrice(item.price * item.quantity), style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            )),
            const Divider(height: 24, color: AppTheme.warmBrown),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tổng thanh toán:', style: GoogleFonts.inter(color: AppTheme.textMuted)),
                Text(AppTheme.formatPrice(order.total), 
                  style: GoogleFonts.inter(color: AppTheme.primaryOrange, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isWide) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.warmBrown,
            AppTheme.primaryBrown,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              // Top bar
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Bàn ${widget.tableNumber}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_cart.isNotEmpty)
                    IconButton(
                      onPressed: _openCart,
                      icon: Badge(
                        label: Text('$_cartCount'),
                        child: const Icon(Icons.shopping_cart_outlined, color: AppTheme.textLight),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Thực Đơn Hôm Nay',
                style: GoogleFonts.playfairDisplay(
                  fontSize: isWide ? 30 : 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentGold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Chọn món, chúng tôi phục vụ ngay',
                style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _buildChip('all', 'Tất Cả'),
          ..._categories.map((c) => _buildChip(c.id, c.name)),
        ],
      ),
    );
  }

  Widget _buildChip(String id, String name) {
    final isSelected = _selectedCategory == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          name,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : AppTheme.textLight,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        onSelected: (_) => _filterByCategory(id),
        selectedColor: AppTheme.primaryOrange,
        backgroundColor: AppTheme.cardBrown,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }

  Widget _buildMenuCard(MenuItem item) {
    return Opacity(
      opacity: item.isAvailable ? 1.0 : 0.6,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBrown,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.warmBrown.withOpacity(0.5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  item.imageUrl.isNotEmpty
                      ? Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppTheme.surfaceBrown,
                            child: const Icon(Icons.restaurant, color: AppTheme.textMuted, size: 40),
                          ),
                        )
                      : Container(
                          color: AppTheme.surfaceBrown,
                          child: const Icon(Icons.restaurant, color: AppTheme.textMuted, size: 40),
                        ),
                  if (item.isPopular)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Phổ biến',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (!item.isAvailable)
                    Container(
                      color: Colors.black45,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.dangerRed,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'HẾT MÓN',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Details
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppTheme.formatPrice(item.price),
                          style: GoogleFonts.inter(
                            color: AppTheme.primaryOrange,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        _buildAddButton(item),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(MenuItem item) {
    if (!item.isAvailable) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceBrown,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.block, color: AppTheme.textMuted, size: 18),
      );
    }
    return InkWell(
      onTap: () => _addToCart(item),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryOrange.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.add, color: AppTheme.primaryOrange, size: 18),
      ),
    );
  }
}
