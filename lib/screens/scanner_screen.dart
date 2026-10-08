import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../store.dart';
import '../utils.dart';
import '../widgets.dart';
import 'catalog_screen.dart';

/// متن QR (JSON لیبل‌های ما یا فقط کد) → کالا
Fabric? findByScan(AppStore store, String raw) {
  var value = raw.trim();
  try {
    final obj = jsonDecode(value);
    if (obj is Map) {
      final c = obj['code'] ?? obj['c'];
      if (c != null) value = c.toString();
    }
  } catch (_) {}
  final key = normalizeKey(value);
  if (key.isEmpty) return null;
  for (final f in store.fabrics) {
    if (normalizeKey(f.code) == key) return f;
  }
  for (final f in store.fabrics) {
    if (normalizeKey(f.code).contains(key) || normalizeKey(f.name).contains(key)) return f;
  }
  return null;
}

class ScannerScreen extends StatefulWidget {
  /// دوربین فقط وقتی تب اسکن باز است روشن می‌شود
  final bool active;
  const ScannerScreen({super.key, required this.active});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _manual = TextEditingController();

  @override
  void dispose() {
    _manual.dispose();
    super.dispose();
  }

  /// true یعنی کالا پیدا و باز شد (و کاربر برگشت)
  Future<bool> _open(String raw) async {
    final store = context.read<AppStore>();
    final f = findByScan(store, raw);
    if (f == null) {
      toast(context, 'کالایی با این کد پیدا نشد.', error: true);
      return false;
    }
    HapticFeedback.mediumImpact();
    await openFabric(context, f.id);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, kNavSpace + 20),
      children: [
        const Text('اسکن QR', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('دوربین را روی لیبل پارچه بگیرید.', style: TextStyle(fontSize: 12, color: Color(0xFF78716C))),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: widget.active ? _Camera(onCode: _open) : Container(color: Colors.black),
          ),
        ),
        const SizedBox(height: 18),
        const Text('یا کد کالا را دستی بنویسید', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _manual,
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => _open(v),
              decoration: const InputDecoration(hintText: 'مثلاً ۱۴۰۵-۰۰۰۱ یا بخشی از نام'),
            ),
          ),
          const SizedBox(width: 8),
          GlassButton(expand: false, height: 52, label: 'جستجو', onPressed: () => _open(_manual.text)),
        ]),
      ],
    );
  }
}

class _Camera extends StatefulWidget {
  final Future<bool> Function(String) onCode;
  const _Camera({required this.onCode});

  @override
  State<_Camera> createState() => _CameraState();
}

class _CameraState extends State<_Camera> with WidgetsBindingObserver {
  MobileScannerController _c = _newController();
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);
  bool _torch = false;
  bool _handling = false;
  // کاربر با خطای «عدم مجوز» به تنظیمات گوشی رفته است؟
  bool _leftWhileDenied = false;

  static MobileScannerController _newController() => MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        formats: const [BarcodeFormat.qrCode],
        facing: CameraFacing.back,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _c.dispose();
    super.dispose();
  }

  bool get _denied => _c.value.error?.errorCode == MobileScannerErrorCode.permissionDenied;

  /// کنترلر جدید می‌سازد. لازم است چون mobile_scanner بعد از خطای «عدم مجوز»
  /// با همان کنترلر دیگر دوباره start نمی‌کند (حتی بعد از دادن مجوز در تنظیمات).
  void _recreate() {
    if (!mounted) return;
    final old = _c;
    setState(() {
      _c = _newController();
      _torch = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        old.dispose();
      } catch (_) {}
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      // پنجره‌ی مجوز فقط inactive می‌کند؛ paused یعنی کاربر از برنامه بیرون رفته (مثلاً تنظیمات)
      _leftWhileDenied = _denied;
    } else if (state == AppLifecycleState.resumed && _leftWhileDenied) {
      _leftWhileDenied = false;
      _recreate();
    }
  }

  Future<void> _startIfStopped() async {
    final v = _c.value;
    if (!mounted || !v.isInitialized || v.isRunning || v.error != null) return;
    try {
      await _c.start();
    } catch (_) {}
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling || capture.barcodes.isEmpty) return;
    final v = capture.barcodes.first.rawValue;
    if (v == null || v.isEmpty) return;
    final now = DateTime.now();
    if (now.difference(_last).inSeconds < 2) return; // جلوگیری از بازشدن چندباره
    _last = now;
    _handling = true;
    try {
      try {
        await _c.stop();
      } catch (_) {}
      await widget.onCode(v);
    } finally {
      _handling = false;
      await _startIfStopped();
    }
  }

  String _errorText(MobileScannerException e) {
    switch (e.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return 'برنامه اجازه‌ی استفاده از دوربین را ندارد.\nتنظیمات گوشی ← برنامه‌ها ← انبار پارچه‌سرا ← مجوزها ← دوربین را «مجاز» کنید و به برنامه برگردید.';
      case MobileScannerErrorCode.unsupported:
        return 'این گوشی از اسکن با دوربین پشتیبانی نمی‌کند. کد را دستی بنویسید.';
      default:
        return 'اتصال به دوربین انجام نشد.\nدوربین ممکن است در برنامه‌ی دیگری باز باشد؛ آن را ببندید و «تلاش دوباره» را بزنید.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      MobileScanner(
        key: ObjectKey(_c),
        controller: _c,
        fit: BoxFit.cover,
        onDetect: _onDetect,
        errorBuilder: (context, error, child) => Container(
          color: const Color(0xFF1C1917),
          padding: const EdgeInsets.all(20),
          alignment: Alignment.center,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 40),
              const SizedBox(height: 10),
              Text(_errorText(error), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.8)),
              const SizedBox(height: 10),
              // جزئیات فنی خطا (برای عیب‌یابی)
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 10)),
              ),
              const SizedBox(height: 14),
              GlassButton(expand: false, height: 44, light: true, icon: Icons.refresh, label: 'تلاش دوباره', onPressed: _recreate),
            ]),
          ),
        ),
      ),
      Center(child: Container(width: 200, height: 200, decoration: BoxDecoration(border: Border.all(color: Colors.white.withAlpha(230), width: 3), borderRadius: BorderRadius.circular(28)))),
      Positioned(
        bottom: 14,
        left: 14,
        child: GlassCircleButton(
          size: 48,
          light: true,
          icon: _torch ? Icons.flash_on : Icons.flash_off,
          tooltip: 'چراغ قوه',
          onPressed: () async {
            try {
              await _c.toggleTorch();
              if (mounted) setState(() => _torch = !_torch);
            } catch (_) {}
          },
        ),
      ),
    ]);
  }
}
