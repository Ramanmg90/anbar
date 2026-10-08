import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic.dart';
import '../share_util.dart';
import '../store.dart';
import '../utils.dart';
import '../widgets.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  List<List<String>>? _rows;
  bool _busy = false;

  Future<void> _pick() async {
    final text = await pickTextFile();
    if (text == null) return;
    setState(() => _rows = parseCsv(text));
  }

  Future<void> _sample() async {
    try {
      await shareTextFile('نمونه-ورود-کالا.csv', kSampleCsv, mime: 'text/csv');
    } catch (_) {
      if (mounted) toast(context, 'ساخت فایل نمونه انجام نشد.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final factor = store.currency == 'IRT' ? 10 : 1;
    final result = _rows == null ? null : buildImport(_rows!, store.fabrics.map((f) => f.code).toList(), factor);
    final good = result?.good ?? const [];
    final bad = result?.bad ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('ورود کالاها از CSV', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF5F5F4), borderRadius: BorderRadius.circular(16)),
            child: Text(
              'در اکسل فایل را با «Save As ← CSV UTF-8» ذخیره کنید. سطر اول باید عنوان ستون‌ها باشد.\n'
              'ستون‌های لازم: نام، کد، متراژ، قیمت. اختیاری: دسته، رنگ، عرض، موقعیت، تأمین‌کننده، حد هشدار، توضیحات.\n'
              'قیمت‌های فایل به ${store.unit} فرض می‌شوند (طبق تنظیمات). کدهای تکراری و ردیف‌های ناقص وارد نمی‌شوند و پایین‌تر فهرست می‌شوند.',
              style: const TextStyle(fontSize: 12, height: 1.9, color: Color(0xFF44403C)),
            ),
          ),
          TextButton.icon(onPressed: _sample, icon: const Icon(Icons.download), label: const Text('دریافت فایل نمونه')),
          const SizedBox(height: 4),
          GlassButton(light: true, onPressed: _pick, icon: Icons.folder_open, label: _rows == null ? 'انتخاب فایل CSV' : 'انتخاب فایل دیگر'),
          if (result != null && result.missing.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(14)),
              child: Text('ستون لازم پیدا نشد: ${result.missing.join('، ')}', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          if (result != null && result.missing.isEmpty) ...[
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: StatCard(label: 'آماده‌ی ورود', value: faNum(good.length), icon: Icons.check_circle_outline, color: Colors.green.shade700)),
              const SizedBox(width: 10),
              Expanded(child: StatCard(label: 'ردشده', value: faNum(bad.length), icon: Icons.error_outline, color: Colors.amber.shade800)),
            ]),
            if (bad.isNotEmpty) ...[
              const SectionTitle('ردیف‌های ردشده'),
              for (final b in bad.take(100))
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE7E5E4))),
                  child: Row(children: [Text('سطر ${toFa(b.line)}', style: const TextStyle(fontSize: 11, color: Color(0xFF78716C))), const Spacer(), Text(b.error ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))]),
                ),
            ],
            const SizedBox(height: 16),
            GlassButton(
              onPressed: (good.isEmpty || _busy)
                  ? null
                  : () async {
                      final nav = Navigator.of(context);
                      setState(() => _busy = true);
                      await store.importFabrics(good);
                      if (!mounted) return;
                      toast(context, '${faNum(good.length)} کالا وارد انبار شد.');
                      nav.pop();
                    },
              icon: Icons.check,
              label: good.isEmpty ? 'کالای قابل‌ورودی نیست' : 'ورود ${faNum(good.length)} کالا به انبار',
            ),
          ],
        ],
      ),
    );
  }
}
