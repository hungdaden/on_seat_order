import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/api_client.dart';
import '../../services/api_service.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    final currentPath = GoRouterState.of(context).uri.path;
    final today = DateFormat('d/M/yyyy').format(DateTime.now());

    final isLoggedIn = ApiClient.token != null;

    if (!isLoggedIn) {
      return Scaffold(
        backgroundColor: AppTheme.primaryBrown,
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.warmBrown,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.cardBrown),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: AppTheme.primaryOrange),
                const SizedBox(height: 24),
                Text(
                  'Yêu cầu đăng nhập',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bạn cần đăng nhập bằng tài khoản Admin để truy cập trang này.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: AppTheme.textMuted),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => context.go('/admin'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryOrange),
                    child: Text('Đến trang Đăng nhập', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryBrown,
      body: Row(
        children: [
          // Sidebar
          if (isWide) _buildSidebar(context, currentPath, today),
          // Main content
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppTheme.warmBrown,
                    border: Border(bottom: BorderSide(color: AppTheme.cardBrown)),
                  ),
                  child: Row(
                    children: [
                      if (!isWide)
                        Builder(
                          builder: (ctx) => IconButton(
                            icon: const Icon(Icons.menu, color: AppTheme.textLight),
                            onPressed: () => Scaffold.of(ctx).openDrawer(),
                          ),
                        ),
                      Text(
                        _getPageTitle(currentPath),
                        style: GoogleFonts.playfairDisplay(
                          fontSize: isWide ? 24 : 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentGold,
                        ),
                      ),
                      const Spacer(),
                      if (isWide)
                        Text(today, style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13)),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AppTheme.textMuted, size: 22),
                        onPressed: () {
                          // This is a simple way to trigger a rebuild of the child
                          context.go(currentPath);
                        },
                        tooltip: 'Làm mới trang',
                      ),
                    ],
                  ),
                ),
                // Page content
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
      drawer: isWide ? null : Drawer(
        backgroundColor: AppTheme.warmBrown,
        child: _buildSidebarContent(context, currentPath, today),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, String currentPath, String today) {
    return Container(
      width: 240,
      color: AppTheme.warmBrown,
      child: _buildSidebarContent(context, currentPath, today),
    );
  }

  Widget _buildSidebarContent(BuildContext context, String currentPath, String today) {
    return Column(
      children: [
        // Brand header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(child: Text('🍜', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Phở Cẩm Phả',
                        style: GoogleFonts.playfairDisplay(
                            color: AppTheme.accentGold, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Admin Panel',
                        style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(color: AppTheme.cardBrown, height: 1),

        const SizedBox(height: 12),

        // Nav items
        _buildNavItem(context, Icons.notifications_outlined, 'Đơn Hàng', '/admin/orders', currentPath,
            badge: null),
        _buildNavItem(context, Icons.restaurant_menu, 'Thực Đơn', '/admin/menu', currentPath),
        _buildNavItem(context, Icons.bar_chart, 'Thống Kê', '/admin/stats', currentPath),

        const Spacer(),

        // Logout
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await ApiService.logout();
                if (context.mounted) context.go('/admin');
              },
              icon: const Icon(Icons.logout, size: 18),
              label: Text('Đăng xuất', style: GoogleFonts.inter(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textMuted,
                side: const BorderSide(color: AppTheme.cardBrown),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, String path, String currentPath,
      {int? badge}) {
    final isActive = currentPath == path;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: isActive ? AppTheme.primaryOrange.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            context.go(path);
            // Close drawer on mobile
            if (Scaffold.of(context).isDrawerOpen) {
              Navigator.pop(context);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon,
                    color: isActive ? AppTheme.primaryOrange : AppTheme.textMuted,
                    size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      color: isActive ? AppTheme.primaryOrange : AppTheme.textLight,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$badge',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getPageTitle(String path) {
    if (path.contains('orders')) return 'Quản Lý Đơn Hàng';
    if (path.contains('menu')) return 'Quản Lý Thực Đơn';
    if (path.contains('stats')) return 'Thống Kê';
    return 'Admin';
  }
}
