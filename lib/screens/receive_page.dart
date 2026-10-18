import 'package:flutter/material.dart';

import '../format.dart';
import '../store.dart';
import '../ui.dart';

class ReceivePage extends StatefulWidget {
  const ReceivePage({super.key, required this.store});

  final AppStore store;

  @override
  State<ReceivePage> createState() => _ReceivePageState();
}

class _ReceivePageState extends State<ReceivePage> {
  String? _productId;
  int _reset = 0;
  final _qtyC = TextEditingController();
  final _costC = TextEditingController();
  final _supplierC = TextEditingController();

  @override
  void dispose() {
    _qtyC.dispose();
    _costC.dispose();
    _supplierC.dispose();
    super.dispose();
  }

  void _save() {
    final qty = int.tryParse(_qtyC.text) ?? 0;
    if (_productId == null) {
      toast(context, 'اختر الصنف أولًا');
      return;
    }
    if (qty <= 0) {
      toast(context, 'اكتب كمية أكبر من صفر');
      return;
    }
    final p = widget.store.byId(_productId!);
    final ok = widget.store.receive(
      productId: _productId!,
      qty: qty,
      unitCost: int.tryParse(_costC.text),
      supplier: _supplierC.text,
    );
    if (!ok) {
      toast(context, 'تعذر تسجيل الاستلام');
      return;
    }
    toast(context, 'أضيف ${fmtNum(qty)} إلى «${p?.name ?? ''}»');
    setState(() {
      _productId = null;
      _reset++;
      _qtyC.clear();
      _costC.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final store = widget.store;
        final selected = _productId == null ? null : store.byId(_productId!);
        final recent = store.receivings.reversed.take(10).toList();
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Panel(
                  child: store.products.isEmpty
                      ? const Text(
                          'أضف أصناف من تبويب «المخزون» أولًا، وبعدها سجّل البضاعة الداخلة هنا.',
                          style: TextStyle(color: kMute, height: 1.7),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('تسجيل بضاعة داخلة',
                                style: TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 12),
                            DropdownMenu<String>(
                              key: ValueKey('dd$_reset'),
                              expandedInsets: EdgeInsets.zero,
                              label: const Text('الصنف'),
                              enableFilter: true,
                              requestFocusOnTap: true,
                              dropdownMenuEntries: [
                                for (final p in store.products)
                                  DropdownMenuEntry(value: p.id, label: p.name),
                              ],
                              onSelected: (v) =>
                                  setState(() => _productId = v),
                            ),
                            if (selected != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'المتوفر حاليًا: ${fmtNum(selected.stock)}',
                                  style: const TextStyle(
                                      color: kMute, fontSize: 13),
                                ),
                              ),
                            const SizedBox(height: 12),
                            numField(_qtyC, 'الكمية الداخلة'),
                            const SizedBox(height: 12),
                            numField(_costC, 'سعر الشراء للقطعة (اختياري)'),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _supplierC,
                              decoration: deco('اسم المورّد (اختياري)'),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _save,
                                style: FilledButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text('إضافة إلى المخزون'),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('آخر ما دخل',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      if (recent.isEmpty)
                        const Text('لا توجد عمليات استلام بعد',
                            style: TextStyle(color: kMute))
                      else
                        for (final r in recent)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(r.name),
                            subtitle: Text(
                              '${fmtDateTime(r.time)}'
                              '${r.supplier.isEmpty ? '' : '  ·  ${r.supplier}'}',
                            ),
                            trailing: Text(
                              '+${fmtNum(r.qty)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
