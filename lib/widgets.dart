import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'models.dart';
import 'utils.dart';

const Color kBrand = Color(0xFF521C27);
const Color kBg = Color(0xFFFAFAF9);

/// فضای خالی زیر لیست‌ها برای نوار پایین شیشه‌ای (و دکمه‌های شناور)
const double kNavSpace = 104;

/// پس‌زمینه‌ی ملایم صفحه‌ی اصلی؛ شیشه‌ها رویش دیده می‌شوند
const BoxDecoration kShellBackground = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF7ECEE), Color(0xFFFAFAF9), Color(0xFFF1EEEA)],
  ),
);

void toast(BuildContext context, String msg, {bool error = false}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: error ? Colors.red.shade800 : Colors.green.shade800,
    behavior: SnackBarBehavior.floating,
  ));
}

Color statusColor(String s) {
  switch (s) {
    case 'بحرانی':
      return Colors.red.shade700;
    case 'رو به اتمام':
      return Colors.amber.shade800;
    default:
      return Colors.green.shade700;
  }
}

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withAlpha(30), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class FabricAvatar extends StatelessWidget {
  final Fabric fabric;
  final double size;
  const FabricAvatar(this.fabric, {super.key, this.size = 48});

  static const _colors = {
    'کتان': Color(0xFFB08968),
    'مخمل': Color(0xFF7B2D3B),
    'کرپ': Color(0xFF3F3F46),
    'لینن': Color(0xFF8A9A7B),
    'ساتن': Color(0xFFB5838D),
    'سایر': Color(0xFF78716C),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: _colors[fabric.category] ?? const Color(0xFF78716C), borderRadius: BorderRadius.circular(size / 4)),
      child: Text(fabric.name.isEmpty ? '؟' : String.fromCharCode(fabric.name.runes.first), style: TextStyle(color: Colors.white, fontSize: size * 0.42, fontWeight: FontWeight.w700)),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  const StatCard({super.key, required this.label, required this.value, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? kBrand;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE7E5E4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: c, size: 22),
          const SizedBox(height: 10),
          FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c))),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF78716C), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyState(this.icon, this.text, {super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 48, color: const Color(0xFFA8A29E)),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF78716C), fontSize: 13, height: 1.8)),
          ]),
        ),
      );
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
        child: Row(children: [
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1C1917)))),
          if (trailing != null) trailing!,
        ]),
      );
}

Color txColor(String type) {
  switch (type) {
    case 'ورود':
      return Colors.green.shade700;
    case 'خروج':
      return Colors.red.shade700;
    case 'لغو':
      return Colors.grey.shade700;
    default:
      return Colors.amber.shade800;
  }
}

IconData txIcon(String type) {
  switch (type) {
    case 'ورود':
      return Icons.arrow_downward;
    case 'خروج':
      return Icons.arrow_upward;
    case 'لغو':
      return Icons.undo;
    default:
      return Icons.tune;
  }
}

class TxTile extends StatelessWidget {
  final Tx tx;
  final VoidCallback? onReverse;
  const TxTile(this.tx, {super.key, this.onReverse});

  @override
  Widget build(BuildContext context) {
    final c = txColor(tx.type);
    final reversed = tx.reversedBy != null;
    final canReverse = onReverse != null && !reversed && tx.reverses == null;
    return Opacity(
      opacity: reversed ? 0.55 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7E5E4))),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: c.withAlpha(28), borderRadius: BorderRadius.circular(12)),
            child: Icon(txIcon(tx.type), color: c, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                reversed ? '${tx.fabricName} (لغو شد)' : tx.fabricName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, decoration: reversed ? TextDecoration.lineThrough : null),
              ),
              const SizedBox(height: 2),
              Text(
                '${tx.type} · ${tx.timestamp}${tx.note.isEmpty ? '' : ' · ${tx.note}'}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF78716C), height: 1.5),
              ),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${tx.metersChange > 0 ? '+' : ''}${faNum(tx.metersChange)} ${tx.unitShort}',
                textDirection: TextDirection.ltr, style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 13)),
            Text('مانده ${faNum(tx.metersAfter)}', style: const TextStyle(fontSize: 10, color: Color(0xFF78716C))),
            if (canReverse)
              InkWell(
                onTap: onReverse,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('لغو', style: TextStyle(color: Colors.red.shade800, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
          ]),
        ]),
      ),
    );
  }
}


// ───────────────────────── المان‌های شیشه‌ای (سبک iOS) ─────────────────────────

/// سطح شیشه‌ای: بلور پس‌زمینه + رنگ نیمه‌شفاف + لبه‌ی روشن
class GlassPanel extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final Color tint;
  final double blur;
  const GlassPanel({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding,
    this.tint = Colors.white,
    this.blur = 24,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(22), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: r,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [tint.withAlpha(190), tint.withAlpha(120)],
              ),
              border: Border.all(color: Colors.white.withAlpha(170), width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// دکمه‌ی گرد و شیشه‌ای. [light] = دکمه‌ی روشن (جای OutlinedButton).
class GlassButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color color;
  final bool light;
  final double height;
  final bool expand;
  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = kBrand,
    this.light = false,
    this.height = 52,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final base = enabled ? color : const Color(0xFFA8A29E);
    final fg = light ? (enabled ? const Color(0xFF292524) : const Color(0xFFA8A29E)) : Colors.white;
    final r = BorderRadius.circular(height / 2);
    final top = light ? Colors.white.withAlpha(215) : base.withAlpha(235);
    final bottom = light ? Colors.white.withAlpha(120) : base.withAlpha(185);
    return SizedBox(
      height: height,
      width: expand ? double.infinity : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: r,
          boxShadow: [BoxShadow(color: (light ? Colors.black : base).withAlpha(light ? 20 : 70), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: ClipRRect(
          borderRadius: r,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Stack(alignment: Alignment.center, children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: r,
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom]),
                    border: Border.all(color: Colors.white.withAlpha(light ? 230 : 120), width: 1),
                  ),
                ),
              ),
              // برق ملایم نیمه‌ی بالا
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: height / 2,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withAlpha(light ? 120 : 70), Colors.white.withAlpha(0)]),
                    ),
                  ),
                ),
              ),
              // محتوا (آیکن + متن): تنها فرزند «غیر Positioned» است تا عرض دکمه
              // وقتی expand=false است به اندازه‌ی محتوا شود (نه کل عرض صفحه).
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (icon != null) ...[Icon(icon, size: 19, color: fg), const SizedBox(width: 8)],
                  Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 14))),
                ]),
              ),
              // لایه‌ی لمس و افکت موج
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(borderRadius: r, onTap: onPressed),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// دکمه‌ی گرد و شیشه‌ای فقط با آیکن (مثل «+»)
class GlassCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final Color color;
  final bool light;
  const GlassCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 56,
    this.color = kBrand,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = light ? const Color(0xFF292524) : Colors.white;
    final btn = SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: (light ? Colors.black : color).withAlpha(light ? 28 : 80), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: light ? [Colors.white.withAlpha(215), Colors.white.withAlpha(120)] : [color.withAlpha(235), color.withAlpha(180)],
                ),
                border: Border.all(color: Colors.white.withAlpha(light ? 230 : 130), width: 1),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onPressed,
                  child: Icon(icon, color: fg, size: size * 0.46),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

/// نوار پایین شیشه‌ای و شناور (مثل iOS)
class GlassNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final List<({IconData icon, IconData selectedIcon, String label})> items;
  const GlassNavBar({super.key, required this.index, required this.onChanged, required this.items});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: GlassPanel(
          radius: 30,
          blur: 30,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: i == index ? kBrand.withAlpha(30) : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(i == index ? items[i].selectedIcon : items[i].icon, size: 24, color: i == index ? kBrand : const Color(0xFF78716C)),
                      const SizedBox(height: 2),
                      Text(items[i].label, style: TextStyle(fontSize: 10.5, fontWeight: i == index ? FontWeight.w800 : FontWeight.w500, color: i == index ? kBrand : const Color(0xFF78716C))),
                    ]),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
