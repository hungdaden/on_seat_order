import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/api_client.dart';
import '../../services/api_service.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _usernameCtrl = TextEditingController(text: 'admin');
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkExistingToken();
  }

  Future<void> _checkExistingToken() async {
    if (ApiClient.token != null) {
      final valid = await ApiService.verifyToken();
      if (valid && mounted) {
        context.go('/admin/orders');
      }
    }
  }

  Future<void> _login() async {
    if (_usernameCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Vui lòng nhập đầy đủ');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ApiService.login(_usernameCtrl.text.trim(), _passwordCtrl.text);
      if (mounted) context.go('/admin/orders');
    } catch (e) {
      setState(() {
        _error = 'Sai tài khoản hoặc mật khẩu';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBrown,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(child: Text('🍜', style: TextStyle(fontSize: 36))),
                ),
                const SizedBox(height: 20),
                Text(
                  'Phở Cẩm Phả',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGold,
                  ),
                ),
                const SizedBox(height: 6),
                Text('Admin Panel', style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 14)),
                const SizedBox(height: 40),

                // Login form
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBrown,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.warmBrown),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Đăng nhập', style: GoogleFonts.inter(
                        color: AppTheme.textLight, fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 24),
                      Text('Tài khoản', style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _usernameCtrl,
                        style: GoogleFonts.inter(color: AppTheme.textLight),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person_outline, color: AppTheme.textMuted),
                          hintText: 'admin',
                        ),
                        onSubmitted: (_) => _login(),
                      ),
                      const SizedBox(height: 18),
                      Text('Mật khẩu', style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: _obscure,
                        style: GoogleFonts.inter(color: AppTheme.textLight),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textMuted),
                          hintText: '••••••',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_off : Icons.visibility,
                              color: AppTheme.textMuted,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        onSubmitted: (_) => _login(),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.dangerRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppTheme.dangerRed, size: 18),
                              const SizedBox(width: 8),
                              Text(_error!, style: GoogleFonts.inter(color: AppTheme.dangerRed, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          child: _loading
                              ? const SizedBox(width: 22, height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text('Đăng nhập',
                                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: Text('← Về trang chủ', style: GoogleFonts.inter(color: AppTheme.textMuted)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
