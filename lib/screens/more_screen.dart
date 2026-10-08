import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../share_util.dart';
import '../store.dart';
import '../utils.dart';
import '../widgets.dart';
import 'import_page.dart';
import 'reports_page.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  Future<void> _backup(BuildContext context, AppStore store) async {
    try {
      await shareTextFile('robofabric-backup-${isoDay(DateTime.now())}.json', store.backupJson(), subject: 'پشتیبان RoboFabric', mime: 'application/json');
    } catch (_) {
      if (context.mounted) toast(context, 'ساخت فایل پشتیبان انجام نشد.', error: true);
    }
  }

  Future<void> _restore(BuildContext context, AppStore store) async {
    final text = await pickTextFile();
    if (text == null) return;
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('بازیابی پشتیبان', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: const Text('با بازیابی، کل داده‌ی فعلی با محتوای فایل جایگزین می‌شود. ادامه می‌دهید؟\n\nپیشنهاد: اول از داده‌ی فعلی پشتیبان بگیرید.', style: TextStyle(height: 1.8, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('انصراف')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700), onPressed: () => Navigator.of(ctx).pop(true), child: const Text('جایگزین کن')),
        ],
      ),
    );
    if (ok != true) return;
    final err = await store.restore(text);
    if (!context.mounted) return;
    toast(context, err ?? 'پشتیبان بازیابی شد.', error: err != null);
  }

  Future<void> _editName(BuildContext context, AppStore store) async {
    final c = TextEditingController(text: store.userName);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('نام کاربر', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(hintText: 'نام و نام خانوادگی')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(c.text), child: const Text('ذخیره')),
        ],
      ),
    );
    c.dispose();
    if (v != null) await store.setUserName(v);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    Widget tile(IconData icon, String title, String? sub, VoidCallback onTap) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7E5E4))),
          child: ListTile(
            onTap: onTap,
            leading: Icon(icon, color: kBrand),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: sub == null ? null : Text(sub, style: const TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.chevron_left),
          ),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, kNavSpace + 20),
      children: [
        const Text('بیشتر', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        tile(Icons.person_outline, 'کاربر', store.userName, () => _editName(context, store)),
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7E5E4))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('واحد پول', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [ButtonSegment(value: 'IRT', label: Text('تومان')), ButtonSegment(value: 'IRR', label: Text('ریال'))],
                selected: {store.currency},
                onSelectionChanged: (s) => store.setCurrency(s.first),
              ),
            ),
            const SizedBox(height: 8),
            const Text('فقط نمایش و ورودی قیمت عوض می‌شود؛ داده‌ها همیشه به ریال ذخیره می‌شوند.', style: TextStyle(fontSize: 11, color: Color(0xFF78716C))),
          ]),
        ),
        tile(Icons.bar_chart, 'گزارش‌ها', 'موجودی لحظه‌ای و گزارش بازه‌ای', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportsPage()))),
        tile(Icons.table_view, 'ورود کالاها از فایل CSV', 'لیست کالاهای اکسل را یک‌جا وارد کنید', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ImportPage()))),
        tile(Icons.cloud_upload_outlined, 'پشتیبان‌گیری', 'فایل پشتیبان را در تلگرام/گوگل‌درایو ذخیره کنید', () => _backup(context, store)),
        tile(Icons.settings_backup_restore, 'بازیابی از فایل پشتیبان', 'جایگزین کل داده‌ی فعلی می‌شود', () => _restore(context, store)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFDE68A))),
          child: const Text(
            'همه‌ی داده‌ها فقط روی همین گوشی ذخیره می‌شوند. اگر برنامه پاک شود یا گوشی عوض شود از بین می‌روند؛ هر چند وقت یک‌بار «پشتیبان‌گیری» بزنید و فایل را جای امنی بفرستید.',
            style: TextStyle(fontSize: 12, height: 1.9, color: Color(0xFF78350F)),
          ),
        ),
      ],
    );
  }
}
