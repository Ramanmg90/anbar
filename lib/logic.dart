import 'models.dart';
import 'utils.dart';

// ───────────────────────── ورود از CSV ─────────────────────────
const Map<String, String> _headers = {
  'نام': 'name', 'نامکالا': 'name', 'نامپارچه': 'name', 'name': 'name',
  'کد': 'code', 'کدکالا': 'code', 'code': 'code',
  'دسته': 'category', 'دستهبندی': 'category', 'category': 'category',
  'رنگ': 'color', 'color': 'color',
  'عرض': 'widthCm', 'width': 'widthCm',
  'متراژ': 'meters', 'متراژموجود': 'meters', 'موجودی': 'meters', 'meters': 'meters',
  'قیمت': 'price', 'قیمتهرمتر': 'price', 'price': 'price',
  'موقعیت': 'location', 'موقعیتدرانبار': 'location', 'location': 'location',
  'حدهشدار': 'min', 'هشدار': 'min', 'min': 'min',
  'تامینکننده': 'supplier', 'تأمینکننده': 'supplier', 'supplier': 'supplier',
  'توضیحات': 'description', 'description': 'description',
};

String _headerKey(String h) {
  final noParen = h.replaceAll(RegExp(r'[(（][^)）]*[)）]'), '');
  return _headers[normalizeKey(noParen)] ?? _headers[normalizeKey(h)] ?? '';
}

/// پارس CSV با پشتیبانی از گیومه، کاما/نقطه‌ویرگول/تب و BOM اکسل
List<List<String>> parseCsv(String text) {
  var src = text;
  if (src.startsWith('\uFEFF')) src = src.substring(1);
  final firstLine = src.split(RegExp(r'\r?\n')).first;
  var delim = ',';
  var best = 0;
  for (final d in [',', ';', '\t']) {
    final c = firstLine.split(d).length;
    if (c > best) {
      best = c;
      delim = d;
    }
  }
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var q = false;
  for (var i = 0; i < src.length; i++) {
    final c = src[i];
    if (q) {
      if (c == '"' && i + 1 < src.length && src[i + 1] == '"') {
        cell.write('"');
        i++;
      } else if (c == '"') {
        q = false;
      } else {
        cell.write(c);
      }
    } else if (c == '"') {
      q = true;
    } else if (c == delim) {
      row.add(cell.toString());
      cell.clear();
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < src.length && src[i + 1] == '\n') i++;
      row.add(cell.toString());
      cell.clear();
      if (row.any((x) => x.trim().isNotEmpty)) rows.add(row);
      row = <String>[];
    } else {
      cell.write(c);
    }
  }
  row.add(cell.toString());
  if (row.any((x) => x.trim().isNotEmpty)) rows.add(row);
  return rows;
}

class ImportRow {
  final int line;
  final Fabric? fabric;
  final String? error;
  const ImportRow(this.line, {this.fabric, this.error});
}

class ImportResult {
  final List<ImportRow> rows;
  final List<String> missing;
  const ImportResult(this.rows, this.missing);
  List<Fabric> get good => [for (final r in rows) if (r.fabric != null) r.fabric!];
  List<ImportRow> get bad => [for (final r in rows) if (r.error != null) r];
}

/// [priceFactor]: ۱۰ اگر قیمت‌های فایل تومان است، ۱ اگر ریال
ImportResult buildImport(List<List<String>> rows, List<String> existingCodes, int priceFactor) {
  if (rows.length < 2) return const ImportResult([], ['فایل خالی است یا فقط سطر عنوان دارد']);
  final cols = rows[0].map(_headerKey).toList();
  const labels = {'name': 'نام', 'code': 'کد', 'meters': 'متراژ', 'price': 'قیمت'};
  final missing = [for (final k in labels.keys) if (!cols.contains(k)) labels[k]!];
  if (missing.isNotEmpty) return ImportResult(const [], missing);

  final seen = existingCodes.map(normalizeKey).toSet();
  final out = <ImportRow>[];
  final stamp = DateTime.now().millisecondsSinceEpoch;
  for (var i = 1; i < rows.length; i++) {
    final r = rows[i];
    final line = i + 1;
    String get(String k) {
      final idx = cols.indexOf(k);
      return (idx >= 0 && idx < r.length) ? r[idx].trim() : '';
    }

    final name = get('name');
    final code = get('code');
    final meters = parseNum(get('meters'));
    final priceRaw = parseNum(get('price'));
    if (name.isEmpty) {
      out.add(ImportRow(line, error: 'نام خالی است'));
      continue;
    }
    if (code.isEmpty) {
      out.add(ImportRow(line, error: 'کد خالی است'));
      continue;
    }
    if (meters == null || meters < 0) {
      out.add(ImportRow(line, error: 'متراژ نامعتبر است'));
      continue;
    }
    if (priceRaw == null || priceRaw <= 0) {
      out.add(ImportRow(line, error: 'قیمت نامعتبر است'));
      continue;
    }
    final key = normalizeKey(code);
    if (seen.contains(key)) {
      out.add(ImportRow(line, error: 'کد تکراری (در انبار یا در همین فایل)'));
      continue;
    }
    seen.add(key);
    final cat = kCategories.contains(get('category')) ? get('category') : 'سایر';
    final minV = parseNum(get('min'));
    final min = (minV != null && minV > 0) ? minV.round() : 15;
    final w = parseNum(get('widthCm'));
    out.add(ImportRow(
      line,
      fabric: Fabric(
        id: 'fab-$stamp-$i',
        code: code,
        name: name,
        category: cat,
        status: computeStatus(meters, min),
        meters: meters,
        pricePerMeter: (priceRaw * priceFactor).round(),
        color: get('color').isEmpty ? 'استاندارد' : get('color'),
        widthCm: (w != null && w > 0) ? w.round() : 150,
        location: get('location').isEmpty ? 'نامشخص' : get('location'),
        description: get('description').isEmpty ? null : get('description'),
        minMetersAlert: min,
        supplier: get('supplier').isEmpty ? null : get('supplier'),
      ),
    ));
  }
  return ImportResult(out, const []);
}

const String kSampleCsv =
    '\uFEFFنام,کد,دسته,رنگ,عرض,متراژ,قیمت,موقعیت,تأمین‌کننده\r\nکتان نخودی ممتاز,۱۴۰۵-۰۰۰۱,کتان,نخودی,۱۴۰,۴۰,۶۴۰۰۰۰,قفسه الف-۱,شرکت نمونه\r\n';

// ───────────────────────── لغو تراکنش ─────────────────────────
class ReverseOutcome {
  final String? error;
  final Fabric? fabric;
  final Tx? record;
  const ReverseOutcome.fail(this.error)
      : fabric = null,
        record = null;
  const ReverseOutcome.ok(this.fabric, this.record) : error = null;
}

/// لغو با ثبت تراکنش جبرانی؛ سابقه‌ی اصلی دست‌نخورده می‌ماند.
ReverseOutcome reverseTx(Tx tx, Fabric? fabric, String reason, String user) {
  if (tx.reversedBy != null) return const ReverseOutcome.fail('این تراکنش قبلاً لغو شده است.');
  if (tx.reverses != null) return const ReverseOutcome.fail('تراکنش جبرانی را نمی‌شود دوباره لغو کرد؛ به‌جایش تراکنش تازه ثبت کنید.');
  if (fabric == null) return const ReverseOutcome.fail('کالای این تراکنش پیدا نشد.');
  if (reason.trim().isEmpty) return const ReverseOutcome.fail('دلیل لغو را بنویسید.');
  final newMeters = round2(fabric.meters - tx.metersChange);
  if (newMeters < 0) {
    return ReverseOutcome.fail('لغو ممکن نیست؛ موجودی فعلی (${faNum(fabric.meters)} ${fabric.unit}) کمتر از مقداری است که باید برگردد.');
  }
  final now = DateTime.now();
  final rec = Tx(
    id: 'tr-${now.millisecondsSinceEpoch}-rev',
    fabricId: fabric.id,
    fabricName: fabric.name,
    fabricCode: fabric.code,
    type: 'لغو',
    metersChange: round2(-tx.metersChange),
    metersAfter: newMeters,
    pricePerMeter: tx.pricePerMeter,
    timestamp: timeStr(now),
    dateStr: fullDate(now),
    at: now.toUtc().toIso8601String(),
    note: 'لغو تراکنش — ${reason.trim()}',
    user: user,
    reverses: tx.id,
    reverseReason: reason.trim(),
    byTaqeh: fabric.byTaqeh,
  );
  return ReverseOutcome.ok(
    fabric.copyWith(meters: newMeters, status: computeStatus(newMeters, fabric.minMetersAlert, fabric.byTaqeh), lastCountDate: 'امروز'),
    rec,
  );
}

// ───────────────────────── گزارش بازه‌ای ─────────────────────────
enum GroupBy { category, user, supplier, fabric }

const Map<GroupBy, String> kGroupLabels = {
  GroupBy.category: 'دسته',
  GroupBy.user: 'کاربر',
  GroupBy.supplier: 'تأمین‌کننده',
  GroupBy.fabric: 'کالا',
};

class ReportRow {
  final String key;
  double inMeters = 0;
  double outMeters = 0;
  double outValue = 0; // ریال
  int count = 0;
  ReportRow(this.key);
}

class RangeReportData {
  final List<ReportRow> rows;
  final double inTotal;
  final double outTotal;
  final double outValue;
  final int undated;
  const RangeReportData(this.rows, this.inTotal, this.outTotal, this.outValue, this.undated);
}

/// تراکنش لغوشده و جبرانی‌اش اثر خالص صفر دارند و حساب نمی‌شوند؛
/// تراکنش‌های بدون زمان دقیق در بازه جا نمی‌گیرند و تعدادشان جدا گزارش می‌شود.
RangeReportData buildRangeReport(List<Tx> txs, List<Fabric> fabrics, DateTime from, DateTime to, GroupBy by) {
  final byId = {for (final f in fabrics) f.id: f};
  final map = <String, ReportRow>{};
  var undated = 0;
  for (final t in txs) {
    if (t.at == null) {
      undated++;
      continue;
    }
    final when = DateTime.tryParse(t.at!)?.toLocal();
    if (when == null || when.isBefore(from) || when.isAfter(to)) continue;
    if (t.reversedBy != null || t.reverses != null) continue;
    final f = byId[t.fabricId];
    final String key;
    switch (by) {
      case GroupBy.category:
        key = f?.category ?? 'نامشخص';
        break;
      case GroupBy.user:
        key = t.user ?? 'نامشخص';
        break;
      case GroupBy.supplier:
        key = t.supplier ?? f?.supplier ?? 'بدون تأمین‌کننده';
        break;
      case GroupBy.fabric:
        key = '${t.fabricName} — ${t.fabricCode}';
        break;
    }
    final row = map.putIfAbsent(key, () => ReportRow(key));
    final price = (t.pricePerMeter ?? f?.pricePerMeter ?? 0).toDouble();
    if (t.metersChange >= 0) {
      row.inMeters = round2(row.inMeters + t.metersChange);
    } else {
      row.outMeters = round2(row.outMeters - t.metersChange);
      row.outValue += -t.metersChange * price;
    }
    row.count++;
  }
  final rows = map.values.toList()..sort((a, b) => (b.inMeters + b.outMeters).compareTo(a.inMeters + a.outMeters));
  var i = 0.0, o = 0.0, v = 0.0;
  for (final r in rows) {
    i += r.inMeters;
    o += r.outMeters;
    v += r.outValue;
  }
  return RangeReportData(rows, round2(i), round2(o), v, undated);
}

String csvCell(Object v) => '"${v.toString().replaceAll('"', '""')}"';
