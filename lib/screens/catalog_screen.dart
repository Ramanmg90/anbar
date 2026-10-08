import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../store.dart';
import '../utils.dart';
import '../widgets.dart';
import 'fabric_detail_page.dart';
import 'fabric_form_page.dart';

Future<void> openFabric(BuildContext context, String id) {
  return Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => FabricDetailPage(fabricId: id)));
}

const _filters = ['همه', 'کتان', 'مخمل', 'کرپ', 'لینن', 'ساتن', 'سایر', 'کمبود', 'موجود', 'بایگانی'];

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String _query = '';
  String _filter = 'همه';

  bool _match(Fabric f, String q) => q.isEmpty || normalizeKey('${f.name}${f.code}${f.color}${f.location}${f.supplier ?? ''}').contains(q);

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final q = normalizeKey(_query);
    final list = store.fabrics.where((f) {
      if (_filter == 'بایگانی') return f.archived && _match(f, q);
      if (f.archived) return false;
      if (!_match(f, q)) return false;
      if (_filter == 'همه') return true;
      if (_filter == 'کمبود') return f.status != 'موجود';
      if (_filter == 'موجود') return f.status == 'موجود';
      return f.category == _filter;
    }).toList();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: const InputDecoration(hintText: 'جستجو: نام، کد، رنگ، موقعیت…', prefixIcon: Icon(Icons.search)),
        ),
      ),
      SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => ChoiceChip(
            label: Text(_filters[i]),
            selected: _filter == _filters[i],
            onSelected: (_) => setState(() => _filter = _filters[i]),
          ),
        ),
      ),
      Expanded(
        child: list.isEmpty
            ? EmptyState(
                Icons.search_off,
                store.fabrics.isEmpty ? 'انبار خالی است.\nبا دکمه‌ی «+» اولین پارچه را اضافه کنید یا از «بیشتر ← ورود از فایل» استفاده کنید.' : 'کالایی با این مشخصات پیدا نشد.',
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, kNavSpace + 130),
                itemCount: list.length,
                itemBuilder: (_, i) => _FabricTile(list[i]),
              ),
      ),
    ]);
  }
}

class _FabricTile extends StatelessWidget {
  final Fabric f;
  const _FabricTile(this.f);

  @override
  Widget build(BuildContext context) {
    final store = context.read<AppStore>();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7E5E4))),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => openFabric(context, f.id),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            FabricAvatar(f),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 3),
                Text('${toFa(f.code)} · ${f.category} · ${f.color}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF78716C))),
                const SizedBox(height: 3),
                Text(store.money(f.pricePerMeter), style: const TextStyle(fontSize: 11, color: Color(0xFF57534E))),
              ]),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${faNum(f.meters)} م', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: statusColor(f.status))),
              const SizedBox(height: 4),
              f.archived ? const Text('بایگانی', style: TextStyle(fontSize: 11, color: Color(0xFF78716C))) : StatusChip(f.status),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// دکمه‌ی افزودن کالا (برای صفحه‌های دیگر)
void openAddFabric(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FabricFormPage()));
}
