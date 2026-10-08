import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../store.dart';
import '../utils.dart';
import '../widgets.dart';

class TransactionPage extends StatefulWidget {
  final String? fabricId;
  final String initialType;
  const TransactionPage({super.key, this.fabricId, this.initialType = 'ورود'});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  String? _fabricId;
  late String _type;
  final _meters = TextEditingController(text: '10');
  final _price = TextEditingController();
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType == 'خروج' ? 'خروج' : 'ورود';
    _fabricId = widget.fabricId;
    final f = _fabricId == null ? null : context.read<AppStore>().byId(_fabricId!);
    if (f != null) _setPriceFrom(f);
  }

  @override
  void dispose() {
    _meters.dispose();
    _price.dispose();
    _note.dispose();
    super.dispose();
  }

  void _setPriceFrom(Fabric f) {
    final store = context.read<AppStore>();
    _price.text = toFa(fmtNum(store.showPrice(f.pricePerMeter)));
  }

  Future<void> _pick() async {
    final store = context.read<AppStore>();
    final f = await showModalBottomSheet<Fabric>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _FabricPicker(items: store.active),
    );
    if (f != null) {
      setState(() => _fabricId = f.id);
      _setPriceFrom(f);
    }
  }

  void _bump(double d) {
    final cur = parseNum(_meters.text) ?? 0;
    final n = (cur + d) < 0 ? 0.0 : round2(cur + d);
    _meters.text = toFa(fmtNum(n));
    setState(() {});
  }

  Future<void> _submit() async {
    final store = context.read<AppStore>();
    final f = _fabricId == null ? null : store.byId(_fabricId!);
    if (f == null) return toast(context, 'ابتدا کالا را انتخاب کنید.', error: true);
    final m = parseNum(_meters.text) ?? 0;
    if (m <= 0) return toast(context, 'متراژ را وارد کنید.', error: true);
    final price = parseNum(_price.text);
    if (price == null || price <= 0) return toast(context, 'قیمت را وارد کنید.', error: true);
    final isOut = _type == 'خروج';
    final nav = Navigator.of(context);
    setState(() => _busy = true);
    final err = await store.applyStock(f.id, isOut ? -m : m, _note.text.trim().isEmpty ? (isOut ? 'خروج از انبار' : 'ورود به انبار') : _note.text.trim(), price: store.toRials(price));
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) return toast(context, err, error: true);
    HapticFeedback.mediumImpact();
    toast(context, isOut ? 'خروج کالا ثبت شد.' : 'ورود کالا ثبت شد.');
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final f = _fabricId == null ? null : store.byId(_fabricId!);
    final m = parseNum(_meters.text) ?? 0;
    final isOut = _type == 'خروج';
    final after = f == null ? null : (isOut ? f.meters - m : f.meters + m);
    final tooMuch = f != null && isOut && m > f.meters;

    return Scaffold(
      appBar: AppBar(title: const Text('ثبت ورود / خروج', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'ورود', label: Text('ورود'), icon: Icon(Icons.arrow_downward)),
              ButtonSegment(value: 'خروج', label: Text('خروج'), icon: Icon(Icons.arrow_upward)),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _pick,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7E5E4))),
              child: f == null
                  ? const Row(children: [Icon(Icons.search), SizedBox(width: 10), Expanded(child: Text('انتخاب کالا…')), Icon(Icons.expand_more)])
                  : Row(children: [
                      FabricAvatar(f, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(f.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text('کد ${toFa(f.code)} · موجودی ${faNum(f.meters)} متر', style: const TextStyle(fontSize: 11, color: Color(0xFF78716C))),
                        ]),
                      ),
                      const Icon(Icons.expand_more),
                    ]),
            ),
          ),
          const SizedBox(height: 16),
          const Text('متراژ', style: TextStyle(fontSize: 12, color: Color(0xFF78716C))),
          const SizedBox(height: 6),
          Row(children: [
            IconButton.filledTonal(onPressed: () => _bump(-1), icon: const Icon(Icons.remove)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _meters,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(onPressed: () => _bump(1), icon: const Icon(Icons.add)),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [for (final p in [5, 10, 25, 50]) ActionChip(label: Text('+${toFa(p)}'), onPressed: () => _bump(p.toDouble()))]),
          if (f != null && m > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                tooMuch ? 'موجودی کافی نیست؛ فقط ${faNum(f.meters)} متر در انبار است.' : 'موجودی پس از ثبت: ${faNum(after!)} متر',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: tooMuch ? Colors.red.shade700 : Colors.green.shade800),
              ),
            ),
          const SizedBox(height: 16),
          TextField(controller: _price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'قیمت هر متر (${store.unit})')),
          const SizedBox(height: 12),
          TextField(controller: _note, decoration: const InputDecoration(labelText: 'توضیح (اختیاری)', hintText: 'مثلاً: فروش به آقای رضایی')),
          const SizedBox(height: 20),
          GlassButton(
            color: isOut ? Colors.red.shade700 : Colors.green.shade700,
            onPressed: (_busy || tooMuch) ? null : _submit,
            icon: Icons.check,
            label: isOut ? 'ثبت خروج' : 'ثبت ورود',
          ),
        ],
      ),
    );
  }
}

class _FabricPicker extends StatefulWidget {
  final List<Fabric> items;
  const _FabricPicker({required this.items});

  @override
  State<_FabricPicker> createState() => _FabricPickerState();
}

class _FabricPickerState extends State<_FabricPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = normalizeKey(_q);
    final list = widget.items.where((f) => q.isEmpty || normalizeKey('${f.name}${f.code}${f.color}').contains(q)).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(autofocus: true, onChanged: (v) => setState(() => _q = v), decoration: const InputDecoration(hintText: 'جستجوی کالا…', prefixIcon: Icon(Icons.search))),
        ),
        Expanded(
          child: list.isEmpty
              ? const EmptyState(Icons.search_off, 'کالایی پیدا نشد.')
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final f = list[i];
                    return ListTile(
                      leading: FabricAvatar(f, size: 40),
                      title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      subtitle: Text('کد ${toFa(f.code)}', style: const TextStyle(fontSize: 11)),
                      trailing: Text('${faNum(f.meters)} م', style: TextStyle(fontWeight: FontWeight.w800, color: statusColor(f.status))),
                      onTap: () => Navigator.of(context).pop(f),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
