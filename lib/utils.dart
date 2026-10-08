import 'package:shamsi_date/shamsi_date.dart';

import 'models.dart';

const _faDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

/// اعداد انگلیسی → فارسی
String toFa(Object? v) {
  if (v == null) return '۰';
  return v.toString().replaceAllMapped(RegExp(r'[0-9]'), (m) => _faDigits[int.parse(m[0]!)]);
}

/// اعداد فارسی و عربی → انگلیسی
String toEn(String s) {
  final sb = StringBuffer();
  for (final r in s.runes) {
    if (r >= 0x06F0 && r <= 0x06F9) {
      sb.writeCharCode(r - 0x06F0 + 48);
    } else if (r >= 0x0660 && r <= 0x0669) {
      sb.writeCharCode(r - 0x0660 + 48);
    } else {
      sb.writeCharCode(r);
    }
  }
  return sb.toString();
}

/// عدد با جداکننده‌ی هزارگان و حداکثر دو رقم اعشار (بدون تبدیل به رقم فارسی)
String fmtNum(num n) {
  final r = (n * 100).round() / 100;
  final s = r == r.roundToDouble() ? r.round().toString() : r.toString();
  final parts = s.split('.');
  parts[0] = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  return parts.join('.');
}

String faNum(num n) => toFa(fmtNum(n));

/// متن ورودی کاربر → عدد؛ اگر عدد نبود null
double? parseNum(String s) {
  final t = toEn(s).replaceAll('٫', '.').replaceAll(RegExp(r'[,٬،\s]'), '');
  if (t.isEmpty) return null;
  final v = double.tryParse(t);
  if (v == null || v.isNaN || v.isInfinite) return null;
  return v;
}

/// کلید مقایسه‌ی کد/نام: ارقام فارسی→انگلیسی، بدون فاصله، حروف کوچک
String normalizeKey(String s) =>
    toEn(s).replaceAll(RegExp(r'[\s\u200c]'), '').replaceAll(RegExp(r'[–—_]'), '-').toLowerCase();

/// حد هشدار پیش‌فرض: ۱۵ متر یا ۳ تاقه
int defaultMinAlert(bool byTaqeh) => byTaqeh ? 3 : 15;

String computeStatus(double qty, [int? minAlert, bool byTaqeh = false]) {
  final min = minAlert ?? defaultMinAlert(byTaqeh);
  final critical = byTaqeh ? 1 : 5; // بحرانی: ≤۱ تاقه یا ≤۵ متر
  if (qty <= critical) return 'بحرانی';
  if (qty <= min) return 'رو به اتمام';
  return 'موجود';
}

double round2(double v) => (v * 100).round() / 100;

String _joinTotals(double meters, double taqeh) {
  final parts = <String>[];
  if (meters != 0 || taqeh == 0) parts.add('${faNum(meters)} متر');
  if (taqeh != 0) parts.add('${faNum(taqeh)} تاقه');
  return parts.join(' و ');
}

/// جمع موجودی با واحدهای جدا، مثلاً «۱۲۰ متر و ۴ تاقه» (متر و تاقه با هم جمع نمی‌شوند)
String stockTotals(Iterable<Fabric> items) => _joinTotals(
      items.where((f) => !f.byTaqeh).fold<double>(0, (s, f) => s + f.meters),
      items.where((f) => f.byTaqeh).fold<double>(0, (s, f) => s + f.meters),
    );

/// جمع ورود (out=false) یا خروج (out=true) تراکنش‌ها با واحدهای جدا
String txTotals(Iterable<Tx> txs, {required bool out}) {
  double m = 0, t = 0;
  for (final x in txs) {
    final v = out ? -x.metersChange : x.metersChange;
    if (x.byTaqeh) {
      t += v;
    } else {
      m += v;
    }
  }
  return _joinTotals(round2(m), round2(t));
}

// ───────── تاریخ شمسی ─────────
const _weekdays = {6: 'شنبه', 7: 'یکشنبه', 1: 'دوشنبه', 2: 'سه‌شنبه', 3: 'چهارشنبه', 4: 'پنجشنبه', 5: 'جمعه'};
const _months = ['فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور', 'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'];

/// مثلاً «چهارشنبه ۸ مهر ۱۴۰۵»
String fullDate([DateTime? d]) {
  final x = d ?? DateTime.now();
  final j = Jalali.fromDateTime(x);
  return '${_weekdays[x.weekday]} ${toFa(j.day)} ${_months[j.month - 1]} ${toFa(j.year)}';
}

String shortJalali(DateTime d) {
  final j = Jalali.fromDateTime(d);
  return '${toFa(j.day)} ${_months[j.month - 1]} ${toFa(j.year)}';
}

String timeStr([DateTime? d]) {
  final x = d ?? DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  return toFa('${two(x.hour)}:${two(x.minute)}');
}

String isoDay(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}
