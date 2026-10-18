class Product {
  Product({
    required this.id,
    required this.name,
    required this.price,
    this.cost = 0,
    this.stock = 0,
    this.minStock = 5,
    this.barcode = '',
  });

  final String id;
  String name;
  String barcode;
  int price;
  int cost;
  int stock;
  int minStock;

  bool get isOut => stock <= 0;
  bool get isLow => stock > 0 && stock <= minStock;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'cost': cost,
        'stock': stock,
        'minStock': minStock,
        'barcode': barcode,
      };

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as String,
        name: j['name'] as String,
        price: (j['price'] as num).toInt(),
        cost: ((j['cost'] ?? 0) as num).toInt(),
        stock: ((j['stock'] ?? 0) as num).toInt(),
        minStock: ((j['minStock'] ?? 5) as num).toInt(),
        barcode: ((j['barcode'] ?? '') as String),
      );
}

class SaleLine {
  SaleLine({
    required this.productId,
    required this.name,
    required this.qty,
    required this.price,
    required this.cost,
  });

  final String productId;
  final String name;
  final int qty;
  final int price;
  final int cost;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'qty': qty,
        'price': price,
        'cost': cost,
      };

  factory SaleLine.fromJson(Map<String, dynamic> j) => SaleLine(
        productId: j['productId'] as String,
        name: j['name'] as String,
        qty: (j['qty'] as num).toInt(),
        price: (j['price'] as num).toInt(),
        cost: ((j['cost'] ?? 0) as num).toInt(),
      );
}

class Sale {
  Sale({required this.id, required this.time, required this.lines});

  final String id;
  final DateTime time;
  final List<SaleLine> lines;

  int get total => lines.fold(0, (s, l) => s + l.price * l.qty);
  int get costTotal => lines.fold(0, (s, l) => s + l.cost * l.qty);
  int get profit => total - costTotal;
  int get items => lines.fold(0, (s, l) => s + l.qty);

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time.millisecondsSinceEpoch,
        'lines': lines.map((l) => l.toJson()).toList(),
      };

  factory Sale.fromJson(Map<String, dynamic> j) => Sale(
        id: j['id'] as String,
        time: DateTime.fromMillisecondsSinceEpoch((j['time'] as num).toInt()),
        lines: (j['lines'] as List)
            .map((e) => SaleLine.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Receiving {
  Receiving({
    required this.id,
    required this.time,
    required this.productId,
    required this.name,
    required this.qty,
    required this.cost,
    required this.supplier,
  });

  final String id;
  final DateTime time;
  final String productId;
  final String name;
  final int qty;
  final int cost;
  final String supplier;

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time.millisecondsSinceEpoch,
        'productId': productId,
        'name': name,
        'qty': qty,
        'cost': cost,
        'supplier': supplier,
      };

  factory Receiving.fromJson(Map<String, dynamic> j) => Receiving(
        id: j['id'] as String,
        time: DateTime.fromMillisecondsSinceEpoch((j['time'] as num).toInt()),
        productId: j['productId'] as String,
        name: j['name'] as String,
        qty: (j['qty'] as num).toInt(),
        cost: ((j['cost'] ?? 0) as num).toInt(),
        supplier: (j['supplier'] ?? '') as String,
      );
}
