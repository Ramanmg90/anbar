import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'logic.dart';
import 'models.dart';
import 'utils.dart';

const String kDefaultUser = 'احمد ستائی مقدم';

class AppStore extends ChangeNotifier {
  List<Fabric> fabrics = [];
  List<Tx> transactions = [];
  List<Notif> notifications = [];

  bool ready = false;
  String? loadError;
  String currency = 'IRT'; // IRT = تومان، IRR = ریال
  String userName = kDefaultUser;

  Future<void> _saving = Future.value();

  // ───────── ارز ─────────
  String get unit => currency == 'IRT' ? 'تومان' : 'ریال';
  double showPrice(int rials) => currency == 'IRT' ? rials / 10 : rials.toDouble();
  int toRials(double shown) => currency == 'IRT' ? (shown * 10).round() : shown.round();
  String money(num rials) => '${faNum(currency == 'IRT' ? rials / 10 : rials)} $unit';

  List<Fabric> get active => fabrics.where((f) => !f.archived).toList();
  int get unreadCount => notifications.where((n) => !n.read).length;

  // ───────── ذخیره و بازیابی ─────────
  Future<File> _file(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$name');
  }

  Future<void> load() async {
    try {
      final s = await _file('settings.json');
      if (await s.exists()) {
        final j = jsonDecode(await s.readAsString()) as Map<String, dynamic>;
        currency = j['currency'] == 'IRR' ? 'IRR' : 'IRT';
        final u = (j['userName'] ?? '').toString().trim();
        userName = u.isEmpty ? kDefaultUser : u;
      }
      final f = await _file('inventory.json');
      if (await f.exists()) {
        try {
          _apply(jsonDecode(await f.readAsString()) as Map<String, dynamic>);
        } catch (_) {
          // فایل اصلی خراب بود؛ از نسخه‌ی قبلی بخوان
          final b = await _file('inventory.bak.json');
          if (await b.exists()) {
            _apply(jsonDecode(await b.readAsString()) as Map<String, dynamic>);
            loadError = 'فایل داده خراب بود و نسخه‌ی قبلی بازیابی شد.';
          } else {
            loadError = 'خواندن داده‌ها ممکن نشد.';
          }
        }
      }
    } catch (e) {
      loadError = 'خواندن داده‌ها ممکن نشد.';
    }
    ready = true;
    notifyListeners();
  }

  void _apply(Map<String, dynamic> j) {
    fabrics = ((j['fabrics'] as List?) ?? []).map((e) => Fabric.fromJson(e as Map<String, dynamic>)).toList();
    transactions = ((j['transactions'] as List?) ?? []).map((e) => Tx.fromJson(e as Map<String, dynamic>)).toList();
    notifications = ((j['notifications'] as List?) ?? []).map((e) => Notif.fromJson(e as Map<String, dynamic>)).toList();
  }

  Map<String, dynamic> _state() => {
        'fabrics': fabrics.map((e) => e.toJson()).toList(),
        'transactions': transactions.map((e) => e.toJson()).toList(),
        'notifications': notifications.map((e) => e.toJson()).toList(),
      };

  /// فرمت پشتیبان با نسخه‌ی وب برنامه یکی است.
  String backupJson() => jsonEncode({'app': 'parche-sarai', 'version': 1, 'exportedAt': DateTime.now().toUtc().toIso8601String(), 'state': _state()});

  Future<void> _persist() {
    final snapshot = jsonEncode(_state()); // همین حالا؛ تا ذخیره‌ی‌های پشت‌سرهم قاطی نشوند
    _saving = _saving.catchError((_) {}).then((_) async {
      final f = await _file('inventory.json');
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsString(snapshot, flush: true);
      if (await f.exists()) {
        await f.copy((await _file('inventory.bak.json')).path);
      }
      await tmp.rename(f.path);
    });
    return _saving;
  }

  Future<void> _commit() async {
    notifyListeners();
    try {
      await _persist();
    } catch (_) {
      loadError = 'ذخیره‌ی داده‌ها روی گوشی انجام نشد؛ حافظه‌ی گوشی را بررسی کنید.';
      notifyListeners();
    }
  }

  Future<void> _saveSettings() async {
    final f = await _file('settings.json');
    await f.writeAsString(jsonEncode({'currency': currency, 'userName': userName}), flush: true);
  }

  void dismissError() {
    loadError = null;
    notifyListeners();
  }

  Future<void> setCurrency(String c) async {
    currency = c;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setUserName(String n) async {
    userName = n.trim().isEmpty ? kDefaultUser : n.trim();
    notifyListeners();
    await _saveSettings();
  }

  // ───────── عملیات ─────────
  void _notify(String title, String message, String type) {
    notifications = [
      Notif(id: 'notif-${DateTime.now().microsecondsSinceEpoch}', title: title, message: message, time: '${fullDate()} ${timeStr()}', type: type),
      ...notifications,
    ];
  }

  Fabric? byId(String id) {
    for (final f in fabrics) {
      if (f.id == id) return f;
    }
    return null;
  }

  bool codeExists(String code, {String? exceptId}) {
    final k = normalizeKey(code);
    return fabrics.any((f) => f.id != exceptId && normalizeKey(f.code) == k);
  }

  Tx _tx(Fabric f, String type, double change, double after, int? price, String note) {
    final now = DateTime.now();
    return Tx(
      id: 'tr-${now.microsecondsSinceEpoch}',
      fabricId: f.id,
      fabricName: f.name,
      fabricCode: f.code,
      type: type,
      metersChange: change,
      metersAfter: after,
      pricePerMeter: price,
      timestamp: timeStr(now),
      dateStr: fullDate(now),
      at: now.toUtc().toIso8601String(),
      note: note,
      user: userName,
      supplier: f.supplier,
    );
  }

  Future<void> addFabric(Fabric f) async {
    fabrics = [f, ...fabrics];
    if (f.meters > 0) transactions = [_tx(f, 'ورود', f.meters, f.meters, f.pricePerMeter, 'موجودی اولیه'), ...transactions];
    _notify('افزودن پارچه جدید', 'پارچه «${f.name}» در انبار ثبت شد.', 'success');
    await _commit();
  }

  Future<void> updateFabric(Fabric u) async {
    fabrics = [for (final f in fabrics) f.id == u.id ? u : f];
    await _commit();
  }

  Future<void> toggleArchive(Fabric f) async {
    fabrics = [for (final x in fabrics) x.id == f.id ? x.copyWith(archived: !x.archived) : x];
    await _commit();
  }

  /// تنها مسیر تغییر موجودی؛ خطا را به‌صورت متن برمی‌گرداند (null یعنی موفق).
  Future<String?> applyStock(String fabricId, double delta, String note, {int? price}) async {
    final f = byId(fabricId);
    if (f == null) return 'کالا پیدا نشد.';
    final newMeters = round2(f.meters + delta);
    if (newMeters < 0) return 'موجودی کافی نیست؛ فقط ${faNum(f.meters)} متر در انبار است.';
    final status = computeStatus(newMeters, f.minMetersAlert ?? 15);
    final updated = f.copyWith(meters: newMeters, status: status, pricePerMeter: price ?? f.pricePerMeter, lastCountDate: 'امروز');
    fabrics = [updated, ...fabrics.where((x) => x.id != fabricId)];
    transactions = [_tx(f, delta >= 0 ? 'ورود' : 'خروج', delta, newMeters, updated.pricePerMeter, note), ...transactions];
    if (status != 'موجود' && status != f.status) {
      _notify(status == 'بحرانی' ? 'موجودی بحرانی' : 'هشدار کمبود موجودی', 'موجودی پارچه «${f.name}» به ${faNum(newMeters)} متر رسید ($status).', 'warning');
    }
    await _commit();
    return null;
  }

  Future<String?> reverse(Tx original, String reason) async {
    final res = reverseTx(original, byId(original.fabricId), reason, userName);
    if (res.error != null) return res.error;
    final nf = res.fabric!;
    fabrics = [for (final f in fabrics) f.id == nf.id ? nf : f];
    transactions = [res.record!, ...transactions.map((t) => t.id == original.id ? t.withReversedBy(res.record!.id) : t)];
    await _commit();
    return null;
  }

  Future<void> importFabrics(List<Fabric> items) async {
    final recs = <Tx>[];
    for (final f in items) {
      if (f.meters > 0) recs.add(_tx(f, 'ورود', f.meters, f.meters, f.pricePerMeter, 'ورود اولیه از فایل'));
    }
    fabrics = [...items, ...fabrics];
    transactions = [...recs, ...transactions];
    _notify('ورود گروهی کالا', '${faNum(items.length)} کالا از فایل وارد شد.', 'success');
    await _commit();
  }

  /// بازیابی پشتیبان؛ در صورت نامعتبر بودن فایل، متن خطا برمی‌گرداند.
  Future<String?> restore(String text) async {
    try {
      final j = jsonDecode(text) as Map<String, dynamic>;
      final st = j['state'];
      if (j['app'] != 'parche-sarai' || st is! Map<String, dynamic> || st['fabrics'] is! List || st['transactions'] is! List) {
        return 'این فایل، پشتیبان پارچه‌سرا نیست.';
      }
      _apply(st);
      await _commit();
      return null;
    } catch (_) {
      return 'فایل پشتیبان خراب یا نامعتبر است.';
    }
  }

  Future<void> markAllRead() async {
    notifications = [for (final n in notifications) n.asRead()];
    await _commit();
  }

  Future<void> clearNotifications() async {
    notifications = [];
    await _commit();
  }
}
