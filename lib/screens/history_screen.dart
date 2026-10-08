import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../store.dart';
import '../utils.dart';
import '../widgets.dart';

const _filters = ['همه', 'ورودی', 'خروجی', 'اصلاح', 'لغوشده'];
const _typeOf = {'ورودی': 'ورود', 'خروجی': 'خروج', 'اصلاح': 'اصلاح', 'لغوشده': 'لغو'};

Future<void> showReverseDialog(BuildContext context, Tx tx) async {
  final store = context.read<AppStore>();
  final ctrl = TextEditingController();
  String? error;
  final f = store.byId(tx.fabricId);
  final back = round2(-tx.metersChange);
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: const Text('لغو تراکنش', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${tx.fabricName}\n${tx.type} ${tx.metersChange > 0 ? '+' : ''}${faNum(tx.metersChange)} ${tx.unit} — ${tx.timestamp}، ${tx.dateStr}', style: const TextStyle(fontSize: 12, height: 1.8)),
            const SizedBox(height: 10),
            Text(
              'تراکنش اصلی پاک نمی‌شود؛ یک تراکنش جبرانی (${back > 0 ? '+' : ''}${faNum(back)} ${tx.unit}) ثبت می‌شود.${f == null ? '' : ' موجودی پس از لغو: ${faNum(f.meters + back)} ${f.unit}.'}',
              style: const TextStyle(fontSize: 12, height: 1.8, color: Color(0xFF57534E)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              onChanged: (_) => setS(() => error = null),
              decoration: InputDecoration(labelText: 'دلیل لغو (الزامی)', hintText: 'مثلاً: به‌جای ۴ متر، ۴۸ متر وارد شد', errorText: error),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('انصراف')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () async {
              final err = await store.reverse(tx, ctrl.text);
              if (err != null) {
                setS(() => error = err);
              } else if (ctx.mounted) {
                Navigator.of(ctx).pop();
                if (context.mounted) toast(context, 'تراکنش لغو شد و رکورد جبرانی ثبت گردید.');
              }
            },
            child: const Text('لغو تراکنش'),
          ),
        ],
      ),
    ),
  );
  ctrl.dispose();
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _query = '';
  String _filter = 'همه';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final q = normalizeKey(_query);
    final list = store.transactions.where((t) {
      if (_filter != 'همه' && t.type != _typeOf[_filter]) return false;
      return q.isEmpty || normalizeKey('${t.fabricName}${t.fabricCode}${t.note}${t.user ?? ''}').contains(q);
    }).toList();

    final today = fullDate();
    final live = store.transactions.where((t) => t.dateStr == today && t.reversedBy == null && t.reverses == null);
    final inToday = txTotals(live.where((t) => t.type == 'ورود'), out: false);
    final outToday = txTotals(live.where((t) => t.type == 'خروج'), out: true);

    final items = <Object>[]; // String = سرتیتر تاریخ، Tx = تراکنش
    String? lastDate;
    for (final t in list) {
      if (t.dateStr != lastDate) {
        items.add(t.dateStr);
        lastDate = t.dateStr;
      }
      items.add(t);
    }

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Row(children: [
          Expanded(child: StatCard(label: 'ورود امروز', value: inToday, icon: Icons.arrow_downward, color: Colors.green.shade700)),
          const SizedBox(width: 10),
          Expanded(child: StatCard(label: 'خروج امروز', value: outToday, icon: Icons.arrow_upward, color: Colors.red.shade700)),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: TextField(onChanged: (v) => setState(() => _query = v), decoration: const InputDecoration(hintText: 'جستجو در تاریخچه…', prefixIcon: Icon(Icons.search))),
      ),
      SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => ChoiceChip(label: Text(_filters[i]), selected: _filter == _filters[i], onSelected: (_) => setState(() => _filter = _filters[i])),
        ),
      ),
      Expanded(
        child: items.isEmpty
            ? const EmptyState(Icons.receipt_long_outlined, 'تراکنشی پیدا نشد.')
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, kNavSpace + 70),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final it = items[i];
                  if (it is String) return Padding(padding: const EdgeInsets.fromLTRB(4, 12, 4, 8), child: Text(it, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF78716C))));
                  final t = it as Tx;
                  return TxTile(t, onReverse: () => showReverseDialog(context, t));
                },
              ),
      ),
    ]);
  }
}
