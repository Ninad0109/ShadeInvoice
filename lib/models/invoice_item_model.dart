class InvoiceItem {
  final String id;
  final String description;
  final double quantity;
  final double unitPrice;
  double get totalPrice => quantity * unitPrice;

  InvoiceItem({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'quantity': quantity,
    'unitPrice': unitPrice,
  };

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
    id: json['id'],
    description: json['description'],
    quantity: json['quantity'],
    unitPrice: json['unitPrice'],
  );

  InvoiceItem copyWith({
    String? id,
    String? description,
    double? quantity,
    double? unitPrice,
  }) => InvoiceItem(
    id: id ?? this.id,
    description: description ?? this.description,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice ?? this.unitPrice,
  );
}