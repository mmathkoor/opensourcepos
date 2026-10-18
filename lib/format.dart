String fmtNum(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return n < 0 ? '-$b' : b.toString();
}

String fmtMoney(int n) => '${fmtNum(n)} ر.ي';

String _two(int n) => n.toString().padLeft(2, '0');

String fmtTime(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

String fmtDate(DateTime t) => '${t.year}/${_two(t.month)}/${_two(t.day)}';

String fmtDateTime(DateTime t) => '${fmtDate(t)}  ${fmtTime(t)}';
