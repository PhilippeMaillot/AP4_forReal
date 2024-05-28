class Product {
  final int id;
  final String title;
  final String description;
  final double price;
  final String image;
  final int quantity;
  final int idDuCart;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.image,
    this.quantity = 1,
    this.idDuCart = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id_product'],
      title: json['product_title'],
      description: json['product_description'],
      price: json['product_price'].toDouble(),
      image: json['product_img'],
      quantity: json['item_quantity'],
      idDuCart: json['id_cart_item'],
    );
  }
}
