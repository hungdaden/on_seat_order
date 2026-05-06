import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _tableNumber = 1;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBrown,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryOrange.withOpacity(0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🍜', style: TextStyle(fontSize: 44)),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Restaurant name
                  Text(
                    'Phở Cẩm Phả',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentGold,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hệ thống đặt món tại bàn',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Table number selector
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBrown,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.warmBrown, width: 1),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Số bàn của bạn',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: AppTheme.textLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStepperButton(
                              icon: Icons.remove,
                              onTap: () {
                                if (_tableNumber > 1) {
                                  setState(() => _tableNumber--);
                                }
                              },
                            ),
                            Container(
                              width: 100,
                              alignment: Alignment.center,
                              child: Text(
                                '$_tableNumber',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 52,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ),
                            _buildStepperButton(
                              icon: Icons.add,
                              onTap: () {
                                if (_tableNumber < 10) {
                                  setState(() => _tableNumber++);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Order button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        context.go('/order?table=$_tableNumber');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: AppTheme.primaryOrange.withOpacity(0.4),
                      ),
                      child: Text(
                        'Đặt Món',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Admin button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/admin'),
                      icon: const Icon(Icons.settings, size: 20),
                      label: Text(
                        'Vào Admin',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textMuted,
                        side: const BorderSide(color: AppTheme.textMuted, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'Scan QR hoặc chọn bàn bên trên',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textMuted.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepperButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: AppTheme.surfaceBrown,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          child: Icon(icon, color: AppTheme.primaryOrange, size: 28),
        ),
      ),
    );
  }
}
