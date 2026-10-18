import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../store.dart';
import '../ui.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.store});

  final AppStore store;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _nameC =
      TextEditingController(text: widget.store.shopName);

  @override
  void dispose() {
    _nameC.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    await Clipboard.setData(ClipboardData(text: widget.store.exportJson()));
    if (!mounted) return;
    toast(context, 'تم نسخ كل البيانات. الصقها في ملاحظات أو رسالة واحفظها.');
  }

  Future<void> _import() async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استعادة نسخة احتياطية'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'الصق النص الذي نسخته سابقًا. تنبيه: هذا يستبدل كل البيانات الحالية.',
                style: TextStyle(color: kMute, height: 1.6),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: c,
                maxLines: 8,
                textDirection: TextDirection.ltr,
                decoration: deco('النص'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('استعادة'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final done = widget.store.importJson(c.text);
    if (!mounted) return;
    toast(context, done ? 'تمت الاستعادة' : 'النص غير صالح، ما تغيّرت البيانات');
    if (done) _nameC.text = widget.store.shopName;
  }

  Future<void> _reset() async {
    final ok = await confirm(
      context,
      'حذف كل البيانات',
      'يُحذف كل شيء: الأصناف والمبيعات والاستلام. ما فيه رجعة إلا لو عندك نسخة احتياطية.',
    );
    if (!ok || !mounted) return;
    widget.store.resetAll();
    _nameC.text = widget.store.shopName;
    toast(context, 'تم حذف البيانات');
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('اسم المحل',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  TextField(controller: _nameC, decoration: deco('الاسم')),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      widget.store.setShopName(_nameC.text);
                      toast(context, 'تم الحفظ');
                    },
                    child: const Text('حفظ'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('النسخ الاحتياطي',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text(
                    'البيانات محفوظة في متصفح هذا الجهاز فقط. لو انمسح المتصفح '
                    'أو تغيّر الجهاز تضيع. انسخ نسخة احتياطية بشكل دوري واحفظها.',
                    style: TextStyle(color: kMute, height: 1.7),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: _export,
                        icon: const Icon(Icons.copy),
                        label: const Text('نسخ البيانات'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _import,
                        icon: const Icon(Icons.restore),
                        label: const Text('استعادة'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Panel(
              child: Row(
                children: [
                  const Expanded(
                    child: Text('حذف كل البيانات',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  OutlinedButton(
                    onPressed: _reset,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                    ),
                    child: const Text('حذف'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
