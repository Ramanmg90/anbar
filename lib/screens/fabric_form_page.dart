import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../store.dart';
import '../utils.dart';
import '../widgets.dart';

/// افزودن کالای جدید؛ اگر [initial] داده شود، ویرایش همان کالا (موجودی فقط با ورود/خروج عوض می‌شود).
class FabricFormPage extends StatefulWidget {
  final Fabric? initial;
  const FabricFormPage({super.key, this.initial});

  @override
  State<FabricFormPage> createState() => _FabricFormPageState();
}

class _FabricFormPageState extends State<FabricFormPage> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _color;
  late final TextEditingController _meters;
  late final TextEditingController _price;
  late final TextEditingController _width;
  late final TextEditingController _min;
  late final TextEditingController _location;
  late final TextEditingController _supplier;
  late final TextEditingController _desc;
  late String _category;
  bool _saving = false;

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final f = widget.initial;
    final store = context.read<AppStore>();
    _name = TextEditingController(text: f?.name ?? '');
    _code = TextEditingController(text: f?.code ?? '۱۴۰۵-${toFa(1000 + Random().nextInt(9000))}');
    _color = TextEditingController(text: f?.color ?? '');
    _meters = TextEditingController(text: '30');
    _price = TextEditingController(text: f == null ? '' : toFa(fmtNum(store.showPrice(f.pricePerMeter))));
    _width = TextEditingController(text: toFa(f?.widthCm ?? 150));
    _min = TextEditingController(text: toFa(f?.minMetersAlert ?? 15));
    _location = TextEditingController(text: f?.location ?? '');
    _supplier = TextEditingController(text: f?.supplier ?? '');
    _desc = TextEditingController(text: f?.description ?? '');
    _category = f?.category ?? 'کتان';
  }

  @override
  void dispose() {
    for (final c in [_name, _code, _color, _meters, _price, _width, _min, _location, _supplier, _desc]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'این فیلد لازم است' : null;
  String? _numReq(String? v) {
    final n = parseNum(v ?? '');
    return (n == null || n <= 0) ? 'عدد معتبر وارد کنید' : null;
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate() || _saving) return;
    final store = context.read<AppStore>();
    final f = widget.initial;
    if (store.codeExists(_code.text, exceptId: f?.id)) {
      toast(context, 'این کد قبلاً برای کالای دیگری ثبت شده است.', error: true);
      return;
    }
    setState(() => _saving = true);
    final minAlert = (parseNum(_min.text) ?? 15).round();
    final price = store.toRials(parseNum(_price.text)!);
    final width = (parseNum(_width.text) ?? 150).round();
    final loc = _location.text.trim().isEmpty ? 'نامشخص' : _location.text.trim();
    final col = _color.text.trim().isEmpty ? 'استاندارد' : _color.text.trim();
    final sup = _supplier.text.trim().isEmpty ? null : _supplier.text.trim();
    final desc = _desc.text.trim().isEmpty ? null : _desc.text.trim();
    final nav = Navigator.of(context);

    if (f != null) {
      await store.updateFabric(Fabric(
        id: f.id,
        code: _code.text.trim(),
        name: _name.text.trim(),
        category: _category,
        status: computeStatus(f.meters, minAlert),
        meters: f.meters,
        pricePerMeter: price,
        color: col,
        widthCm: width,
        location: loc,
        lastCountDate: f.lastCountDate,
        image: f.image,
        images: f.images,
        description: desc,
        minMetersAlert: minAlert,
        supplier: sup,
        archived: f.archived,
      ));
    } else {
      final m = parseNum(_meters.text) ?? 0;
      await store.addFabric(Fabric(
        id: 'fab-${DateTime.now().microsecondsSinceEpoch}',
        code: _code.text.trim(),
        name: _name.text.trim(),
        category: _category,
        status: computeStatus(m, minAlert),
        meters: m,
        pricePerMeter: price,
        color: col,
        widthCm: width,
        location: loc,
        description: desc,
        minMetersAlert: minAlert,
        supplier: sup,
      ));
    }
    if (!mounted) return;
    toast(context, _editing ? 'تغییرات ذخیره شد.' : 'کالا در انبار ثبت شد.');
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    Widget field(String label, TextEditingController c, {String? Function(String?)? validator, TextInputType? type, int lines = 1, String? hint}) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: c,
            validator: validator,
            keyboardType: type,
            maxLines: lines,
            decoration: InputDecoration(labelText: label, hintText: hint),
          ),
        );
    const numKb = TextInputType.numberWithOptions(decimal: true);

    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'ویرایش کالا' : 'افزودن پارچه جدید', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
      body: Form(
        key: _key,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            field('نام پارچه', _name, validator: _req, hint: 'مثلاً مخمل کبریتی زرشکی'),
            field('کد کالا', _code, validator: _req),
            const Padding(padding: EdgeInsets.only(bottom: 6), child: Text('دسته', style: TextStyle(fontSize: 12, color: Color(0xFF78716C)))),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [for (final c in kCategories) ChoiceChip(label: Text(c), selected: _category == c, onSelected: (_) => setState(() => _category = c))],
            ),
            const SizedBox(height: 14),
            field('رنگ', _color),
            if (!_editing) field('موجودی اولیه (متر)', _meters, type: numKb, validator: (v) => parseNum(v ?? '') == null ? 'عدد معتبر وارد کنید' : null),
            field('قیمت هر متر (${store.unit})', _price, type: numKb, validator: _numReq),
            Row(children: [
              Expanded(child: field('عرض (سانتی‌متر)', _width, type: numKb, validator: _numReq)),
              const SizedBox(width: 10),
              Expanded(child: field('حد هشدار (متر)', _min, type: numKb, validator: _numReq)),
            ]),
            field('موقعیت در انبار', _location, hint: 'مثلاً قفسه ب-۳'),
            field('تأمین‌کننده', _supplier),
            field('توضیحات', _desc, lines: 3),
            if (_editing)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: const Color(0xFFF5F5F4), borderRadius: BorderRadius.circular(14)),
                child: Text('موجودی فعلی (${faNum(widget.initial!.meters)} متر) از اینجا تغییر نمی‌کند؛ برای اصلاح آن «ثبت ورود/خروج» را بزنید تا در تاریخچه بماند.', style: const TextStyle(fontSize: 12, height: 1.8, color: Color(0xFF57534E))),
              ),
            GlassButton(
              onPressed: _saving ? null : _save,
              icon: _editing ? Icons.save_outlined : Icons.add,
              label: _editing ? 'ذخیره تغییرات' : 'ثبت کالا در انبار',
            ),
          ],
        ),
      ),
    );
  }
}
