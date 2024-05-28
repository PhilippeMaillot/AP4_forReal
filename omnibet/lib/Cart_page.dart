import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Product.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late List<Product> cartItems = []; // Initialisation de cartItems avec une liste vide
  final String baseURL = 'http://localhost:8080';

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    try {
      final response = await http.get(Uri.parse('$baseURL/cart/get/:id_user'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          cartItems = data.map((json) => Product(
            id: json['id_product'],
            title: json['product_title'],
            description: json['product_description'],
            price: json['product_price'],
            image: '$baseURL/uploads/${json['product_img']}',
          )).toList();
        });
      } else {
        throw Exception('Failed to load cart items');
      }
    } catch (error) {
      print('Error fetching cart items: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panier'),
      ),
      body: cartItems.isNotEmpty // Vérifie si cartItems n'est pas vide avant de construire la ListView
          ? ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return ListTile(
                  leading: Image.network(item.image),
                  title: Text(item.title),
                  subtitle: Text('${item.price}\ points'),
                  // Vous pouvez ajouter plus d'informations sur l'article ici si nécessaire
                );
              },
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
