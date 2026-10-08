import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic.dart';
import '../models.dart';
import '../share_util.dart';
import '../store.dart';
import '../utils.dart';
import '../widgets.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('گزارش‌ها', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          bottom: const TabBar(tabs: [Tab(text: 'موجودی لحظه‌ای'), Tab(text: 'گزارش بازه‌ای')]),
        ),
        body: const TabBarView(children: [_SnapshotTab(), _RangeTab()]),
      ),
    );
  }
}

class _SnapshotTab extends StatelessWidget {
  const _SnapshotTab();

  Future<void> _export(BuildContext context, List<Fabric> items) async {
    const head = ['نام', 'کد', 'دسته', 'رنگ', 'عرض', 'موجودی', 'واحد', 'قیمت هر واحد (ریال)', 'موقعیت', 'تأمین‌کننده', 'وضعیت', 'ارزش کل (ریال)'];
    final rows = [
      for (final f in items) [f.name, f.code, f.category, f.color, f.widthCm, f.meters, f.unit, f.pricePerMeter, f.location, f.supplier ?? '', f.status, (f.meters * f.pricePerMeter).round()],
    ];
    final csv = '\uFEFF${[head, ...rows].map((r) => r.map(csvCell).join(',')).join('\r\n')}';
    try {
      await shareTextFile('موجودی-انبار-${isoDay(DateTime.now())}.csv', csv, mime: 'text/csv');
    } catch (_) {
      if (context.mounted) toast(context, 'ساخت فایل انجام نشد.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final items = store.active;
    final totalValue = items.fold<double>(0, (s, f) => s + f.meters * f.pricePerMeter);
    final byCat = <String, List<Fabric>>{};
    for (final f in items) {
      byCat.putIfAbsent(f.category, () => []).add(f);
    }
    final low = items.where((f) => f.status != 'موجود').toList()..sort((a, b) => a.meters.compareTo(b.meters));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text('وضعیت انبار تا ${fullDate()}', style: const TextStyle(fontSize: 12, color: Color(0xFF78716C))),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: StatCard(label: 'نوع کالا', value: faNum(items.length), icon: Icons.inventory_2_outlined)),
          const SizedBox(width: 10),
          Expanded(child: StatCard(label: 'مجموع موجودی', value: stockTotals(items), icon: Icons.straighten)),
        ]),
        const SizedBox(height: 10),
        StatCard(label: 'ارزش کل انبار', value: store.money(totalValue), icon: Icons.payments_outlined),
        const SectionTitle('به تفکیک دسته'),
        for (final e in byCat.entries)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE7E5E4))),
            child: Row(children: [
              Expanded(child: Text('${e.key} (${toFa(e.value.length)} نوع)', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(stockTotals(e.value), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                Text(store.money(e.value.fold<double>(0, (s, f) => s + f.meters * f.pricePerMeter)), style: const TextStyle(fontSize: 11, color: Color(0xFF78716C))),
              ]),
            ]),
          ),
        if (low.isNotEmpty) ...[
          const SectionTitle('رو به اتمام'),
          for (final f in low)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE7E5E4))),
              child: Row(children: [
                Expanded(child: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                Text('${faNum(f.meters)} ${f.unitShort}', style: TextStyle(fontWeight: FontWeight.w800, color: statusColor(f.status))),
              ]),
            ),
        ],
        const SizedBox(height: 14),
        GlassButton(
          color: Colors.green.shade700,
          onPressed: items.isEmpty ? null : () => _export(context, items),
          icon: Icons.ios_share,
          label: 'خروجی CSV (اکسل)',
        ),
      ],
    );
  }
}

class _RangeTab extends StatefulWidget {
  const _RangeTab();

  @override
  State<_RangeTab> createState() => _RangeTabState();
}

class _RangeTabState extends State<_RangeTab> {
  late DateTime _from;
  late DateTime _to;
  GroupBy _by = GroupBy.category;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _to = DateTime(n.year, n.month, n.day);
    _from = _to.subtract(const Duration(days: 6));
  }

  Future<void> _pickDate(bool isFrom) async {
    final d = await showDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d == null) return;
    setState(() {
      final day = DateTime(d.year, d.month, d.day);
      if (isFrom) {
        _from = day;
        if (_to.isBefore(_from)) _to = _from;
      } else {
        _to = day;
        if (_from.isAfter(_to)) _from = _to;
      }
    });
  }

  void _preset(int days) {
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    setState(() {
      _to = today;
      _from = today.subtract(Duration(days: days));
    });
  }

  Future<void> _export(RangeReportData rep, AppStore store) async {
    final head = [kGroupLabels[_by]!, 'ورود (متر/تاقه)', 'خروج (متر/تاقه)', 'ارزش خروج (${store.unit})', 'تعداد تراکنش'];
    final rows = [for (final r in rep.rows) [r.key, r.inMeters, r.outMeters, store.showPrice(r.outValue.round()).round(), r.count]];
    final csv = '\uFEFF${[head, ...rows].map((r) => r.map(csvCell).join(',')).join('\r\n')}';
    try {
      await shareTextFile('گزارش-${isoDay(_from)}_${isoDay(_to)}.csv', csv, mime: 'text/csv');
    } catch (_) {
      if (mounted) toast(context, 'ساخت فایل انجام نشد.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final end = DateTime(_to.year, _to.month, _to.day, 23, 59, 59, 999);
    final rep = buildRangeReport(store.transactions, store.fabrics, _from, end, _by);

    Widget dateBtn(String label, DateTime d, bool isFrom) => Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
            onPressed: () => _pickDate(isFrom),
            child: Column(children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF78716C))),
              Text(shortJalali(d), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ]),
          ),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Row(children: [dateBtn('از تاریخ', _from, true), const SizedBox(width: 10), dateBtn('تا تاریخ', _to, false)]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          ActionChip(label: const Text('امروز'), onPressed: () => _preset(0)),
          ActionChip(label: const Text('۷ روز اخیر'), onPressed: () => _preset(6)),
          ActionChip(label: const Text('۳۰ روز اخیر'), onPressed: () => _preset(29)),
        ]),
        const SizedBox(height: 10),
        const Text('تفکیک بر اساس', style: TextStyle(fontSize: 11, color: Color(0xFF78716C))),
        const SizedBox(height: 4),
        Wrap(spacing: 8, children: [
          for (final g in GroupBy.values) ChoiceChip(label: Text(kGroupLabels[g]!), selected: _by == g, onSelected: (_) => setState(() => _by = g)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: StatCard(label: 'کل ورود', value: '${faNum(rep.inTotal)} م', icon: Icons.arrow_downward, color: Colors.green.shade700)),
          const SizedBox(width: 8),
          Expanded(child: StatCard(label: 'کل خروج', value: '${faNum(rep.outTotal)} م', icon: Icons.arrow_upward, color: Colors.red.shade700)),
        ]),
        const SizedBox(height: 8),
        StatCard(label: 'ارزش خروج', value: store.money(rep.outValue), icon: Icons.payments_outlined),
        const SizedBox(height: 8),
        if (rep.rows.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: EmptyState(Icons.inbox_outlined, 'در این بازه تراکنشی ثبت نشده است.'))
        else
          for (final r in rep.rows)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE7E5E4))),
              child: Row(children: [
                Expanded(child: Text(r.key, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('ورود ${faNum(r.inMeters)} · خروج ${faNum(r.outMeters)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  Text('${store.money(r.outValue)} · ${toFa(r.count)} تراکنش', style: const TextStyle(fontSize: 10, color: Color(0xFF78716C))),
                ]),
              ]),
            ),
        const SizedBox(height: 4),
        Text(
          'تراکنش‌های لغوشده و جبرانی‌شان در جمع حساب نمی‌شوند.${rep.undated > 0 ? ' ${toFa(rep.undated)} تراکنش قدیمی بدون زمان دقیق در گزارش نیامده‌اند.' : ''}',
          style: const TextStyle(fontSize: 10, color: Color(0xFF78716C), height: 1.8),
        ),
        const SizedBox(height: 10),
        GlassButton(
          color: Colors.green.shade700,
          onPressed: rep.rows.isEmpty ? null : () => _export(rep, store),
          icon: Icons.ios_share,
          label: 'خروجی CSV این گزارش',
        ),
      ],
    );
  }
}
