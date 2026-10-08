import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../store.dart';
import '../utils.dart';
import '../widgets.dart';
import 'fabric_form_page.dart';
import 'qr_page.dart';
import 'transaction_page.dart';

class FabricDetailPage extends StatelessWidget {
  final String fabricId;
  const FabricDetailPage({super.key, required this.fabricId});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final f = store.byId(fabricId);
    if (f == null) {
      return Scaffold(appBar: AppBar(), body: const EmptyState(Icons.search_off, 'این کالا پیدا نشد.'));
    }
    final history = store.transactions.where((t) => t.fabricId == f.id).take(8).toList();

    Widget row(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Icon(icon, size: 18, color: const Color(0xFF78716C)),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Color(0xFF78716C), fontSize: 12)),
            const Spacer(),
            Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
          ]),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('جزئیات کالا', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(tooltip: 'ویرایش', icon: const Icon(Icons.edit_outlined), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FabricFormPage(initial: f)))),
          IconButton(tooltip: 'لیبل QR', icon: const Icon(Icons.qr_code_2), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => QrPage(fabricId: f.id)))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Row(children: [
            FabricAvatar(f, size: 64),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('کد ${toFa(f.code)}', style: const TextStyle(color: Color(0xFF78716C), fontSize: 12)),
              ]),
            ),
            f.archived ? const Chip(label: Text('بایگانی‌شده')) : StatusChip(f.status),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: kBrand, borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              const Text('موجودی', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Text('${faNum(f.meters)} ${f.unit}', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('ارزش: ${store.money(f.meters * f.pricePerMeter)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 12),
          if (!f.archived)
            Row(children: [
              Expanded(child: GlassButton(color: Colors.green.shade700, height: 48, icon: Icons.arrow_downward, label: 'ورود', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TransactionPage(fabricId: f.id, initialType: 'ورود'))))),
              const SizedBox(width: 10),
              Expanded(child: GlassButton(color: Colors.red.shade700, height: 48, icon: Icons.arrow_upward, label: 'خروج', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TransactionPage(fabricId: f.id, initialType: 'خروج'))))),
            ]),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7E5E4))),
            child: Column(children: [
              row(Icons.payments_outlined, 'قیمت هر ${f.unit}', store.money(f.pricePerMeter)),
              const Divider(height: 1),
              row(Icons.category_outlined, 'دسته', f.category),
              const Divider(height: 1),
              row(Icons.palette_outlined, 'رنگ', f.color),
              const Divider(height: 1),
              row(Icons.straighten, 'عرض', '${toFa(f.widthCm)} سانتی‌متر'),
              const Divider(height: 1),
              row(Icons.place_outlined, 'موقعیت در انبار', f.location),
              if (f.supplier != null) ...[const Divider(height: 1), row(Icons.local_shipping_outlined, 'تأمین‌کننده', f.supplier!)],
              const Divider(height: 1),
              row(Icons.notifications_active_outlined, 'حد هشدار', '${toFa(f.minMetersAlert ?? defaultMinAlert(f.byTaqeh))} ${f.unit}'),
            ]),
          ),
          if (f.description != null && f.description!.isNotEmpty) ...[
            const SectionTitle('توضیحات'),
            Text(f.description!, style: const TextStyle(height: 1.9, fontSize: 13)),
          ],
          const SectionTitle('آخرین تراکنش‌های این کالا'),
          if (history.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('تراکنشی ثبت نشده.', style: TextStyle(color: Color(0xFF78716C)))),
          for (final t in history) TxTile(t),
          const SizedBox(height: 12),
          GlassButton(
            light: true,
            height: 48,
            onPressed: () async {
              final wasArchived = f.archived;
              await store.toggleArchive(f);
              if (context.mounted) {
                toast(context, wasArchived ? 'کالا از بایگانی بیرون آمد.' : 'کالا بایگانی شد؛ سابقه‌اش حفظ است.');
                if (!wasArchived) Navigator.of(context).pop();
              }
            },
            icon: f.archived ? Icons.unarchive_outlined : Icons.archive_outlined,
            label: f.archived ? 'بازگرداندن از بایگانی' : 'بایگانی کالا',
          ),
        ],
      ),
    );
  }
}
