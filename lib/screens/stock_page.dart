import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../store.dart';
import '../ui.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key, required this.store});

  final AppStore store;

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showProductDialog(context, widget.store),
        icon: const Icon(Icons.add),
        label: const Text('إضافة صنف'),
      ),
      body: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final all = widget.store.products;
          if (all.isEmpty) return _empty(context);
          final list = all
              .where((p) => query.isEmpty || p.name.contains(query))
              .toList();
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      decoration:
                          deco('ابحث عن صنف', prefix: const Icon(Icons.search)),
                      onChanged: (v) => setState(() => query = v.trim()),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _row(context, list[i]),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, Product p) {
    return Panel(
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: () => showProductDialog(context, widget.store, product: p),
        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          'البيع ${fmtMoney(p.price)}'
          '${p.cost > 0 ? '  ·  الشراء ${fmtMoney(p.cost)}' : ''}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              fmtNum(p.stock),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            stockChip(p),
          ],
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 56, color: kMute),
            const SizedBox(height: 12),
            const Text(
              'ما فيه أصناف في المخزون',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'أضف أول صنف، أو حمّل أصناف تجريبية عشان تجرّب النظام.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kMute),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () => showProductDialog(context, widget.store),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة صنف'),
                ),
                OutlinedButton(
                  onPressed: widget.store.loadSamples,
                  child: const Text('تحميل أصناف تجريبية'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showProductDialog(
  BuildContext context,
  AppStore store, {
  Product? product,
}) async {
  final nameC = TextEditingController(text: product?.name ?? '');
  final priceC =
      TextEditingController(text: product == null ? '' : '${product.price}');
  final costC = TextEditingController(
      text: (product == null || product.cost == 0) ? '' : '${product.cost}');
  final stockC =
      TextEditingController(text: product == null ? '0' : '${product.stock}');
  final minC =
      TextEditingController(text: '${product?.minStock ?? 5}');
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(product == null ? 'إضافة صنف' : 'تعديل الصنف'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameC,
                  decoration: deco('اسم الصنف'),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'اكتب اسم الصنف' : null,
                ),
                const SizedBox(height: 12),
                numField(priceC, 'سعر البيع', required: true),
                const SizedBox(height: 12),
                numField(costC, 'سعر الشراء (اختياري)'),
                const SizedBox(height: 12),
                numField(
                  stockC,
                  product == null ? 'الكمية الحالية' : 'الكمية الحالية (جرد)',
                ),
                const SizedBox(height: 12),
                numField(minC, 'نبّهني لما تنزل الكمية إلى'),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (product != null)
          TextButton(
            onPressed: () async {
              final ok = await confirm(
                ctx,
                'حذف الصنف',
                'تحذف «${product.name}»؟ سجل المبيعات القديمة ما يتأثر.',
              );
              if (ok && ctx.mounted) {
                store.deleteProduct(product.id);
                Navigator.pop(ctx);
              }
            },
            child: Text('حذف', style: TextStyle(color: Colors.red.shade700)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            final price = int.parse(priceC.text);
            final cost = int.tryParse(costC.text) ?? 0;
            final stock = int.tryParse(stockC.text) ?? 0;
            final min = int.tryParse(minC.text) ?? 5;
            if (product == null) {
              store.addProduct(
                name: nameC.text,
                price: price,
                cost: cost,
                stock: stock,
                minStock: min,
              );
            } else {
              product
                ..name = nameC.text.trim()
                ..price = price
                ..cost = cost
                ..stock = stock
                ..minStock = min;
              store.updateProduct(product);
            }
            Navigator.pop(ctx);
          },
          child: const Text('حفظ'),
        ),
      ],
    ),
  );
}
