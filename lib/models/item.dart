class Item {
  final String description;
  final int quantity;
  final double unitPrice;
  final double total;

  Item({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      description: json['description'],
      quantity: json['quantity'],
      unitPrice: (json['unitPrice'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
    };
  }
}
