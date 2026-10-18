import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';

const kLine = Color(0xFFDBE4E6);
const kMute = Color(0xFF62747B);

InputDecoration deco(String label, {String? hint, Widget? prefix}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefix,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kLine),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kLine),
    ),
  );
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kLine),
      ),
      child: child,
    );
  }
}

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ));
}

Future<bool> confirm(BuildContext context, String title, String message) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('تأكيد'),
        ),
      ],
    ),
  );
  return ok == true;
}

TextFormField numField(
  TextEditingController controller,
  String label, {
  bool required = false,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: deco(label),
    validator: (v) =>
        required && (v == null || v.isEmpty) ? 'هذا الحقل مطلوب' : null,
  );
}

Widget stockChip(Product p) {
  final (String label, Color color) = p.isOut
      ? ('نفد', Colors.red.shade700)
      : p.isLow
          ? ('قارب على النفاد', Colors.orange.shade800)
          : ('متوفر', Colors.green.shade700);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    decoration: BoxDecoration(
      color: color.withAlpha(30),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}
