import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../store.dart';
import '../ui.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key, required this.store});

  final AppStore store;

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  int _range = 0;

  DateTime _start() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_range) {
      case 1:
        return today.subtract(const Duration(days: 6));
      case 2:
        return DateTime(now.year, now.month, 1);
      default:
        return today;
    }
  }

  String get _rangeLabel => const ['اليوم', 'آخر 7 أيام', 'هذا الشهر'][_range];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final store = widget.store;
        final sales = store.salesSince(_start());
        final total = sales.fold(0, (s, x) => s + x.total);
        final profit = sales.fold(0, (s, x) => s + x.profit);
        final items = sales.fold(0, (s, x) => s + x.items);

        final byName = <String, int>{};
        for (final s in sales) {
          for (final l in s.lines) {
            byName[l.name] = (byName[l.name] ?? 0) + l.qty;
          }
        }
        final top = byName.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final recent = sales.reversed.take(8).toList();
        final low = store.lowStock;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('اليوم')),
                    ButtonSegment(value: 1, label: Text('7 أيام')),
                    ButtonSegment(value: 2, label: Text('الشهر')),
                  ],
                  selected: {_range},
                  onSelectionChanged: (s) => setState(() => _range = s.first),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(builder: (context, c) {
                  final w = c.maxWidth >= 640
                      ? (c.maxWidth - 36) / 4
                      : (c.maxWidth - 12) / 2;
                  Widget stat(String label, String value) => SizedBox(
                        width: w,
                        child: Panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(label,
                                  style: const TextStyle(
                                      color: kMute, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(value,
                                  style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      );
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      stat('المبيعات ($_rangeLabel)', fmtMoney(total)),
                      stat('الربح التقديري', fmtMoney(profit)),
                      stat('عدد الفواتير', fmtNum(sales.length)),
                      stat('قطع مباعة', fmtNum(items)),
                    ],
                  );
                }),
                const SizedBox(height: 6),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    'الربح تقديري: يعتمد على سعر الشراء المسجّل لكل صنف.',
                    style: TextStyle(color: kMute, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 10),
                _section('الأكثر مبيعًا ($_rangeLabel)', [
                  if (top.isEmpty)
                    const Text('لا مبيعات في هذه الفترة',
                        style: TextStyle(color: kMute)),
                  for (final e in top.take(5))
                    _line(e.key, fmtNum(e.value)),
                ]),
                const SizedBox(height: 12),
                _section('يحتاج طلب بضاعة', [
                  if (low.isEmpty)
                    const Text('كل الأصناف بكميات كافية',
                        style: TextStyle(color: kMute)),
                  for (final p in low)
                    _line(p.name, '${fmtNum(p.stock)}', chip: stockChip(p)),
                ]),
                const SizedBox(height: 12),
                _section('آخر الفواتير', [
                  if (recent.isEmpty)
                    const Text('لا توجد فواتير بعد',
                        style: TextStyle(color: kMute)),
                  for (final s in recent) _saleLine(s),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _line(String label, String value, {Widget? chip}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          if (chip != null) ...[chip, const SizedBox(width: 10)],
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _saleLine(Sale s) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${fmtNum(s.items)} قطعة'),
                Text(fmtDateTime(s.time),
                    style: const TextStyle(color: kMute, fontSize: 12)),
              ],
            ),
          ),
          Text(fmtMoney(s.total),
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
