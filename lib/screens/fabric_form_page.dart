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
  late final TextEditingController _taqeh;
  late final TextEditingController _price;
  late final TextEditingController _width;
  late final TextEditingController _min;
  late final TextEditingController _location;
  late final TextEditingController _supplier;
  late final TextEditingController _desc;
  late String _category;
  bool _saving = false;
  bool _byTaqeh = false; // حالت ورود موجودی اولیه: false = متراژ، true = تاقه

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
    _taqeh = TextEditingController(text: toFa(1));
    _price = TextEditingController(text: f == null ? '' : toFa(fmtNum(store.showPrice(f.pricePerMeter))));
    _width = TextEditingController(text: toFa(f?.widthCm ?? 150));
    _byTaqeh = f?.byTaqeh ?? false;
    _min = TextEditingController(text: toFa(f?.minMetersAlert ?? defaultMinAlert(_byTaqeh)));
    _location = TextEditingController(text: f?.location ?? '');
    _supplier = TextEditingController(text: f?.supplier ?? '');
    _desc = TextEditingController(text: f?.description ?? '');
    _category = f?.category ?? 'کتان';
  }

  @override
  void dispose() {
    for (final c in [_name, _code, _color, _meters, _taqeh, _price, _width, _min, _location, _supplier, _desc]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'این فیلد لازم است' : null;
  String? _numReq(String? v) {
    final n = parseNum(v ?? '');
    return (n == null || n <= 0) ? 'عدد معتبر وارد کنید' : null;
  }

  /// موجودی اولیه: در حالت تاقه «تعداد تاقه»، در حالت متراژ «متر»
  double get _initialQty => parseNum(_byTaqeh ? _taqeh.text : _meters.text) ?? 0;

  String get _unitName => _byTaqeh ? 'تاقه' : 'متر';

  void _setMode(bool taqeh) {
    if (taqeh == _byTaqeh) return;
    setState(() {
      // اگر کاربر حد هشدار را دستی تغییر نداده، با حالت جدید عوض شود
      if (parseNum(_min.text)?.round() == defaultMinAlert(_byTaqeh)) {
        _min.text = toFa(defaultMinAlert(taqeh));
      }
      _byTaqeh = taqeh;
    });
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
    final minAlert = (parseNum(_min.text) ?? defaultMinAlert(_byTaqeh)).round();
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
        status: computeStatus(f.meters, minAlert, f.byTaqeh),
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
        byTaqeh: f.byTaqeh,
      ));
    } else {
      final m = _initialQty;
      await store.addFabric(Fabric(
        id: 'fab-${DateTime.now().microsecondsSinceEpoch}',
        code: _code.text.trim(),
        name: _name.text.trim(),
        category: _category,
        status: computeStatus(m, minAlert, _byTaqeh),
        meters: m,
        pricePerMeter: price,
        color: col,
        widthCm: width,
        location: loc,
        description: desc,
        minMetersAlert: minAlert,
        supplier: sup,
        byTaqeh: _byTaqeh,
      ));
    }
    if (!mounted) return;
    toast(context, _editing ? 'تغییرات ذخیره شد.' : 'کالا در انبار ثبت شد.');
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    Widget field(String label, TextEditingController c, {String? Function(String?)? validator, TextInputType? type, int lines = 1, String? hint, ValueChanged<String>? onChanged}) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: c,
            validator: validator,
            keyboardType: type,
            maxLines: lines,
            onChanged: onChanged,
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
            if (!_editing) ...[
              const Padding(padding: EdgeInsets.only(bottom: 6), child: Text('موجودی اولیه به صورت', style: TextStyle(fontSize: 12, color: Color(0xFF78716C)))),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('متراژ'), icon: Icon(Icons.straighten)),
                    ButtonSegment(value: true, label: Text('تاقه'), icon: Icon(Icons.layers_outlined)),
                  ],
                  selected: {_byTaqeh},
                  onSelectionChanged: (s) => _setMode(s.first),
                ),
              ),
              if (_byTaqeh)
                field('تعداد تاقه', _taqeh, type: numKb, validator: _numReq)
              else
                field('موجودی اولیه (متر)', _meters, type: numKb, validator: (v) => parseNum(v ?? '') == null ? 'عدد معتبر وارد کنید' : null),
            ],
            field('قیمت هر $_unitName (${store.unit})', _price, type: numKb, validator: _numReq),
            Row(children: [
              Expanded(child: field('عرض (سانتی‌متر)', _width, type: numKb, validator: _numReq)),
              const SizedBox(width: 10),
              Expanded(child: field('حد هشدار ($_unitName)', _min, type: numKb, validator: _numReq)),
            ]),
            field('موقعیت در انبار', _location, hint: 'مثلاً قفسه ب-۳'),
            field('تأمین‌کننده', _supplier),
            field('توضیحات', _desc, lines: 3),
            if (_editing)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: const Color(0xFFF5F5F4), borderRadius: BorderRadius.circular(14)),
                child: Text('موجودی فعلی (${faNum(widget.initial!.meters)} ${widget.initial!.unit}) از اینجا تغییر نمی‌کند؛ برای اصلاح آن «ثبت ورود/خروج» را بزنید تا در تاریخچه بماند.', style: const TextStyle(fontSize: 12, height: 1.8, color: Color(0xFF57534E))),
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
