import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../models/menu_item.dart';
import '../services/api_service.dart';

class CartScreen extends StatefulWidget {
  final List<CartItem> cart;
  final int tableNumber;
  final String customerName;
  final Function(String orderId) onOrderSubmitted;
  final VoidCallback onCartUpdated;

  const CartScreen({
    super.key,
    required this.cart,
    required this.tableNumber,
    required this.customerName,
    required this.onOrderSubmitted,
    required this.onCartUpdated,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _submitting = false;
  bool _submitted = false;
  String? _orderId;
  int _rating = 0;
  final _commentController = TextEditingController();

  int get _total => widget.cart.fold(0, (sum, item) => sum + item.subtotal);

  Future<void> _submitOrder() async {
    if (widget.cart.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final result = await ApiService.createOrder(
        tableNumber: widget.tableNumber,
        customerName: widget.customerName,
        items: widget.cart,
      );
      setState(() {
        _submitted = true;
        _orderId = result['id'];
        _submitting = false;
      });
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gửi đơn: $e')),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.warmBrown,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _submitted ? _buildSuccessView(controller) : _buildCartView(controller),
      ),
    );
  }

  Widget _buildCartView(ScrollController controller) {
    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.textMuted.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Title
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.shopping_cart, color: AppTheme.primaryOrange),
              const SizedBox(width: 12),
              Text(
                'Giỏ hàng · Bàn ${widget.tableNumber}',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentGold,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.cardBrown),
        // Cart items
        Expanded(
          child: widget.cart.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 60, color: AppTheme.textMuted.withOpacity(0.3)),
                      const SizedBox(height: 12),
                      Text('Giỏ hàng trống', style: GoogleFonts.inter(color: AppTheme.textMuted)),
                    ],
                  ),
                )
              : ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.cart.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) => _buildCartItem(index),
                ),
        ),
        // Total & Submit
        if (widget.cart.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: AppTheme.cardBrown,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tổng cộng', style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 16)),
                    Text(
                      AppTheme.formatPrice(_total),
                      style: GoogleFonts.inter(
                        color: AppTheme.primaryOrange,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submitOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Gửi Đơn Hàng',
                            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCartItem(int index) {
    final item = widget.cart[index];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBrown,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item.menuItem.imageUrl.isNotEmpty
                ? Image.network(item.menuItem.imageUrl, width: 56, height: 56, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 56, height: 56, color: AppTheme.surfaceBrown,
                      child: const Icon(Icons.restaurant, color: AppTheme.textMuted, size: 24)))
                : Container(width: 56, height: 56, color: AppTheme.surfaceBrown,
                    child: const Icon(Icons.restaurant, color: AppTheme.textMuted, size: 24)),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.menuItem.name,
                    style: GoogleFonts.inter(color: AppTheme.textLight, fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(AppTheme.formatPrice(item.subtotal),
                    style: GoogleFonts.inter(color: AppTheme.primaryOrange, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
          // Quantity controls
          Row(
            children: [
              _miniButton(Icons.remove, () {
                setState(() {
                  if (item.quantity > 1) {
                    item.quantity--;
                  } else {
                    widget.cart.removeAt(index);
                  }
                });
                widget.onCartUpdated();
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('${item.quantity}',
                    style: GoogleFonts.inter(color: AppTheme.textLight, fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              _miniButton(Icons.add, () {
                setState(() => item.quantity++);
                widget.onCartUpdated();
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppTheme.surfaceBrown,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryOrange, size: 18),
      ),
    );
  }

  Widget _buildSuccessView(ScrollController controller) {
    return SingleChildScrollView(
      controller: controller,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 0, bottom: 24),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textMuted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 48),
          ),
          const SizedBox(height: 20),
          Text(
            'Đơn hàng đã gửi! 🎉',
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentGold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đơn hàng của bạn đang được xử lý.\nChúng tôi sẽ phục vụ sớm nhất!',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 32),
          // Success Action
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => widget.onOrderSubmitted(_orderId!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Xong & Theo dõi đơn hàng', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 24),
          // Optional Rating section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardBrown.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.warmBrown),
            ),
            child: Column(
              children: [
                Text(
                  'Đánh giá trải nghiệm (Tùy chọn)',
                  style: GoogleFonts.inter(color: AppTheme.textMuted, fontWeight: FontWeight.w500, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return GestureDetector(
                      onTap: () => setState(() => _rating = i + 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          i < _rating ? Icons.star : Icons.star_border,
                          color: AppTheme.accentGold,
                          size: 32,
                        ),
                      ),
                    );
                  }),
                ),
                if (_rating > 0) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _commentController,
                    maxLines: 2,
                    style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Nhận xét thêm...',
                      fillColor: AppTheme.surfaceBrown,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _submitReview,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGold),
                      child: Text('Gửi đánh giá', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.primaryBrown)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReview() async {
    if (_rating == 0) return;
    try {
      await ApiService.submitReview(
        orderId: _orderId,
        tableNumber: widget.tableNumber,
        rating: _rating,
        comment: _commentController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cảm ơn bạn đã đánh giá! 🙏')),
        );
      }
      widget.onOrderSubmitted(_orderId!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gửi đánh giá: $e')),
        );
      }
    }
  }
}
