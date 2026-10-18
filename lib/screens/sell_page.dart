import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format.dart';
import '../models.dart';
import '../store.dart';
import '../ui.dart';

class SellPage extends StatefulWidget {
  const SellPage({super.key, required this.store});

  final AppStore store;

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  final ValueNotifier<Map<String, int>> cart = ValueNotifier({});
  String query = '';
  final _searchC = TextEditingController();
  final _searchF = FocusNode();

  @override
  void dispose() {
    _searchC.dispose();
    _searchF.dispose();
    super.dispose();
  }

  void _onSubmitSearch(String v) {
    final text = v.trim();
    if (text.isEmpty) return;
    var p = widget.store.byBarcode(text);
    if (p == null) {
      final matches =
          widget.store.products.where((x) => x.name.contains(text)).toList();
      if (matches.length == 1) p = matches.first;
    }
    if (p != null) {
      if (p.stock <= 0) {
        toast(context, '«${p.name}» نفد من المخزون');
      } else {
        _add(p);
      }
    } else if (RegExp(r'^\d{6,}$').hasMatch(text)) {
      toast(context, 'هذا الباركود غير مسجّل في المخزون');
    } else {
      return;
    }
    _searchC.clear();
    setState(() => query = '');
    _searchF.requestFocus();
  }

  int _cartTotal() {
    var t = 0;
    for (final e in cart.value.entries) {
      final p = widget.store.byId(e.key);
      if (p != null) t += p.price * e.value;
    }
    return t;
  }

  int _cartCount() => cart.value.values.fold(0, (a, b) => a + b);

  void _add(Product p) {
    final cur = cart.value[p.id] ?? 0;
    if (cur >= p.stock) {
      toast(context, 'وصلت لآخر كمية متوفرة');
      return;
    }
    cart.value = {...cart.value, p.id: cur + 1};
  }

  void _dec(String id) {
    final cur = cart.value[id] ?? 0;
    final m = {...cart.value};
    if (cur <= 1) {
      m.remove(id);
    } else {
      m[id] = cur - 1;
    }
    cart.value = m;
  }

  void _remove(String id) {
    final m = {...cart.value}..remove(id);
    cart.value = m;
  }

  Future<bool> _pay() async {
    final total = _cartTotal();
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) {
        final paid = int.tryParse(ctrl.text) ?? 0;
        final change = paid - total;
        return AlertDialog(
          title: const Text('إتمام البيع'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الإجمالي: ${fmtMoney(total)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: deco('المبلغ المستلم (اختياري)'),
                onChanged: (_) => setD(() {}),
              ),
              const SizedBox(height: 8),
              if (paid > 0)
                Text(
                  change >= 0
                      ? 'الباقي للعميل: ${fmtMoney(change)}'
                      : 'ناقص: ${fmtMoney(-change)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: change >= 0
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('رجوع'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('تأكيد البيع'),
            ),
          ],
        );
      }),
    );
    if (ok != true || !mounted) return false;
    final sale = widget.store.sell(cart.value);
    if (sale == null) {
      toast(context, 'تعذر إتمام البيع، راجع الكميات');
      return false;
    }
    cart.value = {};
    toast(context, 'تم البيع: ${fmtMoney(sale.total)}');
    return true;
  }

  Widget _productsPanel() {
    return Column(
      children: [
        TextField(
          controller: _searchC,
          focusNode: _searchF,
          decoration: deco('ابحث بالاسم أو امسح الباركود',
              prefix: const Icon(Icons.qr_code_scanner)),
          onChanged: (v) => setState(() => query = v.trim()),
          onSubmitted: _onSubmitSearch,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListenableBuilder(
            listenable: widget.store,
            builder: (context, _) {
              final all = widget.store.products;
              final list = all
                  .where((p) =>
                      query.isEmpty ||
                      p.name.contains(query) ||
                      p.barcode.contains(query))
                  .toList();
              if (all.isEmpty) {
                return const Center(
                  child: Text(
                    'ما فيه أصناف بعد.\nأضفها من تبويب «المخزون» وارجع هنا للبيع.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kMute, height: 1.8),
                  ),
                );
              }
              if (list.isEmpty) {
                return const Center(
                  child: Text('ما فيه صنف بهذا الاسم',
                      style: TextStyle(color: kMute)),
                );
              }
              return ValueListenableBuilder<Map<String, int>>(
                valueListenable: cart,
                builder: (context, cartMap, _) => GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisExtent: 104,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, i) =>
                      _tile(list[i], cartMap[list[i].id] ?? 0),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _tile(Product p, int inCart) {
    final disabled = p.stock <= 0;
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: inCart > 0 ? Theme.of(context).colorScheme.primary : kLine,
            width: inCart > 0 ? 1.6 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: disabled ? null : () => _add(p),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        fmtMoney(p.price),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (inCart > 0)
                      CircleAvatar(
                        radius: 12,
                        child: Text('$inCart',
                            style: const TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
                Text(
                  disabled ? 'نفد' : 'المتوفر: ${fmtNum(p.stock)}',
                  style: const TextStyle(color: kMute, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cartPanel({required Future<void> Function() onPay}) {
    return ValueListenableBuilder<Map<String, int>>(
      valueListenable: cart,
      builder: (context, cartMap, _) {
        final entries = cartMap.entries
            .where((e) => widget.store.byId(e.key) != null)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('الفاتورة الحالية',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Expanded(
              child: entries.isEmpty
                  ? const Center(
                      child: Text('اضغط على صنف لإضافته',
                          style: TextStyle(color: kMute)),
                    )
                  : ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final p = widget.store.byId(entries[i].key)!;
                        final q = entries[i].value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    Text(fmtMoney(p.price * q),
                                        style: const TextStyle(
                                            color: kMute, fontSize: 12)),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _dec(p.id),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text('$q',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              IconButton(
                                onPressed: () => _add(p),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                              IconButton(
                                onPressed: () => _remove(p.id),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الإجمالي',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                Text(fmtMoney(_cartTotal()),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: entries.isEmpty ? null : onPay,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('إتمام البيع',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _cartBar() {
    return ValueListenableBuilder<Map<String, int>>(
      valueListenable: cart,
      builder: (context, cartMap, _) {
        if (cartMap.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: kLine)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_cartCount()} قطعة',
                        style: const TextStyle(color: kMute, fontSize: 12)),
                    Text(fmtMoney(_cartTotal()),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              FilledButton(
                onPressed: _openCartSheet,
                child: const Text('عرض الفاتورة'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openCartSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => SizedBox(
        height: MediaQuery.of(sheetCtx).size.height * 0.8,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _cartPanel(onPay: () async {
            final done = await _pay();
            if (done && sheetCtx.mounted) Navigator.pop(sheetCtx);
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth >= 840) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _productsPanel()),
              const SizedBox(width: 16),
              SizedBox(
                width: 380,
                child: Panel(child: _cartPanel(onPay: () async {
                  await _pay();
                })),
              ),
            ],
          ),
        );
      }
      return Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _productsPanel(),
            ),
          ),
          _cartBar(),
        ],
      );
    });
  }
}
