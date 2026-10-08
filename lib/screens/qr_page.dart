import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../store.dart';
import '../utils.dart';
import '../widgets.dart';

class QrPage extends StatefulWidget {
  final String fabricId;
  const QrPage({super.key, required this.fabricId});

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _showPrice = true;
  bool _showLocation = true;
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final boundary = _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 4);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/qr-label-${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(data!.buffer.asUint8List());
      await Share.shareXFiles([XFile(file.path)], subject: 'لیبل QR');
    } catch (_) {
      if (mounted) toast(context, 'ساخت تصویر لیبل انجام نشد.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final f = store.byId(widget.fabricId);
    if (f == null) return Scaffold(appBar: AppBar(), body: const EmptyState(Icons.search_off, 'کالا پیدا نشد.'));

    return Scaffold(
      appBar: AppBar(title: const Text('لیبل QR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Center(
            child: RepaintBoundary(
              key: _boundaryKey,
              child: Container(
                width: 280,
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  QrImageView(data: jsonEncode({'code': f.code, 'name': f.name}), size: 220, backgroundColor: Colors.white),
                  const SizedBox(height: 8),
                  Text(f.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black)),
                  const SizedBox(height: 2),
                  Text('کد: ${toFa(f.code)}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  if (_showLocation) Text(f.location, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  if (_showPrice) Text('${store.money(f.pricePerMeter)} / ${f.unit}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(value: _showPrice, onChanged: (v) => setState(() => _showPrice = v), title: const Text('نمایش قیمت روی لیبل')),
          SwitchListTile(value: _showLocation, onChanged: (v) => setState(() => _showLocation = v), title: const Text('نمایش موقعیت روی لیبل')),
          const SizedBox(height: 8),
          GlassButton(
            onPressed: _busy ? null : _share,
            icon: Icons.ios_share,
            label: 'اشتراک‌گذاری / چاپ تصویر لیبل',
          ),
          const SizedBox(height: 10),
          const Text('تصویر را می‌شود در برنامه‌ی پرینتر یا واتس‌اپ/تلگرام فرستاد یا ذخیره کرد و از آنجا چاپ گرفت.', style: TextStyle(fontSize: 11, color: Color(0xFF78716C), height: 1.8)),
        ],
      ),
    );
  }
}
