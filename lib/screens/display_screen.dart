import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

class DisplayScreen extends StatefulWidget {
  const DisplayScreen({super.key});

  @override
  State<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen> {
  List<Map<String, dynamic>> _tables = [];
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _loadData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final data = await ApiService.fetchTableStatuses();
      if (mounted) {
        setState(() {
          _tables = data;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading table status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    int availableCount = _tables.where((t) => t['is_available'] == true).length;
    int totalCount = _tables.length;

    return Scaffold(
      backgroundColor: Colors.black, // Dark background for TV
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange))
          : Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(40),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.warmBrown.withOpacity(0.5),
                    border: const Border(bottom: BorderSide(color: AppTheme.cardBrown, width: 2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'PHỞ CẨM PHẢ - TRẠNG THÁI BÀN',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentGold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _summaryBox('TRỐNG', '$availableCount', Colors.greenAccent),
                          const SizedBox(width: 40),
                          _summaryBox('ĐANG CÓ KHÁCH', '${totalCount - availableCount}', Colors.redAccent),
                        ],
                      ),
                    ],
                  ),
                ),
                // Grid of tables
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        mainAxisSpacing: 30,
                        crossAxisSpacing: 30,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: _tables.length,
                      itemBuilder: (context, index) {
                        final table = _tables[index];
                        final isAvailable = table['is_available'] == true;
                        return _buildTableCard(table['table_number'], isAvailable);
                      },
                    ),
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Vui lòng quét mã QR tại bàn để đặt món. Xin cảm ơn!',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      color: AppTheme.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _summaryBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 3),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.inter(fontSize: 72, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildTableCard(int number, bool isAvailable) {
    final color = isAvailable ? Colors.greenAccent : Colors.redAccent;
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color, width: 4),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'BÀN',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          Text(
            '$number',
            style: GoogleFonts.inter(fontSize: 64, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            isAvailable ? 'TRỐNG' : 'CÓ KHÁCH',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
