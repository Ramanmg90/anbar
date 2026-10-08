import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../store.dart';
import '../utils.dart';
import '../widgets.dart';
import 'catalog_screen.dart';
import 'fabric_form_page.dart';
import 'transaction_page.dart';

class HomeScreen extends StatelessWidget {
  final void Function(int) onGoto;
  const HomeScreen({super.key, required this.onGoto});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final items = store.active;
    final totalMeters = items.fold<double>(0, (s, f) => s + f.meters);
    final totalValue = items.fold<double>(0, (s, f) => s + f.meters * f.pricePerMeter);
    final low = items.where((f) => f.status != 'موجود').toList()..sort((a, b) => a.meters.compareTo(b.meters));
    final recent = store.transactions.take(5).toList();
    final first = store.userName.split(' ').first;

    void openTx(String type) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TransactionPage(initialType: type)));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, kNavSpace + 70),
      children: [
        Text('سلام $first 👋', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: StatCard(label: 'نوع کالا', value: faNum(items.length), icon: Icons.inventory_2_outlined)),
          const SizedBox(width: 10),
          Expanded(child: StatCard(label: 'مجموع متراژ', value: '${faNum(totalMeters)} متر', icon: Icons.straighten)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: StatCard(label: 'ارزش انبار', value: store.money(totalValue), icon: Icons.payments_outlined)),
          const SizedBox(width: 10),
          Expanded(child: StatCard(label: 'کالای رو به اتمام', value: faNum(low.length), icon: Icons.warning_amber_rounded, color: low.isEmpty ? Colors.green.shade700 : Colors.red.shade700)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: GlassButton(color: Colors.green.shade700, height: 48, icon: Icons.arrow_downward, label: 'ورود', onPressed: () => openTx('ورود'))),
          const SizedBox(width: 8),
          Expanded(child: GlassButton(color: Colors.red.shade700, height: 48, icon: Icons.arrow_upward, label: 'خروج', onPressed: () => openTx('خروج'))),
          const SizedBox(width: 8),
          Expanded(child: GlassButton(light: true, height: 48, icon: Icons.qr_code_scanner, label: 'اسکن', onPressed: () => onGoto(2))),
        ]),
        const SizedBox(height: 8),
        GlassButton(
          light: true,
          height: 48,
          icon: Icons.add,
          label: 'افزودن پارچه جدید',
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FabricFormPage())),
        ),
        if (low.isNotEmpty) ...[
          SectionTitle('نیازمند سفارش مجدد', trailing: TextButton(onPressed: () => onGoto(1), child: const Text('همه کالاها'))),
          for (final f in low.take(5))
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE7E5E4))),
              child: ListTile(
                onTap: () => openFabric(context, f.id),
                leading: FabricAvatar(f, size: 42),
                title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                subtitle: Text('کد ${toFa(f.code)}', style: const TextStyle(fontSize: 11)),
                trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${faNum(f.meters)} متر', style: TextStyle(fontWeight: FontWeight.w800, color: statusColor(f.status))),
                  StatusChip(f.status),
                ]),
              ),
            ),
        ],
        SectionTitle('آخرین تراکنش‌ها', trailing: TextButton(onPressed: () => onGoto(3), child: const Text('همه'))),
        if (recent.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: EmptyState(Icons.receipt_long_outlined, 'هنوز تراکنشی ثبت نشده.\nاولین کالا را اضافه کنید یا از فایل وارد کنید.'))
        else
          for (final t in recent) TxTile(t),
      ],
    );
  }
}
