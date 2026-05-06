import 'dart:io';
import 'package:qr/qr.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) {
  final host = args.isNotEmpty ? args[0] : 'http://localhost:8080';
  final outputDir = p.join(Directory.current.path, 'server', 'qr_codes');
  Directory(outputDir).createSync(recursive: true);

  print('🔲 Generating QR codes for 10 tables...');
  print('   Host: $host');
  print('   Output: $outputDir\n');

  for (int table = 1; table <= 10; table++) {
    final url = '$host/order?table=$table';
    final padded = table.toString().padLeft(2, '0');
    final filepath = p.join(outputDir, 'table_$padded.svg');

    final qrCode = QrCode.fromData(data: url, errorCorrectLevel: QrErrorCorrectLevel.M);
    final qrImage = QrImage(qrCode);
    final svg = _generateSvg(qrImage, table);
    File(filepath).writeAsStringSync(svg);
    print('   ✅ Table $padded → table_$padded.svg');
  }

  final htmlPath = p.join(outputDir, 'all_tables.html');
  _generatePrintPage(htmlPath, host);
  print('\n📄 Printable page: $htmlPath');
  print('🎉 Done! Open all_tables.html and print.');
}

String _generateSvg(QrImage qrImage, int tableNumber) {
  final mc = qrImage.moduleCount;
  final cs = 10;
  final pad = 40;
  final lh = 60;
  final ts = mc * cs + pad * 2;
  final th = ts + lh;

  final buf = StringBuffer();
  buf.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  buf.writeln('<svg xmlns="http://www.w3.org/2000/svg" width="$ts" height="$th" viewBox="0 0 $ts $th">');
  buf.writeln('<rect width="$ts" height="$th" fill="white"/>');

  for (int r = 0; r < mc; r++) {
    for (int c = 0; c < mc; c++) {
      if (qrImage.isDark(r, c)) {
        buf.writeln('<rect x="${c * cs + pad}" y="${r * cs + pad}" width="$cs" height="$cs" fill="#1A0F00"/>');
      }
    }
  }

  final ly = ts + 25;
  buf.writeln('<text x="${ts / 2}" y="$ly" text-anchor="middle" font-family="Arial" font-size="24" font-weight="bold" fill="#D35400">Bàn $tableNumber</text>');
  buf.writeln('<text x="${ts / 2}" y="${ly + 22}" text-anchor="middle" font-family="Arial" font-size="11" fill="#666">Phở Cẩm Phả</text>');
  buf.writeln('</svg>');
  return buf.toString();
}

void _generatePrintPage(String filepath, String host) {
  final buf = StringBuffer();
  buf.writeln('<!DOCTYPE html><html lang="vi"><head><meta charset="UTF-8">');
  buf.writeln('<title>QR Codes — Phở Cẩm Phả</title>');
  buf.writeln('<style>body{font-family:Arial;margin:20px}h1{text-align:center;color:#D35400}');
  buf.writeln('.grid{display:grid;grid-template-columns:repeat(2,1fr);gap:30px;max-width:800px;margin:0 auto}');
  buf.writeln('.card{border:2px solid #D35400;border-radius:12px;padding:20px;text-align:center;page-break-inside:avoid}');
  buf.writeln('.card h2{color:#1A0F00;margin:10px 0 5px}.card p{color:#666;font-size:12px;margin:0}');
  buf.writeln('.card img{width:200px;height:200px}@media print{.no-print{display:none}}</style></head><body>');
  buf.writeln('<h1>🍜 Phở Cẩm Phả — Mã QR Đặt Món</h1>');
  buf.writeln('<p class="no-print" style="text-align:center;margin-bottom:20px">');
  buf.writeln('<button onclick="window.print()" style="padding:10px 30px;font-size:16px;background:#D35400;color:white;border:none;border-radius:8px;cursor:pointer">🖨 In tất cả</button></p>');
  buf.writeln('<div class="grid">');
  for (int t = 1; t <= 10; t++) {
    final pad = t.toString().padLeft(2, '0');
    buf.writeln('<div class="card"><img src="table_$pad.svg" alt="QR Bàn $t"/><h2>Bàn $t</h2>');
    buf.writeln('<p>Quét mã QR để đặt món</p><p style="font-size:10px;color:#999;margin-top:5px">$host/order?table=$t</p></div>');
  }
  buf.writeln('</div></body></html>');
  File(filepath).writeAsStringSync(buf.toString());
}
