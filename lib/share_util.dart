import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// فایل متنی می‌سازد و پنجره‌ی اشتراک‌گذاری اندروید را باز می‌کند
/// (ذخیره در فایل‌ها/گوگل‌درایو، فرستادن در تلگرام و واتس‌اپ و…).
Future<void> shareTextFile(String fileName, String content, {String? subject, String mime = 'text/plain'}) async {
  final dir = await getTemporaryDirectory();
  final f = File('${dir.path}/$fileName');
  await f.writeAsString(content, flush: true);
  await Share.shareXFiles([XFile(f.path, mimeType: mime)], subject: subject);
}

/// انتخاب فایل از گوشی و برگرداندن متنش؛ اگر انصراف داده شود null
Future<String?> pickTextFile() async {
  final res = await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
  if (res == null || res.files.isEmpty) return null;
  final bytes = res.files.single.bytes;
  if (bytes == null) return null;
  var text = utf8.decode(bytes, allowMalformed: true);
  if (text.startsWith('\uFEFF')) text = text.substring(1);
  return text;
}
